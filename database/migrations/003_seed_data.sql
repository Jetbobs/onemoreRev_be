-- Migration: 003_seed_data
-- Description: Initial seed data for testing deegongso platform
-- Created: 2025-08-29
-- NOTE: This should be run AFTER user authentication is set up

-- =====================================================
-- SEED USERS (These will be inserted via application after auth signup)
-- =====================================================

-- Mock Admin User
INSERT INTO users (id, email, name, phone, role, admin_level, admin_permissions, created_at) 
VALUES (
  'a0000000-0000-0000-0000-000000000001',
  'admin@deegongso.com',
  '시스템 관리자',
  '010-0000-0001',
  'admin',
  'super',
  '{"user_management": true, "dispute_resolution": true, "system_settings": true, "analytics_access": true}',
  NOW()
) ON CONFLICT (id) DO NOTHING;

-- Mock Client Users
INSERT INTO users (id, email, name, phone, role, company, department, title, created_at) 
VALUES 
  (
    'c0000000-0000-0000-0000-000000000001',
    'client1@example.com', 
    '김클라이언트',
    '010-1234-5678',
    'client',
    '스타트업 ABC',
    '마케팅팀',
    '팀장',
    NOW()
  ),
  (
    'c0000000-0000-0000-0000-000000000002',
    'client2@example.com',
    '이기업',
    '010-2345-6789', 
    'client',
    '테크 기업',
    'CEO',
    '대표이사',
    NOW()
  )
ON CONFLICT (id) DO NOTHING;

-- Mock Designer Users  
INSERT INTO users (id, email, name, phone, role, experience, specialization, portfolio_url, strengths, is_verified, bio, created_at)
VALUES
  (
    'd0000000-0000-0000-0000-000000000001',
    'designer1@example.com',
    '박디자이너', 
    '010-9876-5432',
    'designer',
    '3-5년',
    ARRAY['로고 디자인', '브랜드 아이덴티티', 'UI/UX'],
    'https://portfolio.example.com/designer1',
    ARRAY['창의적 사고', '빠른 커뮤니케이션', '트렌드 감각'],
    true,
    '안녕하세요! 3년차 브랜드 디자이너 박디자이너입니다. 클라이언트의 비전을 정확히 파악하여 최고의 결과물을 만들어드리겠습니다.',
    NOW()
  ),
  (
    'd0000000-0000-0000-0000-000000000002',
    'designer2@example.com',
    '정아트',
    '010-8765-4321',
    'designer', 
    '5-7년',
    ARRAY['웹 디자인', '모바일 UI', '일러스트레이션'],
    'https://portfolio.example.com/designer2',
    ARRAY['세심한 디테일', '사용자 중심 디자인', '빠른 작업'],
    true,
    '5년차 UX/UI 디자이너입니다. 사용자 경험을 최우선으로 하는 실용적이면서도 아름다운 디자인을 추구합니다.',
    NOW()
  )
ON CONFLICT (id) DO NOTHING;

-- =====================================================
-- SEED PROJECTS
-- =====================================================

