const { createClient } = require('@supabase/supabase-js');
const fs = require('fs');
const path = require('path');

// Load environment variables
require('dotenv').config();

const supabaseUrl = process.env.SUPABASE_URL;
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!supabaseUrl || !supabaseServiceKey) {
  console.error('Missing Supabase environment variables');
  process.exit(1);
}

const supabase = createClient(supabaseUrl, supabaseServiceKey);

async function runMigration() {
  try {
    console.log('🚀 Starting migration: 003_add_modification_requests');
    
    // Read the migration file
    const migrationPath = path.join(__dirname, 'database', 'migrations', '003_add_modification_requests.sql');
    const migrationSQL = fs.readFileSync(migrationPath, 'utf8');
    
    console.log('📄 Migration file loaded');
    console.log('📏 Migration size:', migrationSQL.length, 'characters');
    
    // Split the SQL into individual statements
    const statements = migrationSQL
      .split(';')
      .map(stmt => stmt.trim())
      .filter(stmt => stmt && !stmt.startsWith('--'));
    
    console.log('📝 Found', statements.length, 'SQL statements');
    
    // Execute each statement
    for (let i = 0; i < statements.length; i++) {
      const statement = statements[i];
      if (!statement) continue;
      
      console.log(`⚡ Executing statement ${i + 1}/${statements.length}...`);
      console.log('📋 Statement:', statement.substring(0, 100) + (statement.length > 100 ? '...' : ''));
      
      try {
        const { data, error } = await supabase.rpc('exec_sql', { sql: statement });
        
        if (error) {
          console.error('❌ Error executing statement:', error);
          throw error;
        }
        
        console.log('✅ Statement executed successfully');
      } catch (err) {
        console.error('❌ Failed to execute statement:', err.message);
        throw err;
      }
    }
    
    console.log('🎉 Migration completed successfully!');
    console.log('📊 Total statements executed:', statements.length);
    
  } catch (error) {
    console.error('💥 Migration failed:', error.message);
    process.exit(1);
  }
}

// Simple migration display and connection test
async function runMigrationDirect() {
  try {
    console.log('🚀 Starting migration process');
    
    // Read the migration file
    const migrationPath = path.join(__dirname, 'database', 'migrations', '003_add_modification_requests.sql');
    const migrationSQL = fs.readFileSync(migrationPath, 'utf8');
    
    console.log('📄 Migration file loaded successfully');
    console.log('📏 File size:', migrationSQL.length, 'characters');
    
    // Test basic connection by checking existing projects table
    console.log('🔍 Testing database connection...');
    const { data, error } = await supabase
      .from('projects')
      .select('id')
      .limit(1);
      
    if (error) {
      console.log('❌ Database connection test failed:', error.message);
    } else {
      console.log('✅ Database connection successful');
      console.log('📊 Found', data?.length || 0, 'test records in projects table');
    }
    
    console.log('');
    console.log('🎯 MIGRATION READY FOR EXECUTION');
    console.log('');
    console.log('📋 Instructions:');
    console.log('1. Open your Supabase Dashboard (https://app.supabase.com)');
    console.log('2. Go to SQL Editor');
    console.log('3. Create a new query');
    console.log('4. Copy and paste the migration SQL below');
    console.log('5. Execute the query');
    console.log('');
    console.log('📂 Migration file: database/migrations/003_add_modification_requests.sql');
    console.log('');
    console.log('🔽 MIGRATION SQL (Copy this):');
    console.log('=' .repeat(80));
    console.log(migrationSQL);
    console.log('=' .repeat(80));
    console.log('');
    console.log('✨ After running this migration, your modification request system will be ready!');
    
  } catch (error) {
    console.error('💥 Migration process failed:', error.message);
  }
}

// Run the migration
console.log('🔧 Starting Supabase migration process...');
runMigrationDirect();