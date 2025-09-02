const { createClient } = require('@supabase/supabase-js');
require('dotenv').config();

const supabase = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_SERVICE_ROLE_KEY);

async function createFreshTestProject() {
  console.log('=== 새로운 재협상 테스트 프로젝트 생성 ===');
  
  // 테스트 클라이언트와 디자이너 ID 가져오기
  const { data: testClient, error: clientError } = await supabase
    .from('users')
    .select('id, email')
    .eq('email', 'test_client@deegongso.com')
    .single();
    
  const { data: testDesigner, error: designerError } = await supabase
    .from('users')
    .select('id, email')
    .eq('role', 'designer')
    .limit(1)
    .single();
    
  if (clientError || designerError || !testClient || !testDesigner) {
    console.error('테스트 사용자를 찾을 수 없습니다');
    return;
  }
  
  console.log('테스트 사용자 정보:');
  console.log('- 클라이언트:', testClient.email);
  console.log('- 디자이너:', testDesigner.email);
  
  // 1. 새 프로젝트 생성
  const projectData = {
    client_id: testClient.id,
    designer_id: testDesigner.id,
    title: 'renegotiation_test_project',
    description: '재협상 테스트를 위한 새 프로젝트입니다.',
    project_type: 'logo_design',
    status: 'creation_pending',
    budget_min: 400000,
    budget_max: 500000,
    deadline: new Date(Date.now() + 14 * 24 * 60 * 60 * 1000).toISOString().split('T')[0], // 2주 후
    requirements: '재협상 테스트용 로고 디자인 프로젝트',
    max_modifications: 3
  };
  
  const { data: newProject, error: projectError } = await supabase
    .from('projects')
    .insert(projectData)
    .select()
    .single();
    
  if (projectError) {
    console.error('프로젝트 생성 실패:', projectError);
    return;
  }
  
  console.log('\\n✅ 프로젝트 생성 완료:');
  console.log('- 프로젝트 ID:', newProject.id);
  console.log('- 프로젝트명:', newProject.title);
  
  // 2. 초기 제안서 생성
  const proposalData = {
    project_id: newProject.id,
    designer_id: testDesigner.id,
    title: 'renegotiation_test_project 제안서',
    description: '재협상 테스트를 위한 초기 제안서입니다.',
    proposed_budget: 500000,
    estimated_duration: 14,
    approach: '전문적인 로고 디자인 서비스를 제공하겠습니다.',
    deliverables: ['초안 로고', '수정본', '최종 로고', '원본 파일'],
    timeline_description: '2주 내 완성 예정',
    status: 'submitted'
  };
  
  const { data: newProposal, error: proposalError } = await supabase
    .from('proposals')
    .insert(proposalData)
    .select()
    .single();
    
  if (proposalError) {
    console.error('제안서 생성 실패:', proposalError);
    return;
  }
  
  console.log('\\n✅ 초기 제안서 생성 완료:');
  console.log('- 제안서 ID:', newProposal.id);
  console.log('- 제안 예산:', newProposal.proposed_budget);
  
  // 3. 클라이언트의 수정 요청 생성
  const modificationRequest = {
    project_id: newProject.id,
    requested_by: testClient.id,
    
    // 원본 데이터 백업
    original_budget: newProposal.proposed_budget,
    original_duration: newProposal.estimated_duration,
    original_max_modifications: newProject.max_modifications,
    
    // 수정 요청 내용 (예산 40% 증가, 기간 1주 연장, 수정 횟수 2회 추가)
    new_budget: 700000, // 50만원 → 70만원
    new_duration: 21,   // 14일 → 21일
    new_max_modifications: 5, // 3회 → 5회
    new_start_date: new Date().toISOString().split('T')[0],
    new_draft_deadline: new Date(Date.now() + 10 * 24 * 60 * 60 * 1000).toISOString().split('T')[0], // 10일 후
    new_final_deadline: new Date(Date.now() + 21 * 24 * 60 * 60 * 1000).toISOString().split('T')[0], // 21일 후
    
    // 추가 요구사항
    additional_requirements: '더 복잡한 디자인이 필요합니다. 3D 효과와 애니메이션 버전도 포함해주세요.',
    
    // 상태
    status: 'pending'
  };
  
  const { data: newRequest, error: requestError } = await supabase
    .from('project_modification_requests')
    .insert(modificationRequest)
    .select()
    .single();
    
  if (requestError) {
    console.error('수정 요청 생성 실패:', requestError);
    return;
  }
  
  console.log('\\n✅ 수정 요청 생성 완료:');
  console.log('- 수정 요청 ID:', newRequest.id);
  console.log('- 기존 예산:', newRequest.original_budget, '→ 새 예산:', newRequest.new_budget);
  console.log('- 기존 기간:', newRequest.original_duration, '일 → 새 기간:', newRequest.new_duration, '일');
  console.log('- 기존 수정 횟수:', newRequest.original_max_modifications, '회 → 새 수정 횟수:', newRequest.new_max_modifications, '회');
  
  console.log('\\n🎯 재협상 테스트 준비 완료!');
  console.log('\\n다음 단계:');
  console.log('1. /proposals 페이지에서 "renegotiation_test_project" 수정 요청 확인');
  console.log('2. "재협상" 버튼 클릭하여 재협상 플로우 테스트');
  console.log('3. 기존 제안서가 업데이트되는지 확인 (새 제안서 생성 X)');
}

createFreshTestProject().catch(console.error);