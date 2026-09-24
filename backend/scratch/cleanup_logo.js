const db = require('../config/db');

async function cleanup() {
  try {
    console.log("Cleaning up duplicate settings...");
    
    // We want to delete duplicate settings keeping only the one with the maximum updated_at / id.
    // In MySQL, we can do a DELETE join.
    await db.query(`
      DELETE a1 FROM app_settings a1
      INNER JOIN app_settings a2 
      ON COALESCE(a1.gym_id, 'NULL') = COALESCE(a2.gym_id, 'NULL')
      AND a1.key = a2.key
      AND a1.updated_at < a2.updated_at
    `);
    
    console.log("Cleanup completed successfully.");
    process.exit(0);
  } catch (err) {
    console.error("Cleanup failed:", err);
    process.exit(1);
  }
}

cleanup();