INSERT INTO projects (
  id, client_id, title, description, project_type, status, 
  budget_min, budget_max, expected_duration, deadline,
  requirements, target_audience, preferred_style, 
  reference_materials, max_modifications, created_at
) VALUES
  (
    'p0000000-0000-0000-0000-000000000001',
    'c0000000-0000-0000-0000-000000000001',
    '스타트업 ABC 로고 디자인',
    '스타트업을 위한 모던하고 혁신적인 로고 디자인을 의뢰드립니다. 기술 스타트업의 이미지를 잘 표현할 수 있는 로고가 필요합니다.',
    'logo_design',
    'review_requested',
    500000,
    1000000,
    7,
    CURRENT_DATE + INTERVAL '14 days',
    '- 모던하고 깔끔한 디자인\n- 확장성 있는 로고 (다양한 크기에서 활용 가능)\n- 컬러/흑백 버전 모두 제공\n- AI, PNG, SVG 파일 형식 제공',
    '20-30대 IT 관심층, 초기 투자자',
    '미니멀, 모던, 테크',
    ARRAY['https://example.com/ref1.jpg', 'https://example.com/ref2.jpg'],
    3,
    NOW() - INTERVAL '2 days'
  ),
  (
    'p0000000-0000-0000-0000-000000000002', 
    'c0000000-0000-0000-0000-000000000002',
    '테크 기업 브랜드 아이덴티티',
    '기업의 새로운 브랜드 아이덴티티 전체를 구축하고 싶습니다. 로고, 명함, 레터헤드 등이 포함된 종합적인 브랜딩 프로젝트입니다.',
    'brand_identity',
    'creation_pending',
    2000000,
    5000000,
    21,
    CURRENT_DATE + INTERVAL '30 days',
    '- 로고 디자인\n- 명함 디자인\n- 레터헤드\n- 브랜드 가이드라인\n- 컬러 팔레트\n- 타이포그래피 가이드',
    '기업 고객, B2B 파트너',
    '프로페셔널, 신뢰감, 혁신적',
    ARRAY['https://example.com/brand1.jpg', 'https://example.com/brand2.jpg'],
    5,
    NOW() - INTERVAL '1 day'
  ),
  (
    'p0000000-0000-0000-0000-000000000003',
    'c0000000-0000-0000-0000-000000000001', 
    '모바일 앱 UI 디자인',
    '스타트업 모바일 앱의 전체 UI 디자인을 의뢰합니다. 사용자 친화적이면서도 직관적인 인터페이스가 필요합니다.',
    'mobile_app_ui',
    'in_progress',
    3000000,
    4000000,
    30,
    CURRENT_DATE + INTERVAL '45 days',
    '- 메인 스크린 디자인\n- 사용자 가입/로그인 플로우\n- 핵심 기능 화면들\n- 아이콘 세트\n- 디자인 시스템',
    '20-40대 모바일 사용자',
    '모던, 사용자 중심, 직관적',
    ARRAY['https://example.com/app1.jpg', 'https://example.com/app2.jpg'],
    4,
    NOW() - INTERVAL '5 days'
  )
ON CONFLICT (id) DO NOTHING;

-- Update project with designer assignment for in-progress project
UPDATE projects 
SET designer_id = 'd0000000-0000-0000-0000-000000000002'
WHERE id = 'p0000000-0000-0000-0000-000000000003';

-- =====================================================
-- SEED PROPOSALS  
-- =====================================================

INSERT INTO proposals (
  id, project_id, designer_id, title, description, 
  proposed_budget, estimated_duration, approach, 
  deliverables, timeline_description, sample_works, 
  status, created_at
) VALUES
  (
    'pr000000-0000-0000-0000-000000000001',
    'p0000000-0000-0000-0000-000000000001',
    'd0000000-0000-0000-0000-000000000001',
    '스타트업 ABC 로고 - 혁신적이고 기억에 남는 디자인',
    '스타트업 ABC의 비전과 가치를 담은 독창적인 로고를 제안드립니다. 3가지 컨셉으로 시작하여 최종안을 완성해드리겠습니다.',
    800000,
    7,
    '1단계: 브랜드 분석 및 컨셉 설정\n2단계: 3가지 초기 디자인 컨셉 제시\n3단계: 선택된 컨셉 정교화\n4단계: 최종 파일 제작 및 전달',
    ARRAY['로고 시안 3종', '최종 로고 (AI, PNG, SVG)', '컬러/흑백 버전', '사용 가이드라인'],
    '1-2일: 컨셉 설계\n3-5일: 시안 제작\n6-7일: 수정 및 최종 완성',
    ARRAY['https://portfolio.com/logo1.jpg', 'https://portfolio.com/logo2.jpg'],
    'submitted',
    NOW() - INTERVAL '1 day'
  ),
  (
    'pr000000-0000-0000-0000-000000000002', 
    'p0000000-0000-0000-0000-000000000001',
    'd0000000-0000-0000-0000-000000000002',
    'ABC 로고 - 테크 스타트업 전문 디자인',
    '테크 스타트업 전문 디자이너로서 혁신적이면서도 확장성 있는 로고를 제안합니다.',
    750000,
    5,
    '스타트업의 핵심 가치 분석 → 테크 트렌드 반영 → 심볼+워드마크 조합 → 확장성 테스트',
    ARRAY['초기 컨셉 5종', '정교화 3종', '최종안 완성', '전체 파일 패키지'],
    '빠른 작업으로 5일 완성 가능',
    ARRAY['https://portfolio.com/tech1.jpg', 'https://portfolio.com/tech2.jpg'],
    'submitted', 
    NOW() - INTERVAL '6 hours'
  )
