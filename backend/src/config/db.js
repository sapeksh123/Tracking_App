const { Pool } = require('pg');
require('dotenv').config();

let connectionString = process.env.DATABASE_URL || '';
if (connectionString.trim().startsWith('psql ')) {
  connectionString = connectionString.replace(/^psql\s+/, '').trim();

  connectionString = connectionString.replace(/^['\"]|['\"]$/g, '');
}

const poolConfig = {
  connectionString,
};

const shouldEnableSSL = (process.env.DATABASE_SSL || '').toLowerCase() === 'true' || process.env.NODE_ENV === 'production' || /sslmode=require/.test(connectionString);
if (shouldEnableSSL) {
  poolConfig.ssl = {
    rejectUnauthorized: false,
  };
}


const pool = new Pool(poolConfig);

pool.on('error', (err) => {
  console.error('Unexpected error on idle pg client', err);
});

module.exports = {
  query: (text, params) => pool.query(text, params),
  pool
};
