CREATE TABLE users (
  id TEXT PRIMARY KEY,
  full_name TEXT NOT NULL,
  mobile_number TEXT NOT NULL,
  email TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  role TEXT NOT NULL CHECK (role IN ('RIDER', 'DRIVER')),
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE driver_profiles (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id),
  vehicle_type TEXT NOT NULL,
  vehicle_number TEXT NOT NULL,
  is_online BOOLEAN NOT NULL DEFAULT FALSE,
  last_latitude DECIMAL(10, 7),
  last_longitude DECIMAL(10, 7),
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE rides (
  id TEXT PRIMARY KEY,
  rider_id TEXT NOT NULL REFERENCES users(id),
  driver_id TEXT REFERENCES users(id),
  pickup TEXT NOT NULL,
  destination TEXT NOT NULL,
  co_rider_pickup_distance_meters INTEGER,
  estimated_fare INTEGER,
  eta_minutes INTEGER,
  otp TEXT NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('SEARCHING', 'MATCHED', 'ACCEPTED', 'STARTED', 'COMPLETED', 'CANCELLED')),
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
