const http = require("http");
const fs = require("fs");
const path = require("path");
require("dotenv").config({ path: path.join(__dirname, "../../.env") });
const { createToken, hashPassword, verifyPassword, verifyToken } = require("./auth");
const { initDb, getPool, createId } = require("./db");

const PORT = Number(process.env.PORT || 3000);
const publicRoot = path.join(__dirname, "..", "..", "frontend");

const mimeTypes = {
  ".html": "text/html; charset=utf-8",
  ".css": "text/css; charset=utf-8",
  ".js": "text/javascript; charset=utf-8",
  ".json": "application/json; charset=utf-8",
  ".svg": "image/svg+xml; charset=utf-8"
};

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET,POST,OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type,Authorization"
};

function sendJson(res, statusCode, body) {
  res.writeHead(statusCode, {
    "Content-Type": "application/json; charset=utf-8",
    ...corsHeaders
  });
  res.end(JSON.stringify(body));
}

function parseBody(req) {
  return new Promise((resolve, reject) => {
    let body = "";
    req.on("data", chunk => {
      body += chunk;
      if (body.length > 1_000_000) {
        req.destroy();
        reject(new Error("Request body too large"));
      }
    });
    req.on("end", () => {
      if (!body) return resolve({});
      try {
        resolve(JSON.parse(body));
      } catch {
        reject(new Error("Invalid JSON body"));
      }
    });
  });
}

function cleanUser(user) {
  return {
    id: user.id,
    fullName: user.full_name, // MySQL uses snake_case in our schema
    mobileNumber: user.mobile_number,
    email: user.email,
    role: user.role,
    createdAt: user.created_at
  };
}

function getToken(req) {
  const authHeader = req.headers.authorization || "";
  return authHeader.startsWith("Bearer ") ? authHeader.slice(7) : null;
}

async function getCurrentUser(req) {
  const tokenPayload = verifyToken(getToken(req));
  if (!tokenPayload) return null;
  const pool = getPool();
  const [rows] = await pool.query('SELECT * FROM users WHERE id = ?', [tokenPayload.sub]);
  return rows[0] || null;
}

async function requireUser(req, res) {
  const user = await getCurrentUser(req);
  if (!user) {
    sendJson(res, 401, { success: false, message: "Please login first." });
    return null;
  }
  return user;
}

function assertRequired(payload, fields) {
  const missing = fields.filter(field => !String(payload[field] || "").trim());
  if (missing.length) return `${missing.join(", ")} is required.`;
  return null;
}

function isValidRole(role) {
  return role === "RIDER" || role === "DRIVER";
}

function hashSeed(text) {
  return String(text).split("").reduce((sum, char) => sum + char.charCodeAt(0), 0);
}

function calculateDistanceKm(lat1, lon1, lat2, lon2) {
  if (!lat1 || !lon1 || !lat2 || !lon2) return 0;
  const R = 6371; 
  const dLat = (lat2 - lat1) * (Math.PI / 180); 
  const dLon = (lon2 - lon1) * (Math.PI / 180); 
  const a = Math.sin(dLat / 2) * Math.sin(dLat / 2) + Math.cos(lat1 * (Math.PI / 180)) * Math.cos(lat2 * (Math.PI / 180)) * Math.sin(dLon / 2) * Math.sin(dLon / 2); 
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a)); 
  return R * c; 
}

function buildDriverSummary(user, profile, distanceKm = null) {
  const seed = hashSeed(user.id);
  const rating = 4.6 + (seed % 5) * 0.1;
  const etaMinutes = distanceKm !== null ? Math.max(1, Math.round(distanceKm * 3)) : 3 + (seed % 6);
  const dist = distanceKm !== null ? distanceKm : 0.4 + (seed % 9) * 0.1;

  return {
    id: user.id,
    name: user.full_name,
    vehicleType: profile.vehicle_type,
    vehicleNumber: profile.vehicle_number,
    isOnline: !!profile.is_online,
    rating: Number(rating.toFixed(1)),
    etaMinutes,
    distanceKm: Number(dist.toFixed(1)),
    locationLabel: profile.last_location_label || "Nearby stand"
  };
}

