const http = require("http");
const fs = require("fs");
const path = require("path");
const { createToken, hashPassword, verifyPassword, verifyToken } = require("./auth");
const { createId, readDb, writeDb } = require("./store");

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
      if (!body) {
        resolve({});
        return;
      }

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
    fullName: user.fullName,
    mobileNumber: user.mobileNumber,
    email: user.email,
    role: user.role,
    createdAt: user.createdAt
  };
}

function getToken(req) {
  const authHeader = req.headers.authorization || "";
  return authHeader.startsWith("Bearer ") ? authHeader.slice(7) : null;
}

function getCurrentUser(req) {
  const tokenPayload = verifyToken(getToken(req));
  if (!tokenPayload) {
    return null;
  }

  const db = readDb();
  return db.users.find(user => user.id === tokenPayload.sub) || null;
}

function requireUser(req, res) {
  const user = getCurrentUser(req);
  if (!user) {
    sendJson(res, 401, { success: false, message: "Please login first." });
    return null;
  }
  return user;
}

function assertRequired(payload, fields) {
  const missing = fields.filter(field => !String(payload[field] || "").trim());
  if (missing.length) {
    return `${missing.join(", ")} is required.`;
  }
  return null;
}

function isValidRole(role) {
  return role === "RIDER" || role === "DRIVER";
}

function findAvailableDriver(db) {
  const profile = db.driverProfiles.find(driver => driver.isOnline);
  if (!profile) {
    return null;
  }

  const user = db.users.find(candidate => candidate.id === profile.userId);
  if (!user) {
    return null;
  }

  return { profile, user };
}

function createDemoRideMatch(db, rider, payload) {
  const driver = findAvailableDriver(db);
  const now = new Date().toISOString();
  const ride = {
    id: createId("ride"),
    riderId: rider.id,
    driverId: driver ? driver.user.id : null,
    pickup: payload.pickup.trim(),
    destination: payload.destination.trim(),
    coRiderPickupDistanceMeters: 700,
    estimatedFare: 86,
    etaMinutes: driver ? 6 : null,
    otp: String(Math.floor(1000 + Math.random() * 9000)),
    status: driver ? "MATCHED" : "SEARCHING",
    createdAt: now,
    updatedAt: now
  };

  db.rides.push(ride);
  writeDb(db);

  return ride;
}

function enrichRide(db, ride) {
  const driver = db.users.find(user => user.id === ride.driverId);
  const driverProfile = db.driverProfiles.find(profile => profile.userId === ride.driverId);
  const rider = db.users.find(user => user.id === ride.riderId);

  return {
    ...ride,
    rider: rider ? cleanUser(rider) : null,
    driver: driver ? cleanUser(driver) : null,
    driverProfile: driverProfile || null
  };
}

