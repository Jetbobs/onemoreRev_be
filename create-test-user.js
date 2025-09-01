// 실제 Supabase Auth를 통한 테스트 사용자 생성
require('dotenv').config();
const { createClient } = require('@supabase/supabase-js');

const supabaseUrl = process.env.SUPABASE_URL;
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

const supabase = createClient(supabaseUrl, supabaseServiceKey, {
  auth: {
    autoRefreshToken: false,
    persistSession: false
  }
});

async function createTestUser() {
  console.log('🧪 Supabase Auth를 통한 테스트 사용자 생성...\n');

  try {
    // 1. Supabase Auth에 사용자 생성 (관리자 권한으로)
    console.log('👤 Auth 사용자 생성 중...');
    
    const { data: authData, error: authError } = await supabase.auth.admin.createUser({
      email: 'test@deegongso.com',
      password: 'test123456',
      email_confirm: true,
      user_metadata: {
        name: '테스트 사용자',
        role: 'client'
      }
    });

    if (authError) {
      console.error('❌ Auth 사용자 생성 실패:', authError.message);
      return;
    }

    console.log('✅ Auth 사용자 생성 성공:', authData.user.email);
    console.log('   사용자 ID:', authData.user.id);

    // 2. users 테이블에 프로필 추가
    console.log('\n📝 사용자 프로필 생성 중...');
    
    const { data: profileData, error: profileError } = await supabase
      .from('users')
      .insert({
        id: authData.user.id,
        email: authData.user.email,
        name: '테스트 사용자',
        phone: '010-1234-5678',
        role: 'client',
        company: '테스트 회사',
        department: '개발팀'
      })
      .select();

    if (profileError) {
      console.error('❌ 프로필 생성 실패:', profileError.message);
      return;
    }

    console.log('✅ 사용자 프로필 생성 성공');

    // 3. 생성된 사용자 확인
    console.log('\n📊 생성된 사용자 확인...');
    const { data: users, error: fetchError } = await supabase
      .from('users')
      .select('*');

    if (fetchError) {
      console.error('❌ 사용자 조회 실패:', fetchError.message);
    } else {
      console.log(`\n👥 총 사용자 수: ${users.length}명`);
      users.forEach(user => {
        console.log(`   - ${user.name} (${user.email}) - ${user.role}`);
      });
    }

    // 4. 간단한 프로젝트 생성 테스트
    console.log('\n📋 테스트 프로젝트 생성 중...');
    
    const { data: projectData, error: projectError } = await supabase
      .from('projects')
      .insert({
        client_id: authData.user.id,
        title: '테스트 프로젝트',
        description: '백엔드 연동 테스트를 위한 프로젝트입니다.',
        project_type: 'logo_design',
        status: 'creation_pending',
        budget_min: 100000,
        budget_max: 200000
      })
      .select();

    if (projectError) {
      console.error('❌ 프로젝트 생성 실패:', projectError.message);
    } else {
      console.log('✅ 테스트 프로젝트 생성 성공');
      console.log('   프로젝트 제목:', projectData[0].title);
    }

    console.log('\n🎉 테스트 데이터 생성 완료!');

  } catch (error) {
    console.error('❌ 전체 프로세스 에러:', error.message);
  }
}

createTestUser();