async function findAvailableDriver(preferredDriverId, pickupLocation) {
  const pool = getPool();
  let bestProfile = null;
  let bestDistance = Infinity;

  // Fetch online drivers with their user info
  const [drivers] = await pool.query(
    'SELECT dp.*, u.full_name, u.mobile_number, u.email, u.role, u.created_at as user_created_at FROM driver_profiles dp JOIN users u ON dp.user_id = u.id WHERE dp.is_online = 1'
  );

  if (preferredDriverId) {
    bestProfile = drivers.find(d => d.user_id === preferredDriverId) || null;
    if (bestProfile && pickupLocation && bestProfile.last_latitude) {
      bestDistance = calculateDistanceKm(
        pickupLocation.lat, pickupLocation.lng,
        bestProfile.last_latitude, bestProfile.last_longitude
      );
    }
  }

  if (!bestProfile) {
    for (const driver of drivers) {
      let dist = Infinity;
      if (pickupLocation && driver.last_latitude) {
        dist = calculateDistanceKm(
          pickupLocation.lat, pickupLocation.lng,
          driver.last_latitude, driver.last_longitude
        );
      } else {
        dist = 5.0; 
      }
      if (dist < bestDistance) {
        bestDistance = dist;
        bestProfile = driver;
      }
    }
  }

  if (!bestProfile) return null;
  const user = { id: bestProfile.user_id, full_name: bestProfile.full_name, mobile_number: bestProfile.mobile_number, email: bestProfile.email, role: bestProfile.role, created_at: bestProfile.user_created_at };
  const summary = buildDriverSummary(user, bestProfile, bestDistance !== Infinity ? bestDistance : null);
  return { profile: bestProfile, summary, user };
}

async function listAvailableDrivers(pickupLocation = null) {
  const pool = getPool();
  const [drivers] = await pool.query(
    'SELECT dp.*, u.full_name, u.mobile_number, u.email, u.role, u.created_at as user_created_at FROM driver_profiles dp JOIN users u ON dp.user_id = u.id WHERE dp.is_online = 1'
  );

  return drivers.map(profile => {
    let dist = null;
    if (pickupLocation && profile.last_latitude) {
      dist = calculateDistanceKm(pickupLocation.lat, pickupLocation.lng, profile.last_latitude, profile.last_longitude);
    }
    const user = { id: profile.user_id, full_name: profile.full_name, mobile_number: profile.mobile_number, email: profile.email, role: profile.role, created_at: profile.user_created_at };
    return buildDriverSummary(user, profile, dist);
  }).sort((a, b) => a.etaMinutes - b.etaMinutes);
}

async function createDemoRideMatch(rider, payload) {
  const pool = getPool();
  const pickupLocation = payload.pickupLocation;
  
  let rideDistanceKm = 3.5;
  if (pickupLocation && payload.destinationLocation) {
    rideDistanceKm = calculateDistanceKm(
      pickupLocation.lat, pickupLocation.lng,
      payload.destinationLocation.lat, payload.destinationLocation.lng
    );
  }
  const estimatedFare = Math.max(30, Math.round(30 + (rideDistanceKm * 15)));

  const rideId = createId("ride");
  const otp = String(Math.floor(1000 + Math.random() * 9000));
  
  let poolGroupId = createId("group");

  await pool.query(
    `INSERT INTO rides (
      id, rider_id, driver_id, pool_group_id, pickup, destination, 
      pickup_lat, pickup_lng, destination_lat, destination_lng, 
      co_rider_pickup_distance_meters, estimated_fare, eta_minutes, otp, status
    ) VALUES (?, ?, NULL, ?, ?, ?, ?, ?, ?, ?, ?, ?, NULL, ?, 'SEARCHING')`,
    [
      rideId, rider.id, poolGroupId, payload.pickup.trim(), payload.destination.trim(),
      pickupLocation ? pickupLocation.lat : null, pickupLocation ? pickupLocation.lng : null,
      payload.destinationLocation ? payload.destinationLocation.lat : null, payload.destinationLocation ? payload.destinationLocation.lng : null,
      0, estimatedFare, otp
    ]
  );
  
  const [otherRides] = await pool.query('SELECT * FROM rides WHERE status = "SEARCHING" AND rider_id != ?', [rider.id]);
  for (const r of otherRides) {
    if (r.pickup_lat && pickupLocation && r.destination_lat && payload.destinationLocation) {
      const pDist = calculateDistanceKm(r.pickup_lat, r.pickup_lng, pickupLocation.lat, pickupLocation.lng);
      const dDist = calculateDistanceKm(r.destination_lat, r.destination_lng, payload.destinationLocation.lat, payload.destinationLocation.lng);
      if (pDist <= 5.0 && dDist <= 5.0) {
        await pool.query('UPDATE rides SET pool_group_id = ? WHERE id = ?', [r.pool_group_id, rideId]);
        break;
      }
    }
  }

  const [rows] = await pool.query('SELECT * FROM rides WHERE id = ?', [rideId]);
  return rows[0];
}

