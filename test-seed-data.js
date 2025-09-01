// 시드 데이터 추가 테스트
require('dotenv').config();
const { createClient } = require('@supabase/supabase-js');

const supabaseUrl = process.env.SUPABASE_URL;
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

const supabase = createClient(supabaseUrl, supabaseServiceKey);

async function addSeedData() {
  console.log('🌱 시드 데이터 추가 중...\n');

  try {
    // 1. 테스트 사용자 추가 (Admin, Client, Designer)
    console.log('👤 테스트 사용자 추가 중...');
    
    const testUsers = [
      {
        id: 'a0000000-0000-0000-0000-000000000001',
        email: 'admin@deegongso.com',
        name: '시스템 관리자',
        phone: '010-0000-0001',
        role: 'admin',
        admin_level: 'super',
        admin_permissions: { user_management: true, dispute_resolution: true, system_settings: true, analytics_access: true }
      },
      {
        id: 'c0000000-0000-0000-0000-000000000001',
        email: 'client1@example.com',
        name: '김클라이언트',
        phone: '010-1234-5678',
        role: 'client',
        company: '스타트업 ABC',
        department: '마케팅팀',
        title: '팀장'
      },
      {
        id: 'd0000000-0000-0000-0000-000000000001',
        email: 'designer1@example.com',
        name: '박디자이너',
        phone: '010-9876-5432',
        role: 'designer',
        experience: '3-5년',
        specialization: ['로고 디자인', '브랜드 아이덴티티', 'UI/UX'],
        portfolio_url: 'https://portfolio.example.com/designer1',
        strengths: ['창의적 사고', '빠른 커뮤니케이션', '트렌드 감각'],
        is_verified: true,
        bio: '안녕하세요! 3년차 브랜드 디자이너 박디자이너입니다.'
      }
    ];

    const { data: userData, error: userError } = await supabase
      .from('users')
      .insert(testUsers)
      .select();

    if (userError) {
      console.log('⚠️ 사용자 추가 중 일부 오류:', userError.message);
    } else {
      console.log(`✅ ${userData.length}명의 테스트 사용자 추가 완료`);
    }

    // 2. 테스트 프로젝트 추가
    console.log('\n📋 테스트 프로젝트 추가 중...');
    
    const testProject = {
      id: 'p0000000-0000-0000-0000-000000000001',
      client_id: 'c0000000-0000-0000-0000-000000000001',
      title: '스타트업 ABC 로고 디자인',
      description: '스타트업을 위한 모던하고 혁신적인 로고 디자인을 의뢰드립니다.',
      project_type: 'logo_design',
      status: 'review_requested',
      budget_min: 500000,
      budget_max: 1000000,
      expected_duration: 7,
      requirements: '- 모던하고 깔끔한 디자인\n- 확장성 있는 로고\n- 컬러/흑백 버전 모두 제공',
      target_audience: '20-30대 IT 관심층, 초기 투자자',
      preferred_style: '미니멀, 모던, 테크',
      reference_materials: ['https://example.com/ref1.jpg', 'https://example.com/ref2.jpg'],
      max_modifications: 3
    };

    const { data: projectData, error: projectError } = await supabase
      .from('projects')
      .insert([testProject])
      .select();

    if (projectError) {
      console.log('⚠️ 프로젝트 추가 오류:', projectError.message);
    } else {
      console.log('✅ 테스트 프로젝트 추가 완료');
    }

    // 3. 전체 데이터 확인
    console.log('\n📊 추가된 데이터 확인...');
    
    const { data: users } = await supabase.from('users').select('id, name, email, role');
    const { data: projects } = await supabase.from('projects').select('id, title, status');

    console.log(`\n👥 총 사용자 수: ${users?.length || 0}명`);
    users?.forEach(user => {
      console.log(`   - ${user.name} (${user.email}) - ${user.role}`);
    });

    console.log(`\n📋 총 프로젝트 수: ${projects?.length || 0}개`);
    projects?.forEach(project => {
      console.log(`   - ${project.title} (${project.status})`);
    });

    console.log('\n🎉 시드 데이터 추가 완료!');

  } catch (error) {
    console.error('❌ 시드 데이터 추가 중 에러:', error.message);
  }
}

addSeedData();