async function handleApi(req, res) {
  const url = new URL(req.url, `http://${req.headers.host}`);
  const method = req.method;

  try {
    if (method === "POST" && url.pathname === "/api/auth/signup") {
      const payload = await parseBody(req);
      const role = String(payload.role || "").toUpperCase();

      if (!isValidRole(role)) {
        sendJson(res, 400, { success: false, message: "Choose Rider or Driver." });
        return;
      }

      const required = role === "DRIVER"
        ? ["fullName", "mobileNumber", "email", "password", "vehicleType", "vehicleNumber"]
        : ["fullName", "mobileNumber", "email", "password"];
      const missingMessage = assertRequired(payload, required);

      if (missingMessage) {
        sendJson(res, 400, { success: false, message: missingMessage });
        return;
      }

      if (String(payload.password).length < 6) {
        sendJson(res, 400, { success: false, message: "Password must be at least 6 characters." });
        return;
      }

      const db = readDb();
      const normalizedEmail = String(payload.email).trim().toLowerCase();
      const existing = db.users.find(user => user.email === normalizedEmail);

      if (existing) {
        sendJson(res, 409, { success: false, message: "Email is already registered." });
        return;
      }

      const now = new Date().toISOString();
      const user = {
        id: createId("user"),
        fullName: String(payload.fullName).trim(),
        mobileNumber: String(payload.mobileNumber).trim(),
        email: normalizedEmail,
        passwordHash: hashPassword(String(payload.password)),
        role,
        createdAt: now,
        updatedAt: now
      };

      db.users.push(user);

      if (role === "DRIVER") {
        db.driverProfiles.push({
          id: createId("driver"),
          userId: user.id,
          vehicleType: String(payload.vehicleType).trim(),
          vehicleNumber: String(payload.vehicleNumber).trim().toUpperCase(),
          isOnline: false,
          lastLocation: {
            label: "Waiting for live location",
            lat: 18.5204,
            lng: 73.8567
          },
          createdAt: now,
          updatedAt: now
        });
      }

      writeDb(db);

      sendJson(res, 201, {
        success: true,
        message: "Account created.",
        token: createToken(user),
        user: cleanUser(user)
      });
      return;
    }

    if (method === "POST" && url.pathname === "/api/auth/login") {
      const payload = await parseBody(req);
      const missingMessage = assertRequired(payload, ["email", "password"]);

      if (missingMessage) {
        sendJson(res, 400, { success: false, message: missingMessage });
        return;
      }

      const db = readDb();
      const email = String(payload.email).trim().toLowerCase();
      const user = db.users.find(candidate => candidate.email === email);

      if (!user || !verifyPassword(String(payload.password), user.passwordHash)) {
        sendJson(res, 401, { success: false, message: "Invalid email or password." });
        return;
      }

      sendJson(res, 200, {
        success: true,
        message: "Login successful.",
        token: createToken(user),
        user: cleanUser(user)
      });
      return;
    }

    if (method === "GET" && url.pathname === "/api/auth/me") {
      const user = requireUser(req, res);
      if (!user) {
        return;
      }

      sendJson(res, 200, { success: true, user: cleanUser(user) });
      return;
    }

    if (method === "POST" && url.pathname === "/api/drivers/status") {
      const user = requireUser(req, res);
      if (!user) {
        return;
      }

      if (user.role !== "DRIVER") {
        sendJson(res, 403, { success: false, message: "Only drivers can update driver status." });
        return;
      }

      const payload = await parseBody(req);
      const db = readDb();
      const profile = db.driverProfiles.find(driver => driver.userId === user.id);

      if (!profile) {
        sendJson(res, 404, { success: false, message: "Driver profile not found." });
        return;
      }

      profile.isOnline = Boolean(payload.isOnline);
      profile.lastLocation = {
        label: payload.locationLabel || "Driver live location",
        lat: Number(payload.lat || 18.5204),
        lng: Number(payload.lng || 73.8567)
      };
      profile.updatedAt = new Date().toISOString();

      writeDb(db);

      sendJson(res, 200, { success: true, profile });
      return;
    }

    if (method === "GET" && url.pathname === "/api/drivers/rides") {
      const user = requireUser(req, res);
      if (!user) {
        return;
      }

      if (user.role !== "DRIVER") {
        sendJson(res, 403, { success: false, message: "Only drivers can see driver rides." });
        return;
      }

      const db = readDb();
      const rides = db.rides
        .filter(ride => ride.driverId === user.id && ride.status !== "COMPLETED")
        .map(ride => enrichRide(db, ride));

      sendJson(res, 200, { success: true, rides });
      return;
    }

    if (method === "POST" && url.pathname === "/api/rides/request") {
      const user = requireUser(req, res);
      if (!user) {
        return;
      }

      if (user.role !== "RIDER") {
        sendJson(res, 403, { success: false, message: "Only riders can request rides." });
        return;
      }

      const payload = await parseBody(req);
      const missingMessage = assertRequired(payload, ["pickup", "destination"]);

      if (missingMessage) {
        sendJson(res, 400, { success: false, message: missingMessage });
        return;
      }

      const db = readDb();
      const ride = createDemoRideMatch(db, user, payload);
      const refreshedDb = readDb();

      sendJson(res, 201, {
        success: true,
        ride: enrichRide(refreshedDb, ride)
      });
      return;
    }

    if (method === "GET" && url.pathname === "/api/rides/mine") {
      const user = requireUser(req, res);
      if (!user) {
        return;
      }

      const db = readDb();
      const rides = db.rides
        .filter(ride => ride.riderId === user.id || ride.driverId === user.id)
        .sort((a, b) => b.createdAt.localeCompare(a.createdAt))
        .map(ride => enrichRide(db, ride));

      sendJson(res, 200, { success: true, rides });
      return;
    }

    if (method === "POST" && url.pathname.startsWith("/api/rides/")) {
      const user = requireUser(req, res);
      if (!user) {
        return;
      }

      const rideId = url.pathname.split("/")[3];
      const action = url.pathname.split("/")[4];
      const db = readDb();
      const ride = db.rides.find(candidate => candidate.id === rideId);

      if (!ride) {
        sendJson(res, 404, { success: false, message: "Ride not found." });
        return;
      }

      if (ride.driverId !== user.id && ride.riderId !== user.id) {
        sendJson(res, 403, { success: false, message: "You cannot update this ride." });
        return;
      }

      if (action === "accept" && user.role === "DRIVER") {
        ride.status = "ACCEPTED";
      } else if (action === "start" && user.role === "DRIVER") {
        const payload = await parseBody(req);
        if (String(payload.otp) !== String(ride.otp)) {
          sendJson(res, 400, { success: false, message: "Incorrect OTP." });
          return;
        }
        ride.status = "STARTED";
      } else if (action === "complete" && user.role === "DRIVER") {
        ride.status = "COMPLETED";
      } else if (action === "cancel") {
        ride.status = "CANCELLED";
      } else {
        sendJson(res, 400, { success: false, message: "Invalid ride action." });
        return;
      }

      ride.updatedAt = new Date().toISOString();
      writeDb(db);

      sendJson(res, 200, { success: true, ride: enrichRide(db, ride) });
      return;
    }

    sendJson(res, 404, { success: false, message: "API route not found." });
  } catch (error) {
    sendJson(res, 500, { success: false, message: error.message || "Server error." });
  }
}

function serveStatic(req, res) {
  const url = new URL(req.url, `http://${req.headers.host}`);
  let requestedPath = decodeURIComponent(url.pathname);

  if (requestedPath === "/") {
    requestedPath = "/index.html";
  }

  const safePath = path.normalize(requestedPath).replace(/^(\.\.[/\\])+/, "");
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

server.listen(PORT, () => {
  console.log(`RideMate AI running at http://localhost:${PORT}`);
});