async function enrichRide(ride) {
  const pool = getPool();
  
  const [users] = await pool.query('SELECT * FROM users WHERE id IN (?, ?)', [ride.rider_id, ride.driver_id]);
  const rider = users.find(u => u.id === ride.rider_id);
  const driver = users.find(u => u.id === ride.driver_id);
  
  let driverProfile = null;
  if (driver) {
    const [profiles] = await pool.query('SELECT * FROM driver_profiles WHERE user_id = ?', [driver.id]);
    driverProfile = profiles[0] || null;
  }

  // Map MySQL snake_case back to camelCase for Flutter
  return {
    id: ride.id,
    riderId: ride.rider_id,
    driverId: ride.driver_id,
    pickup: ride.pickup,
    destination: ride.destination,
    pickupLocation: ride.pickup_lat ? { lat: ride.pickup_lat, lng: ride.pickup_lng } : null,
    destinationLocation: ride.destination_lat ? { lat: ride.destination_lat, lng: ride.destination_lng } : null,
    coRiderPickupDistanceMeters: ride.co_rider_pickup_distance_meters,
    estimatedFare: ride.estimated_fare,
    etaMinutes: ride.eta_minutes,
    otp: ride.otp,
    status: ride.status,
    poolGroupId: ride.pool_group_id,
    createdAt: ride.created_at,
    updatedAt: ride.updated_at,
    rider: rider ? cleanUser(rider) : null,
    driver: driver ? cleanUser(driver) : null,
    driverProfile: driverProfile ? {
      id: driverProfile.id,
      userId: driverProfile.user_id,
      vehicleType: driverProfile.vehicle_type,
      vehicleNumber: driverProfile.vehicle_number,
      isOnline: !!driverProfile.is_online,
      lastLocation: driverProfile.last_latitude ? { lat: driverProfile.last_latitude, lng: driverProfile.last_longitude, label: driverProfile.last_location_label } : null
    } : null
  };
}

// SSE Connection Manager
const activeStreams = new Map();

function broadcastRideUpdate(rideId, enrichedRide) {
  const streams = activeStreams.get(rideId) || [];
  const payload = `data: ${JSON.stringify(enrichedRide)}\n\n`;
  streams.forEach(res => {
    try { res.write(payload); } catch (e) {}
  });
}

async function broadcastChatEvent(poolGroupId, chatMessage) {
  const pool = getPool();
  const [rides] = await pool.query('SELECT id FROM rides WHERE pool_group_id = ?', [poolGroupId]);
  const payload = `event: chat\ndata: ${JSON.stringify(chatMessage)}\n\n`;
  
  for (const r of rides) {
    const streams = activeStreams.get(r.id) || [];
    streams.forEach(res => {
      try { res.write(payload); } catch (e) {}
    });
  }
}


