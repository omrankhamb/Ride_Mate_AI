const request = require('supertest');
const server = require('../src/server');
const { initDb, getPool } = require('../src/db');

describe('RideMate AI API Tests', () => {
  let pool;

  beforeAll(async () => {
    // We assume MySQL is running locally for the test
    pool = await initDb();
  });

  afterAll(async () => {
    await pool.end();
  });

  describe('Authentication', () => {
    it('should create a demo session and return a token', async () => {
      const res = await request(server)
        .post('/api/demo/session')
        .send({ role: 'RIDER' })
        .set('Accept', 'application/json');
      
      expect(res.statusCode).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.token).toBeDefined();
      expect(res.body.user.role).toBe('RIDER');
    });

    it('should fail login with invalid credentials', async () => {
      const res = await request(server)
        .post('/api/auth/login')
        .send({ email: 'fake@example.com', password: 'wrong' })
        .set('Accept', 'application/json');
      
      expect(res.statusCode).toBe(401);
      expect(res.body.success).toBe(false);
    });
  });

  describe('Shared-Auto Capacity', () => {
    it('should list available drivers', async () => {
      const res = await request(server)
        .get('/api/drivers/available')
        .set('Accept', 'application/json');
      
      // If there are drivers, they should have etaMinutes
      expect(res.statusCode).toBe(200);
      expect(res.body.success).toBe(true);
      expect(Array.isArray(res.body.drivers)).toBe(true);
    });
  });
});
