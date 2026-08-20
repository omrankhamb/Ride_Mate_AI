const mysql = require("mysql2/promise");
const crypto = require("crypto");
const fs = require("fs");
const path = require("path");

const dbUrl = process.env.DATABASE_URL || "mysql://root:password@localhost:3306";
const [connectionUrl, databaseName] = dbUrl.match(/^(.*)\/([^?]+)/) 
  ? [dbUrl.match(/^(.*)\/([^?]+)/)[1], dbUrl.match(/^(.*)\/([^?]+)/)[2]] 
  : ["mysql://root:password@localhost:3306", "ridemate"];

let pool;

async function initDb() {
  if (pool) return pool;

  // Create DB if it doesn't exist
  const tempConn = await mysql.createConnection(connectionUrl);
  await tempConn.query(`CREATE DATABASE IF NOT EXISTS \`${databaseName}\``);
  await tempConn.end();

  // Create connection pool
  pool = mysql.createPool({
    uri: `${connectionUrl}/${databaseName}`,
    waitForConnections: true,
    connectionLimit: 10,
    queueLimit: 0,
    multipleStatements: true,
  });

  // Execute schema.sql to ensure tables exist
  const schemaPath = path.join(__dirname, "..", "..", "database", "schema.sql");
  if (fs.existsSync(schemaPath)) {
    const schemaSql = fs.readFileSync(schemaPath, "utf8");
    await pool.query(schemaSql);
  }

  console.log(`Connected to MySQL database: ${databaseName}`);
  return pool;
}

function getPool() {
  if (!pool) {
    throw new Error("Database not initialized. Call initDb() first.");
  }
  return pool;
}

function createId(prefix) {
  return `${prefix}_${crypto.randomUUID()}`;
}

module.exports = {
  initDb,
  getPool,
  createId
};
