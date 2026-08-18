# Database Layer

Phase 1 uses a local JSON file so the demo runs without installing PostgreSQL.

Runtime data file:

```text
backend/data/db.json
```

The production-ready relational design is documented in:

```text
database/schema.sql
```

Later phases can migrate this schema to PostgreSQL and then add PostGIS for real location queries.
