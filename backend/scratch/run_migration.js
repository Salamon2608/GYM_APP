const fs = require('fs');
const path = require('path');
const db = require('../config/db');

async function run() {
  try {
    console.log('Reading migration file...');
    const sqlFile = path.join(__dirname, '../database/migrate_receipt_number.sql');
    if (!fs.existsSync(sqlFile)) {
      throw new Error(`Migration file not found at: ${sqlFile}`);
    }
    
    const sql = fs.readFileSync(sqlFile, 'utf8');
    
    // Clean up comments and split by semicolon
    const statements = sql
      .split(';')
      .map(stmt => {
        // Remove comments
        return stmt
          .split('\n')
          .filter(line => !line.trim().startsWith('--'))
          .join('\n')
          .trim();
      })
      .filter(stmt => stmt.length > 0);

    console.log(`Found ${statements.length} SQL statement(s) to execute.`);

    for (let i = 0; i < statements.length; i++) {
      const stmt = statements[i];
      console.log(`Executing statement ${i + 1}/${statements.length}...`);
      await db.query(stmt);
    }

    console.log('✅ Migration executed successfully!');
  } catch (err) {
    console.error('❌ Migration failed:', err.message);
  } finally {
    await db.end();
    process.exit();
  }
}

run();
