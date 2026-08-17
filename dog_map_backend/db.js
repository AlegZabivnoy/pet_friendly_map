const { Pool } = require('pg');
require('dotenv').config();

const connectionString =
    process.env.STORAGE_DATABASE_URL ||
    process.env.DATABASE_URL ||
    process.env.STORAGE_URL ||
    process.env.POSTGRES_URL;

const pool = new Pool(
    connectionString
        ? {
            connectionString,
            ssl: { rejectUnauthorized: false },
        }
        : {
            user: process.env.DB_USER,
            password: process.env.DB_PASSWORD,
            host: process.env.DB_HOST,
            port: process.env.DB_PORT,
            database: process.env.DB_DATABASE,
        }
);

module.exports = pool;