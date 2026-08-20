const fs = require('fs');
let content = fs.readFileSync('backend/src/server.js', 'utf8');

const anchor = 'if (method === "POST" && url.pathname === "/api/rides/request") {';

const newRoutes = `
    if (method === "GET" && url.pathname === "/api/drivers/board") {
      const user = await requireUser(req, res);
      if (!user) return;
      
      const [rides] = await pool.query('SELECT * FROM rides WHERE status = "SEARCHING"');
      const enriched = await Promise.all(rides.map(r => enrichRide(r)));
      
      // Group by pool_group_id
      const grouped = {};
      for (const r of enriched) {
         const gid = r.pool_group_id || r.id;
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
         await pool.query('UPDATE driver_profiles SET seats_available = seats_available - 1 WHERE user_id = ?', [user.id]);
         const [updatedRides] = await pool.query('SELECT * FROM rides WHERE id = ?', [r.id]);
         const enriched = await enrichRide(updatedRides[0]);
         broadcastRideUpdate(r.id, enriched);
      }

      sendJson(res, 200, { success: true, message: "Group accepted." });
      return;
    }

`;

if (content.indexOf(anchor) > -1) {
    fs.writeFileSync('backend/src/server.js', content.replace(anchor, newRoutes + anchor));
    console.log('Routes added');
} else {
    console.log('Anchor not found');
}
