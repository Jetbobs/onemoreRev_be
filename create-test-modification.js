const { createClient } = require('@supabase/supabase-js');
require('dotenv').config();

const supabase = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_SERVICE_ROLE_KEY);

async function createTestModificationRequest() {
  console.log('=== test_4 제안서에 대한 테스트 수정 요청 생성 ===');
  
  // test_4 제안서 정보 가져오기
  const { data: proposal, error: propError } = await supabase
    .from('proposals')
    .select('*')
    .ilike('title', '%test_4%')
    .single();
    
  if (propError || !proposal) {
    console.error('test_4 제안서를 찾을 수 없습니다:', propError);
    return;
  }
  
  console.log('test_4 제안서 정보:');
  console.log('- ID:', proposal.id);
  console.log('- 프로젝트 ID:', proposal.project_id);
  console.log('- 현재 예산:', proposal.proposed_budget);
  console.log('- 현재 기간:', proposal.estimated_duration, '일');
  
  // 프로젝트 정보도 가져오기
  const { data: project, error: projError } = await supabase
    .from('projects')
    .select('*')
    .eq('id', proposal.project_id)
    .single();
    
  if (projError || !project) {
    console.error('프로젝트 정보를 찾을 수 없습니다:', projError);
    return;
  }
  
  console.log('프로젝트 정보:');
  console.log('- 클라이언트 ID:', project.client_id);
  console.log('- 현재 수정 횟수:', project.max_modifications);
  
  // 테스트용 수정 요청 생성
  const modificationRequest = {
    project_id: proposal.project_id,
    requested_by: project.client_id,
    
    // 원본 데이터 백업
    original_budget: proposal.proposed_budget,
    original_duration: proposal.estimated_duration,
    original_max_modifications: project.max_modifications,
    
    // 수정 요청 내용 (예산 20% 증가, 기간 5일 연장, 수정 횟수 2회 추가)
    new_budget: Math.round(proposal.proposed_budget * 1.2),
    new_duration: (proposal.estimated_duration || 14) + 5,
    new_max_modifications: (project.max_modifications || 3) + 2,
    
    // 추가 요구사항
    additional_requirements: '재협상 테스트: 더 상세한 디자인과 추가 수정이 필요합니다.',
    
    // 상태
    status: 'pending'
  };
  
  console.log('\n생성할 수정 요청:');
  console.log('- 기존 예산:', modificationRequest.original_budget, '→ 새 예산:', modificationRequest.new_budget);
  console.log('- 기존 기간:', modificationRequest.original_duration, '일 → 새 기간:', modificationRequest.new_duration, '일');
  console.log('- 기존 수정 횟수:', modificationRequest.original_max_modifications, '회 → 새 수정 횟수:', modificationRequest.new_max_modifications, '회');
  
  // 데이터베이스에 삽입
  const { data: newRequest, error: insertError } = await supabase
    .from('project_modification_requests')
    .insert(modificationRequest)
    .select()
    .single();
    
  if (insertError) {
    console.error('수정 요청 생성 실패:', insertError);
    return;
  }
  
  console.log('\n✅ 수정 요청이 성공적으로 생성되었습니다!');
  console.log('수정 요청 ID:', newRequest.id);
  console.log('\n이제 /proposals 페이지에서 이 수정 요청에 대해 재협상을 테스트할 수 있습니다.');
}

createTestModificationRequest().catch(console.error);