async function handleApi(req, res) {
  const url = new URL(req.url, `http://${req.headers.host}`);
  const method = req.method;
  const pool = getPool();

  try {
    if (method === "GET" && url.pathname.match(/^\/api\/rides\/[^\/]+\/stream$/)) {
      const user = await requireUser(req, res);
      if (!user) return;
      const rideId = url.pathname.split("/")[3];
      res.writeHead(200, { "Content-Type": "text/event-stream", "Cache-Control": "no-cache", "Connection": "keep-alive", ...corsHeaders });
      res.write(`data: {"connected": true}\n\n`);
      if (!activeStreams.has(rideId)) activeStreams.set(rideId, []);
      activeStreams.get(rideId).push(res);
      req.on("close", () => {
        const streams = activeStreams.get(rideId) || [];
        const index = streams.indexOf(res);
        if (index !== -1) streams.splice(index, 1);
        if (streams.length === 0) activeStreams.delete(rideId);
      });
      return;
    }

    if (method === "POST" && url.pathname === "/api/demo/session") {
      const payload = await parseBody(req);
      const role = String(payload.role || "RIDER").toUpperCase() === "DRIVER" ? "DRIVER" : "RIDER";
      const email = `demo.${role.toLowerCase()}@ridemate.test`;
      
      let [users] = await pool.query('SELECT * FROM users WHERE email = ?', [email]);
      let user = users[0];

      if (!user) {
        user = {
          id: createId("user"),
          full_name: role === "DRIVER" ? "Demo Driver" : "Demo Rider",
          mobile_number: role === "DRIVER" ? "9000000001" : "9000000002",
          email,
          password_hash: hashPassword("demo-session"),
          role
        };
        await pool.query(
          'INSERT INTO users (id, full_name, mobile_number, email, password_hash, role) VALUES (?, ?, ?, ?, ?, ?)',
          [user.id, user.full_name, user.mobile_number, user.email, user.password_hash, user.role]
        );

        if (role === "DRIVER") {
          await pool.query(
            `INSERT INTO driver_profiles (id, user_id, vehicle_type, vehicle_number, is_online, last_latitude, last_longitude, last_location_label) 
              VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
            [createId("driver"), user.id, "Shared Auto", "MH12RM2026", 1, 18.5204, 73.8567, "VIT Pune gate"]
          );
        }
      }

      sendJson(res, 200, { success: true, token: createToken(user), user: cleanUser(user) });
      return;
    }

    if (method === "POST" && url.pathname === "/api/auth/signup") {
      const payload = await parseBody(req);
      const role = String(payload.role || "").toUpperCase();
      if (!isValidRole(role)) return sendJson(res, 400, { success: false, message: "Choose Rider or Driver." });

      const required = role === "DRIVER" ? ["fullName", "mobileNumber", "email", "password", "vehicleType", "vehicleNumber"] : ["fullName", "mobileNumber", "email", "password"];
      const missingMessage = assertRequired(payload, required);
      if (missingMessage) return sendJson(res, 400, { success: false, message: missingMessage });
      if (String(payload.password).length < 6) return sendJson(res, 400, { success: false, message: "Password must be at least 6 characters." });

      const normalizedEmail = String(payload.email).trim().toLowerCase();
      const [existing] = await pool.query('SELECT id FROM users WHERE email = ?', [normalizedEmail]);
      if (existing.length > 0) return sendJson(res, 409, { success: false, message: "Email is already registered." });

      const user = {
        id: createId("user"),
        full_name: String(payload.fullName).trim(),
        mobile_number: String(payload.mobileNumber).trim(),
        email: normalizedEmail,
        password_hash: hashPassword(String(payload.password)),
        role
      };

      await pool.query(
        'INSERT INTO users (id, full_name, mobile_number, email, password_hash, role) VALUES (?, ?, ?, ?, ?, ?)',
        [user.id, user.full_name, user.mobile_number, user.email, user.password_hash, user.role]
      );

      if (role === "DRIVER") {
        await pool.query(
          `INSERT INTO driver_profiles (id, user_id, vehicle_type, vehicle_number, is_online, last_latitude, last_longitude, last_location_label) 
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
          [createId("driver"), user.id, String(payload.vehicleType).trim(), String(payload.vehicleNumber).trim().toUpperCase(), 0, 18.5204, 73.8567, "Waiting for live location"]
        );
      }

      sendJson(res, 201, { success: true, message: "Account created.", token: createToken(user), user: cleanUser(user) });
      return;
    }

    if (method === "POST" && url.pathname === "/api/auth/login") {
      const payload = await parseBody(req);
      const missingMessage = assertRequired(payload, ["email", "password"]);
      if (missingMessage) return sendJson(res, 400, { success: false, message: missingMessage });

      const email = String(payload.email).trim().toLowerCase();
      const [users] = await pool.query('SELECT * FROM users WHERE email = ?', [email]);
      const user = users[0];

      if (!user || !verifyPassword(String(payload.password), user.password_hash)) {
        return sendJson(res, 401, { success: false, message: "Invalid email or password." });
      }

      sendJson(res, 200, { success: true, message: "Login successful.", token: createToken(user), user: cleanUser(user) });
      return;
    }

    if (method === "GET" && url.pathname === "/api/auth/me") {
      const user = await requireUser(req, res);
      if (!user) return;
      sendJson(res, 200, { success: true, user: cleanUser(user) });
      return;
    }

    if (method === "POST" && url.pathname === "/api/drivers/status") {
      const user = await requireUser(req, res);
      if (!user) return;
      if (user.role !== "DRIVER") return sendJson(res, 403, { success: false, message: "Only drivers can update driver status." });

      const payload = await parseBody(req);
      await pool.query(
        'UPDATE driver_profiles SET is_online = ?, last_latitude = ?, last_longitude = ?, last_location_label = ? WHERE user_id = ?',
        [payload.isOnline ? 1 : 0, Number(payload.lat || 18.5204), Number(payload.lng || 73.8567), payload.locationLabel || "Driver live location", user.id]
      );
      
      const [profiles] = await pool.query('SELECT * FROM driver_profiles WHERE user_id = ?', [user.id]);
      sendJson(res, 200, { success: true, profile: profiles[0] });
      return;
    }

    if (method === "GET" && url.pathname === "/api/drivers/rides") {
      const user = await requireUser(req, res);
      if (!user) return;
      if (user.role !== "DRIVER") return sendJson(res, 403, { success: false, message: "Only drivers can see driver rides." });

      const [rides] = await pool.query('SELECT * FROM rides WHERE driver_id = ? AND status != ?', [user.id, 'COMPLETED']);
      const enrichedRides = await Promise.all(rides.map(r => enrichRide(r)));
      sendJson(res, 200, { success: true, rides: enrichedRides });
      return;
    }

    if (method === "GET" && url.pathname === "/api/drivers/available") {
      const drivers = await listAvailableDrivers();
      sendJson(res, 200, { success: true, drivers });
      return;
    }

    
    if (method === "GET" && url.pathname === "/api/admin/state") {
      const [drivers] = await pool.query('SELECT dp.*, u.full_name, u.mobile_number, u.email, u.role, u.created_at as user_created_at FROM driver_profiles dp JOIN users u ON dp.user_id = u.id WHERE dp.is_online = 1');
      const [rides] = await pool.query('SELECT * FROM rides WHERE status != "COMPLETED" AND status != "CANCELLED"');
      const enrichedDrivers = drivers.map(d => {
        const u = { id: d.user_id, full_name: d.full_name, mobile_number: d.mobile_number, email: d.email, role: d.role, created_at: d.user_created_at };
        return buildDriverSummary(u, d);
      });
      const enrichedRides = await Promise.all(rides.map(r => enrichRide(r)));
      sendJson(res, 200, { success: true, drivers: enrichedDrivers, rides: enrichedRides });
      return;
    }

    if (method === "GET" && url.pathname === "/api/drivers/board") {
      const user = await requireUser(req, res);
      if (!user) return;
      
      const [rides] = await pool.query('SELECT * FROM rides WHERE status = "SEARCHING"');
      const enriched = await Promise.all(rides.map(r => enrichRide(r)));
      
      const grouped = {};
      for (const r of enriched) {
         const gid = r.poolGroupId || r.id;
         if (!grouped[gid]) grouped[gid] = [];
         grouped[gid].push(r);
      }
      sendJson(res, 200, { success: true, board: Object.values(grouped) });
      return;
    }

    if (method === "POST" && url.pathname.startsWith("/api/rides/group/") && url.pathname.endsWith("/accept")) {
      const user = await requireUser(req, res);
      if (!user) return;
      if (user.role !== "DRIVER") return sendJson(res, 403, { success: false, message: "Only drivers can accept." });

      const groupId = url.pathname.split("/")[4];
      const [rides] = await pool.query('SELECT * FROM rides WHERE pool_group_id = ? AND status = "SEARCHING"', [groupId]);
      if (rides.length === 0) return sendJson(res, 404, { success: false, message: "Group not found or already accepted." });
      
      for (const r of rides) {
         await pool.query('UPDATE rides SET driver_id = ?, status = "ACCEPTED" WHERE id = ?', [user.id, r.id]);
         await pool.query('UPDATE driver_profiles SET seats_available = GREATEST(seats_available - 1, 0) WHERE user_id = ?', [user.id]);
         const [updatedRides] = await pool.query('SELECT * FROM rides WHERE id = ?', [r.id]);
         const enriched = await enrichRide(updatedRides[0]);
         broadcastRideUpdate(r.id, enriched);
      }
      sendJson(res, 200, { success: true, message: "Group accepted." });
      return;
    }

    if (method === "POST" && url.pathname === "/api/matches/nearby-rides") {
      const user = await requireUser(req, res);
      if (!user) return;
      const payload = await parseBody(req);
      const excludeRideId = payload.excludeRideId;
      // Auto matching removed for manual P2P matching
         }
      }
      sendJson(res, 200, { success: true, matches });
      return;
    }

    if (method === "POST" && url.pathname === "/api/rides/connect") {
      const user = await requireUser(req, res);
      if (!user) return;
      const payload = await parseBody(req);
      const myRideId = payload.myRideId;
      const targetRideId = payload.targetGroupId;
      
      await pool.query(
        'INSERT INTO corider_requests (sender_ride_id, receiver_ride_id, status) VALUES (?, ?, ?)',
        [myRideId, targetRideId, 'PENDING']
      );
      sendJson(res, 200, { success: true, message: "Request sent to co-rider!" });
      return;
    }
    
    if (method === "POST" && url.pathname === "/api/rides/corider_respond") {
      const user = await requireUser(req, res);
      if (!user) return;
      const payload = await parseBody(req);
      const { requestId, action } = payload;
      
      if (action === 'accept') {
        const [reqs] = await pool.query('SELECT * FROM corider_requests WHERE id = ?', [requestId]);
        if (reqs.length > 0) {
          const r = reqs[0];
          const [senders] = await pool.query('SELECT pool_group_id FROM rides WHERE id = ?', [r.sender_ride_id]);
          if (senders.length > 0) {
             const groupId = senders[0].pool_group_id;
             await pool.query('UPDATE rides SET pool_group_id = ? WHERE id = ?', [groupId, r.receiver_ride_id]);
          }
        }
        await pool.query('UPDATE corider_requests SET status = ? WHERE id = ?', ['ACCEPTED', requestId]);
      } else {
        await pool.query('UPDATE corider_requests SET status = ? WHERE id = ?', ['REJECTED', requestId]);
      }
      sendJson(res, 200, { success: true, message: "Responded" });
      return;
    });
      return;
    }
    
    if (method === "POST" && url.pathname === "/api/rides/corider_respond") {
      const user = await requireUser(req, res);
      if (!user) return;
      const payload = await parseBody(req);
      const { requestId, action } = payload;
      
      if (action === 'accept') {
        const [reqs] = await pool.query('SELECT * FROM corider_requests WHERE id = ?', [requestId]);
        if (reqs.length > 0) {
          const r = reqs[0];
          // Get sender's pool_group_id
          const [senders] = await pool.query('SELECT pool_group_id FROM rides WHERE id = ?', [r.sender_ride_id]);
          if (senders.length > 0) {
             const groupId = senders[0].pool_group_id;
             await pool.query('UPDATE rides SET pool_group_id = ? WHERE id = ?', [groupId, r.receiver_ride_id]);
          }
        }
        await pool.query('UPDATE corider_requests SET status = ? WHERE id = ?', ['ACCEPTED', requestId]);
      } else {
        await pool.query('UPDATE corider_requests SET status = ? WHERE id = ?', ['REJECTED', requestId]);
      }
      sendJson(res, 200, { success: true, message: "Responded" });
      return;
    }

