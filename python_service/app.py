"""RideMate AI location, geocoding, and shared-ride matching service."""

from __future__ import annotations

import json
import math
import os
import re
import time
from pathlib import Path
from typing import Any
from functools import lru_cache

import httpx
from flask import Flask, jsonify, request


EARTH_RADIUS_METERS = 6_371_008.8
MODEL_NAME = os.getenv(
    "RIDEMATE_EMBEDDING_MODEL",
    "sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2",
)
PROJECT_ROOT = Path(__file__).resolve().parents[1]
DB_PATH = Path(os.getenv("RIDEMATE_DB_PATH", PROJECT_ROOT / "backend" / "data" / "db.json"))
NOMINATIM_URL = "https://nominatim.openstreetmap.org/search"


app = Flask(__name__)


@app.after_request
def add_cors_headers(response):
    response.headers["Access-Control-Allow-Origin"] = "*"
    response.headers["Access-Control-Allow-Headers"] = "Content-Type"
    response.headers["Access-Control-Allow-Methods"] = "GET, POST, OPTIONS"
    return response


class SemanticPlaceRanker:
    """Lazy pre-trained embedding model."""

    def __init__(self):
        self.model = None
        self.load_attempted = False
        self.enabled = os.getenv("RIDEMATE_ENABLE_EMBEDDINGS") == "1"

    def _load(self) -> None:
        if self.load_attempted:
            return
        self.load_attempted = True
        if not self.enabled:
            return
        try:
            from sentence_transformers import SentenceTransformer, util

            allow_download = os.getenv("RIDEMATE_ALLOW_MODEL_DOWNLOAD") == "1"
            self.model = SentenceTransformer(
                MODEL_NAME,
                local_files_only=not allow_download,
            )
            self.util = util
        except Exception:
            self.model = None
            self.util = None

    @property
    def is_model_ready(self) -> bool:
        self._load()
        return self.model is not None

    def similarity(self, first: str, second: str) -> float:
        if not first or not second:
            return 0.0
        self._load()
        if self.model is not None and self.util is not None:
            embeddings = self.model.encode(
                [first, second], convert_to_tensor=True, normalize_embeddings=True
            )
            return max(0.0, float(self.util.cos_sim(embeddings[0], embeddings[1])))
        first_tokens = set(_normalise(first).split())
        second_tokens = set(_normalise(second).split())
        if not first_tokens or not second_tokens:
            return 0.0
        return len(first_tokens & second_tokens) / max(len(first_tokens | second_tokens), 1)


ranker = SemanticPlaceRanker()


def _normalise(value: str) -> str:
    return re.sub(r"[^a-z0-9 ]+", " ", value.lower()).strip()


def _to_point(value: dict[str, Any] | None) -> tuple[float, float] | None:
    if not value:
        return None
    try:
        return float(value.get("lat", value.get("latitude"))), float(
            value.get("lng", value.get("longitude"))
        )
    except (TypeError, ValueError):
        return None


def _haversine_meters(first: tuple[float, float], second: tuple[float, float]) -> float:
    first_lat, first_lng, second_lat, second_lng = map(
        math.radians, [first[0], first[1], second[0], second[1]]
    )
    delta_lat = second_lat - first_lat
    delta_lng = second_lng - first_lng
    value = math.sin(delta_lat / 2) ** 2 + math.cos(first_lat) * math.cos(second_lat) * math.sin(delta_lng / 2) ** 2
    return EARTH_RADIUS_METERS * 2 * math.asin(math.sqrt(value))


def _read_database() -> dict[str, Any]:
    if not DB_PATH.exists():
        return {"users": [], "rides": []}
    
    # Retry loop to prevent crashing if Node is currently writing to db.json
    for _ in range(5):
        try:
            return json.loads(DB_PATH.read_text(encoding="utf-8"))
        except json.JSONDecodeError:
            time.sleep(0.05)
    
    return {"users": [], "rides": []}


def _ride_location(ride: dict[str, Any], name: str) -> dict[str, Any] | None:
    location = ride.get(f"{name}Location")
    if _to_point(location):
        return location
    return None


@app.get("/health")
def health():
    return jsonify(
        {
            "success": True,
            "service": "RideMate location matcher",
            "embeddingModel": MODEL_NAME,
            "embeddingLoaded": ranker.model is not None,
            "embeddingEnabled": ranker.enabled,
        }
    )


@lru_cache(maxsize=128)
def _fetch_nominatim(query: str) -> list[dict[str, Any]]:
    try:
        response = httpx.get(
            NOMINATIM_URL,
            params={"q": query, "format": "jsonv2", "limit": 5},
            headers={"User-Agent": "RideMateAI-Demo/1.0"},
            timeout=4.0,
        )
        response.raise_for_status()
        return [
            {
                "label": item["display_name"],
                "lat": float(item["lat"]),
                "lng": float(item["lon"]),
                "source": "OpenStreetMap",
            }
            for item in response.json()
        ]
    except (httpx.HTTPError, ValueError, KeyError, TypeError):
        return []


