const fs = require('fs');
let content = fs.readFileSync('backend/src/server.js', 'utf8');

const targetFuncStart = content.indexOf('async function createDemoRideMatch(rider, payload) {');
const targetFuncEnd = content.indexOf('async function enrichRide(ride) {');

const replacement = `async function createDemoRideMatch(rider, payload) {
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
  
  // Smart Rider Pooling Logic
  let poolGroupId = null;
  
  // Find other SEARCHING rides
  const [searchingRides] = await pool.query('SELECT * FROM rides WHERE status = "SEARCHING" AND id != ?', [rideId]);
  
  for (const r of searchingRides) {
    if (r.pickup_lat && pickupLocation && r.destination_lat && payload.destinationLocation) {
      const pDist = calculateDistanceKm(r.pickup_lat, r.pickup_lng, pickupLocation.lat, pickupLocation.lng);
      const dDist = calculateDistanceKm(r.destination_lat, r.destination_lng, payload.destinationLocation.lat, payload.destinationLocation.lng);
      
      if (pDist <= 2.5 && dDist <= 2.5) {
        poolGroupId = r.pool_group_id;
        if (!poolGroupId) {
           poolGroupId = createId("group");
           await pool.query('UPDATE rides SET pool_group_id = ? WHERE id = ?', [poolGroupId, r.id]);
        }
        break;
      }
    }
  }
  
  if (!poolGroupId) {
    poolGroupId = createId("group");
  }

  await pool.query(
    \`INSERT INTO rides (
      id, rider_id, driver_id, pool_group_id, pickup, destination, 
      pickup_lat, pickup_lng, destination_lat, destination_lng, 
      co_rider_pickup_distance_meters, estimated_fare, eta_minutes, otp, status
    ) VALUES (?, ?, NULL, ?, ?, ?, ?, ?, ?, ?, ?, ?, NULL, ?, 'SEARCHING')\`,
    [
      rideId, rider.id, poolGroupId, payload.pickup.trim(), payload.destination.trim(),
      pickupLocation ? pickupLocation.lat : null, pickupLocation ? pickupLocation.lng : null,
      payload.destinationLocation ? payload.destinationLocation.lat : null, payload.destinationLocation ? payload.destinationLocation.lng : null,
      700, estimatedFare, otp
    ]
  );
  
  const [rows] = await pool.query('SELECT * FROM rides WHERE id = ?', [rideId]);
  return rows[0];
}

`;

if (targetFuncStart > -1 && targetFuncEnd > -1) {
    const newContent = content.substring(0, targetFuncStart) + replacement + content.substring(targetFuncEnd);
    fs.writeFileSync('backend/src/server.js', newContent);
    console.log('Patched createDemoRideMatch');
} else {
    console.log('Not found');
}