if (method === "POST" && url.pathname === "/api/rides/request") {
      const user = await requireUser(req, res);
      if (!user) return;
      if (user.role !== "RIDER") return sendJson(res, 403, { success: false, message: "Only riders can request rides." });

      const payload = await parseBody(req);
      const missingMessage = assertRequired(payload, ["pickup", "destination"]);
      if (missingMessage) return sendJson(res, 400, { success: false, message: missingMessage });

      const ride = await createDemoRideMatch(user, payload);
      const enrichedRide = await enrichRide(ride);
      
      let selectedDriver = null;
      if (ride.driver_id) {
        const drivers = await listAvailableDrivers();
        selectedDriver = drivers.find(d => d.id === ride.driver_id) || null;
      }
      sendJson(res, 201, { success: true, ride: enrichedRide, selectedDriver });
      return;
    }

    if (method === "GET" && url.pathname === "/api/rides/mine") {
      const user = await requireUser(req, res);
      if (!user) return;

      const [rides] = await pool.query('SELECT * FROM rides WHERE rider_id = ? OR driver_id = ? ORDER BY created_at DESC', [user.id, user.id]);
      const enrichedRides = await Promise.all(rides.map(r => enrichRide(r)));
      
      let pendingRequests = [];
      const activeRide = enrichedRides.find(r => r.status === 'SEARCHING');
      if (activeRide) {
        const [reqs] = await pool.query('SELECT cr.id, cr.sender_ride_id, u.full_name as sender_name, r.pickup_lat, r.pickup_lng, r.destination_lat, r.destination_lng, r.pickup_label, r.destination_label FROM corider_requests cr JOIN rides r ON cr.sender_ride_id = r.id JOIN users u ON r.rider_id = u.id WHERE cr.receiver_ride_id = ? AND cr.status = "PENDING"', [activeRide.id]);
        
        pendingRequests = reqs.map(req => {
          return {
            id: req.id,
            senderName: req.sender_name.split(' ')[0],
            pickup: req.pickup_label,
            destination: req.destination_label,
            pickupLat: req.pickup_lat,
            pickupLng: req.pickup_lng
          };
        });
      }
      
      sendJson(res, 200, { success: true, rides: enrichedRides, pendingRequests });
      return;
    }

    if (method === "POST" && url.pathname.startsWith("/api/rides/")) {
      const user = await requireUser(req, res);
      if (!user) return;

      const rideId = url.pathname.split("/")[3];
      const action = url.pathname.split("/")[4];
      
      const [rides] = await pool.query('SELECT * FROM rides WHERE id = ?', [rideId]);
      const ride = rides[0];

      if (!ride) return sendJson(res, 404, { success: false, message: "Ride not found." });
      if (ride.driver_id !== user.id && ride.rider_id !== user.id) return sendJson(res, 403, { success: false, message: "You cannot update this ride." });

      let newStatus = ride.status;

      if (action === "accept" && user.role === "DRIVER") {
        if (ride.status !== "MATCHED" && ride.status !== "SEARCHING") return sendJson(res, 400, { success: false, message: "Ride cannot be accepted in its current state." });
        newStatus = "ACCEPTED";
      } else if (action === "start" && user.role === "DRIVER") {
        if (ride.status !== "ACCEPTED") return sendJson(res, 400, { success: false, message: "Ride must be accepted before starting." });
        const payload = await parseBody(req);
        if (String(payload.otp) !== String(ride.otp)) return sendJson(res, 400, { success: false, message: "Incorrect OTP." });
        newStatus = "STARTED";
      } else if (action === "complete" && user.role === "DRIVER") {
        if (ride.status !== "STARTED") return sendJson(res, 400, { success: false, message: "Only started rides can be completed." });
        newStatus = "COMPLETED";
      } else if (action === "cancel") {
        if (ride.status === "COMPLETED" || ride.status === "CANCELLED") return sendJson(res, 400, { success: false, message: "Ride cannot be cancelled." });
        newStatus = "CANCELLED";
      } else {
        return sendJson(res, 400, { success: false, message: "Invalid ride action." });
      }

      await pool.query('UPDATE rides SET status = ? WHERE id = ?', [newStatus, rideId]);
      const [updatedRides] = await pool.query('SELECT * FROM rides WHERE id = ?', [rideId]);
      const enriched = await enrichRide(updatedRides[0]);
      
      broadcastRideUpdate(rideId, enriched);
      sendJson(res, 200, { success: true, ride: enriched });
      return;
    }

    
    if (method === "GET" && url.pathname.startsWith("/api/chat/")) {
      const user = await requireUser(req, res);
      if (!user) return;
      const groupId = url.pathname.split("/")[3];
      const [messages] = await pool.query('SELECT * FROM chat_messages WHERE pool_group_id = ? ORDER BY created_at ASC', [groupId]);
      // CamelCase mappings
      const formatted = messages.map(m => ({
        id: m.id,
        poolGroupId: m.pool_group_id,
        senderId: m.sender_id,
        senderName: m.sender_name,
        message: m.message,
        createdAt: m.created_at
      }));
      return sendJson(res, 200, { success: true, messages: formatted });
    }

    if (method === "POST" && url.pathname === "/api/chat") {
      const user = await requireUser(req, res);
      if (!user) return;
      const payload = await parseBody(req);
      const { poolGroupId, message } = payload;
      
      const msgId = createId("msg");
      const senderName = user.full_name.split(' ')[0];
      
      await pool.query(
        'INSERT INTO chat_messages (id, pool_group_id, sender_id, sender_name, message) VALUES (?, ?, ?, ?, ?)',
        [msgId, poolGroupId, user.id, senderName, message]
      );
      
      const [inserted] = await pool.query('SELECT * FROM chat_messages WHERE id = ?', [msgId]);
      const m = inserted[0];
      const formatted = {
        id: m.id,
        poolGroupId: m.pool_group_id,
        senderId: m.sender_id,
        senderName: m.sender_name,
        message: m.message,
        createdAt: m.created_at
      };
      
      await broadcastChatEvent(poolGroupId, formatted);
      return sendJson(res, 201, { success: true, message: formatted });
    }
    sendJson(res, 404, { success: false, message: "API route not found." });
  } catch (error) {
    sendJson(res, 500, { success: false, message: error.message || "Server error." });
  }
}

