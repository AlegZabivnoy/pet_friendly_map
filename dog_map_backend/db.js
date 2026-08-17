const { Pool } = require('pg');
require('dotenv').config();

const connectionString =
    process.env.DATABASE_URL ||
    process.env.POSTGRES_URL ||
    process.env.STORAGE_DATABASE_URL ||
    process.env.STORAGE_URL;

const pool = new Pool({
    connectionString,
    ssl: { rejectUnauthorized: false },
});

pool.on('error', (err) => {
    console.error('Unexpected database error:', err);
});

module.exports = pool;