ON CONFLICT (id) DO NOTHING;

-- =====================================================
-- SEED PROJECT FILES
-- =====================================================

INSERT INTO project_files (
  id, project_id, uploaded_by, file_name, file_url, 
  file_type, file_size, category, version, description, created_at
) VALUES
  (
    'f0000000-0000-0000-0000-000000000001',
    'p0000000-0000-0000-0000-000000000001',
    'c0000000-0000-0000-0000-000000000001',
    'reference_logos.pdf',
    'https://storage.supabase.co/example/reference_logos.pdf',
    'application/pdf',
    2048576,
    'reference',
    1,
    '참고하고 싶은 로고 예시들을 모았습니다.',
    NOW() - INTERVAL '1 day'
  ),
  (
    'f0000000-0000-0000-0000-000000000002',
    'p0000000-0000-0000-0000-000000000003',
    'd0000000-0000-0000-0000-000000000002', 
    'wireframe_v1.fig',
    'https://storage.supabase.co/example/wireframe_v1.fig',
    'application/octet-stream',
    5242880,
    'deliverable',
    1,
    '초기 와이어프레임 작업물입니다.',
    NOW() - INTERVAL '2 days'
  )
ON CONFLICT (id) DO NOTHING;

-- =====================================================
-- SEED FEEDBACK
-- =====================================================

INSERT INTO feedback (
  id, project_id, created_by, feedback_type, status, 
  title, content, is_modification_request, 
  modification_priority, estimated_hours, created_at
) VALUES
  (
    'fb000000-0000-0000-0000-000000000001',
    'p0000000-0000-0000-0000-000000000003',
    'c0000000-0000-0000-0000-000000000001',
    'revision_request',
    'pending',
    '메인 화면 컬러 수정 요청',
    '메인 화면의 전체적인 컬러톤을 좀 더 밝게 조정해주시면 좋겠습니다. 현재 버전이 약간 어둡게 느껴집니다.',
    true,
    2,
    4,
    NOW() - INTERVAL '1 day'
  ),
  (
    'fb000000-0000-0000-0000-000000000002',
    'p0000000-0000-0000-0000-000000000003', 
    'd0000000-0000-0000-0000-000000000002',
    'general',
    'pending',
    '초기 와이어프레임 완성',
    '요청하신 메인 화면들의 초기 와이어프레임을 완성했습니다. 검토 후 피드백 주시면 다음 단계로 진행하겠습니다.',
    false,
    NULL,
    NULL,
    NOW() - INTERVAL '2 days'
  )
ON CONFLICT (id) DO NOTHING;

-- =====================================================
-- SEED FEEDBACK COMMENTS
-- =====================================================

INSERT INTO feedback_comments (
  id, feedback_id, user_id, content, created_at
) VALUES
  (
    'fc000000-0000-0000-0000-000000000001',
    'fb000000-0000-0000-0000-000000000001',
    'd0000000-0000-0000-0000-000000000002',
    '네, 컬러 조정 작업하겠습니다. 좀 더 밝고 활기찬 톤으로 변경해드릴게요.',
    NOW() - INTERVAL '6 hours'
  ),
  (
    'fc000000-0000-0000-0000-000000000002',
    'fb000000-0000-0000-0000-000000000002',
    'c0000000-0000-0000-0000-000000000001',
    '와이어프레임 확인했습니다. 전체적으로 만족스럽네요. 다음 단계 진행해주세요!',
    NOW() - INTERVAL '1 day'
  )
