// Supabase 테이블 존재 여부 확인 스크립트
require('dotenv').config();
const { createClient } = require('@supabase/supabase-js');

const supabaseUrl = process.env.SUPABASE_URL;
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!supabaseUrl || !supabaseServiceKey) {
  console.error('❌ 환경변수가 설정되지 않았습니다.');
  process.exit(1);
}

const supabase = createClient(supabaseUrl, supabaseServiceKey);

async function checkTables() {
  console.log('🔍 Supabase 데이터베이스 테이블 존재 여부 확인 중...\n');

  const tablesToCheck = [
    'users',
    'projects', 
    'proposals',
    'project_files',
    'feedback',
    'feedback_comments',
    'payments',
    'notifications',
    'disputes',
    'user_sanctions',
    'admin_logs',
    'announcements',
    'announcement_reads'
  ];

  console.log('📋 예상되는 테이블 목록:');
  tablesToCheck.forEach(table => console.log(`   - ${table}`));
  console.log();

  for (const tableName of tablesToCheck) {
    try {
      // 각 테이블에서 첫 번째 행만 조회해서 테이블 존재 여부 확인
      const { data, error } = await supabase
        .from(tableName)
        .select('*')
        .limit(1);

      if (error) {
        if (error.message.includes('relation') && error.message.includes('does not exist')) {
          console.log(`❌ ${tableName}: 테이블이 존재하지 않음`);
        } else if (error.message.includes('permission denied')) {
          console.log(`🔒 ${tableName}: RLS 정책에 의해 접근 제한됨 (테이블 존재함)`);
        } else {
          console.log(`⚠️  ${tableName}: ${error.message}`);
        }
      } else {
        console.log(`✅ ${tableName}: 테이블 존재 확인 (${data?.length || 0}개 레코드)`);
      }
    } catch (err) {
      console.log(`❌ ${tableName}: 에러 - ${err.message}`);
    }
  }

  console.log('\n📊 테이블 확인 완료!');

  // 추가로 Supabase의 정보 스키마에서 테이블 목록 조회 시도
  try {
    console.log('\n🔍 정보 스키마에서 public 테이블 목록 조회 시도...');
    const { data, error } = await supabase
      .rpc('exec', {
        sql: "SELECT table_name FROM information_schema.tables WHERE table_schema = 'public' ORDER BY table_name"
      });

    if (error) {
      console.log('⚠️  RPC 호출 실패:', error.message);
    } else {
      console.log('📋 실제 존재하는 public 테이블:');
      if (data && data.length > 0) {
        data.forEach(row => console.log(`   - ${row.table_name}`));
      } else {
        console.log('   없음');
      }
    }
  } catch (err) {
    console.log('⚠️  정보 스키마 조회 실패:', err.message);
  }
}

checkTables().catch(console.error);