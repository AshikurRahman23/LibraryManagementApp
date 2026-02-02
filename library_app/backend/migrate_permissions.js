import pool from './models/db.js';

async function migratePermissions() {
  try {
    console.log('Adding permissions column to users table...');
    
    // Add permissions column if it doesn't exist
    await pool.query(`
      ALTER TABLE users 
      ADD COLUMN IF NOT EXISTS permissions TEXT DEFAULT '[]'
    `);
    
    console.log('Migration completed successfully!');
    console.log('Permissions column added to users table.');
    
    process.exit(0);
  } catch (error) {
    console.error('Migration failed:', error.message);
    process.exit(1);
  }
}

migratePermissions();