ON CONFLICT (id) DO NOTHING;

-- =====================================================
-- SEED NOTIFICATIONS  
-- =====================================================

INSERT INTO notifications (
  id, user_id, type, title, message, project_id, 
  feedback_id, is_read, created_at
) VALUES
  (
    'n0000000-0000-0000-0000-000000000001',
    'd0000000-0000-0000-0000-000000000001',
    'proposal_received',
    '새로운 프로젝트 제안 기회',
    '스타트업 ABC 로고 디자인 프로젝트에 제안서를 제출해보세요.',
    'p0000000-0000-0000-0000-000000000001',
    NULL,
    false,
    NOW() - INTERVAL '1 day'
  ),
  (
    'n0000000-0000-0000-0000-000000000002',
    'c0000000-0000-0000-0000-000000000001',
    'feedback_submitted',
    '새 피드백이 등록되었습니다', 
    '모바일 앱 UI 디자인 프로젝트에 새로운 피드백이 등록되었습니다.',
    'p0000000-0000-0000-0000-000000000003',
    'fb000000-0000-0000-0000-000000000002',
    true,
    NOW() - INTERVAL '2 days'
  ),
  (
    'n0000000-0000-0000-0000-000000000003',
    'd0000000-0000-0000-0000-000000000002',
    'modification_requested',
    '수정 요청이 접수되었습니다',
    '모바일 앱 UI 디자인 프로젝트에 수정 요청이 접수되었습니다.',
    'p0000000-0000-0000-0000-000000000003',
    'fb000000-0000-0000-0000-000000000001',
    false,
    NOW() - INTERVAL '1 day'
  )
ON CONFLICT (id) DO NOTHING;

-- =====================================================
-- SEED ANNOUNCEMENTS
-- =====================================================

INSERT INTO announcements (
  id, created_by, title, content, summary, status, 
  target_audience, is_important, published_at, created_at
) VALUES
  (
    'an000000-0000-0000-0000-000000000001',
    'a0000000-0000-0000-0000-000000000001',
    '디공소 플랫폼 베타 오픈!',
    '안녕하세요! 디공소 플랫폼이 베타 서비스를 시작합니다.\n\n주요 기능:\n- 프로젝트 의뢰 및 관리\n- 실시간 피드백 시스템\n- 안전한 결제 시스템\n- 분쟁 해결 지원\n\n많은 관심과 참여 부탁드립니다!',
    '디공소 베타 서비스가 시작되었습니다!',
    'published',
    'all',
    true,
    NOW() - INTERVAL '3 days',
    NOW() - INTERVAL '3 days'
  )
ON CONFLICT (id) DO NOTHING;

-- =====================================================
-- UPDATE SOME RECORDS FOR REALISTIC DATA
-- =====================================================

-- Update project modification count (simulate feedback processing)
UPDATE projects 
SET current_modifications = 1
WHERE id = 'p0000000-0000-0000-0000-000000000003';

-- Mark some notifications as read
UPDATE notifications 
SET is_read = true, read_at = NOW() - INTERVAL '1 day'
WHERE id = 'n0000000-0000-0000-0000-000000000002';

-- =====================================================
-- SEED DATA COMPLETED
-- =====================================================

-- Summary of seeded data:
-- - 1 Admin user, 2 Client users, 2 Designer users  
-- - 3 Projects (various statuses)
-- - 2 Proposals for first project
-- - 2 Project files
-- - 2 Feedback items with 2 comments
-- - 3 Notifications
-- - 1 Published announcement

-- Next steps:
-- 1. Set up Supabase project and run these migrations
-- 2. Configure Supabase Storage buckets for file uploads
-- 3. Set up authentication providers (Google OAuth)
-- 4. Test database with actual Supabase client connections