function serveStatic(req, res) {
  const url = new URL(req.url, `http://${req.headers.host}`);
  let requestedPath = decodeURIComponent(url.pathname);
  if (requestedPath === "/") requestedPath = "/index.html";
  const safePath = path.normalize(requestedPath).replace(/^(\\.\\.[\\/\\\\])+/, "");
  const filePath = path.join(publicRoot, safePath);

  if (!filePath.startsWith(publicRoot)) {
    res.writeHead(403);
    res.end("Forbidden");
    return;
  }

  fs.readFile(filePath, (error, data) => {
    if (error) {
      fs.readFile(path.join(publicRoot, "index.html"), (fallbackError, fallbackData) => {
        if (fallbackError) {
          res.writeHead(404);
          res.end("Not found");
          return;
        }
        res.writeHead(200, { "Content-Type": mimeTypes[".html"] });
        res.end(fallbackData);
      });
      return;
    }
    const extension = path.extname(filePath);
    res.writeHead(200, { "Content-Type": mimeTypes[extension] || "application/octet-stream" });
    res.end(data);
  });
}

const server = http.createServer((req, res) => {
  if (req.method === "OPTIONS") {
    res.writeHead(204, corsHeaders);
    res.end();
    return;
  }
  if (req.url.startsWith("/api/")) {
    handleApi(req, res);
    return;
  }
  serveStatic(req, res);
});

initDb().then(() => {
  server.listen(PORT, () => {
    console.log(`RideMate AI running at http://localhost:${PORT} backed by MySQL`);
  });
}).catch(err => {
  console.error("Failed to initialize database:", err);
  process.exit(1);
});