@app.post("/api/geocode")
def geocode():
    payload = request.get_json(silent=True) or {}
    query = str(payload.get("query", "")).strip()
    if len(query) < 2:
        return jsonify({"message": "Enter at least two characters."}), 400

    results = _fetch_nominatim(query)

    return jsonify(
        {
            "success": True,
            "locations": results,
            "semanticModelReady": ranker.is_model_ready,
            "semanticModelEnabled": ranker.enabled,
        }
    )


@app.post("/api/matches/nearby-rides")
def nearby_rides():
    payload = request.get_json(silent=True) or {}
    request_pickup = _to_point(payload.get("pickup"))
    request_destination = _to_point(payload.get("destination"))
    if request_pickup is None or request_destination is None:
        return jsonify({"message": "Pickup and destination coordinates are required."}), 400

    pickup_radius = max(100, min(int(payload.get("pickupRadiusMeters", 1000)), 5000))
    destination_radius = max(100, min(int(payload.get("destinationRadiusMeters", 1500)), 5000))
    excluded_ride_id = str(payload.get("excludeRideId", ""))
    excluded_rider_id = str(payload.get("excludeRiderId", ""))
    database = _read_database()
    users = {user["id"]: user for user in database.get("users", [])}

    candidates = []
    for ride in database.get("rides", []):
        if (
            ride.get("id") == excluded_ride_id
            or ride.get("riderId") == excluded_rider_id
            or ride.get("status") in {"CANCELLED", "COMPLETED"}
        ):
            continue
        pickup = _ride_location(ride, "pickup")
        destination = _ride_location(ride, "destination")
        pickup_point = _to_point(pickup)
        destination_point = _to_point(destination)
        if pickup_point is not None and destination_point is not None:
            candidates.append((ride, pickup, destination, pickup_point, destination_point))

    if not candidates:
        return jsonify({"success": True, "matches": [], "matchingMethod": "geospatial + semantic"})

    # BallTree quickly narrows large ride lists by pickup. Exact Haversine checks
    # are still made afterwards to avoid approximation errors near a boundary.
    try:
        import numpy as np
        from sklearn.neighbors import BallTree

        pickup_coordinates = np.radians(
            np.array([[item[3][0], item[3][1]] for item in candidates])
        )
        tree = BallTree(pickup_coordinates, metric="haversine")
        pickup_indexes = tree.query_radius(
            np.radians(np.array([[request_pickup[0], request_pickup[1]]])),
            r=pickup_radius / EARTH_RADIUS_METERS,
        )[0]
    except ImportError:
        pickup_indexes = range(len(candidates))

    matches = []
    for index in pickup_indexes:
        ride, pickup, destination, pickup_point, destination_point = candidates[int(index)]
        pickup_distance = _haversine_meters(request_pickup, pickup_point)
        destination_distance = _haversine_meters(request_destination, destination_point)
        if pickup_distance > pickup_radius or destination_distance > destination_radius:
            continue

        pickup_similarity = ranker.similarity(
            str(payload.get("pickup", {}).get("label", "")), str(pickup.get("label", ride.get("pickup", "")))
        )
        destination_similarity = ranker.similarity(
            str(payload.get("destination", {}).get("label", "")), str(destination.get("label", ride.get("destination", "")))
        )
        spatial_score = 0.5 * (1 - pickup_distance / pickup_radius) + 0.5 * (
            1 - destination_distance / destination_radius
        )
        semantic_score = (pickup_similarity + destination_similarity) / 2
        match_score = round(100 * (0.9 * spatial_score + 0.1 * semantic_score))
        rider = users.get(ride.get("riderId"), {})
        matches.append(
            {
                "rideId": ride.get("id"),
                "riderName": rider.get("fullName", "Nearby rider"),
                "pickup": ride.get("pickup", pickup.get("label", "Pickup")),
                "destination": ride.get("destination", destination.get("label", "Destination")),
                "pickupDistanceMeters": round(pickup_distance),
                "destinationDistanceMeters": round(destination_distance),
                "matchScore": max(0, min(100, match_score)),
            }
        )

    matches.sort(key=lambda item: item["matchScore"], reverse=True)
    return jsonify(
        {
            "success": True,
            "matches": matches[:10],
            "matchingMethod": "BallTree Haversine range filter + sentence-transformer place similarity",
            "semanticModelReady": ranker.is_model_ready,
            "semanticModelEnabled": ranker.enabled,
        }
    )


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int(os.getenv("PORT", "8000")), debug=True)
