-- Migration: 001_initial_schema
-- Description: Initial database schema setup for deegongso platform
-- Created: 2025-08-29

-- 이 마이그레이션은 schema.sql의 내용과 동일하지만 
-- 단계별로 실행할 수 있도록 분리된 버전입니다.

-- Step 1: Extensions and Types
-- 필요한 확장 기능 활성화
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- 사용자 역할 enum
CREATE TYPE user_role AS ENUM ('client', 'designer', 'admin');
CREATE TYPE admin_level AS ENUM ('super', 'moderator', 'support');

-- 프로젝트 관련 enum
CREATE TYPE project_status AS ENUM (
  'creation_pending',
  'review_requested', 
  'client_review_pending',
  'designer_review_pending',
  'in_progress',
  'feedback_period',
  'modification_in_progress',
  'completion_requested',
  'completed',
  'cancelled',
  'disputed'
);

CREATE TYPE project_type AS ENUM (
  'logo_design',
  'business_card',
  'poster_design',
  'brochure',
  'packaging',
  'web_design',
  'mobile_app_ui',
  'brand_identity',
  'illustration',
  'other'
);

-- 제안서 관련 enum
CREATE TYPE proposal_status AS ENUM ('submitted', 'accepted', 'rejected', 'withdrawn');

-- 피드백 관련 enum  
CREATE TYPE feedback_type AS ENUM ('general', 'markup', 'revision_request', 'approval');
CREATE TYPE feedback_status AS ENUM ('pending', 'addressed', 'resolved', 'rejected');

-- 결제 관련 enum
CREATE TYPE payment_status AS ENUM ('pending', 'completed', 'failed', 'refunded', 'cancelled');
CREATE TYPE payment_type AS ENUM ('project_payment', 'additional_work', 'dispute_resolution');

-- 알림 관련 enum
CREATE TYPE notification_type AS ENUM (
  'project_created',
  'proposal_received', 
  'proposal_accepted',
  'feedback_submitted',
  'modification_requested',
  'project_completed',
  'payment_completed',
  'dispute_created',
  'system_announcement'
);

-- 분쟁 관련 enum
CREATE TYPE dispute_status AS ENUM ('open', 'investigating', 'resolved', 'closed');
CREATE TYPE dispute_type AS ENUM ('quality_issue', 'payment_issue', 'communication_issue', 'deadline_issue', 'other');

-- 제재 관련 enum
CREATE TYPE sanction_type AS ENUM ('warning', 'temporary_suspension', 'permanent_ban', 'feature_restriction');

-- 관리자 로그 enum
CREATE TYPE admin_action_type AS ENUM (
  'user_sanctioned',
  'dispute_resolved', 
  'user_verified',
  'project_cancelled',
  'payment_refunded',
  'system_maintenance'
);

-- 공지사항 관련 enum
CREATE TYPE announcement_status AS ENUM ('draft', 'scheduled', 'published', 'archived');
CREATE TYPE announcement_target AS ENUM ('all', 'clients', 'designers', 'admins');

-- Step 2: Core Tables Creation

-- 사용자 테이블 (Supabase auth.users와 연동)
CREATE TABLE users (
  id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  email VARCHAR(255) UNIQUE NOT NULL,
  name VARCHAR(100) NOT NULL,
  phone VARCHAR(20),
  role user_role NOT NULL DEFAULT 'client',
  avatar_url TEXT,
  
  -- 클라이언트 전용 필드
  company VARCHAR(200),
  department VARCHAR(100),
  title VARCHAR(100), -- 직책
  
  -- 디자이너 전용 필드
  experience VARCHAR(50), -- 경력 (예: "3-5년")
  specialization TEXT[], -- 전문분야 배열
  portfolio_url TEXT,
  strengths TEXT[], -- 강점 배열
  is_verified BOOLEAN DEFAULT false, -- 인증 여부
  bio TEXT, -- 자기소개
  
  -- 어드민 전용 필드
  admin_level admin_level,
  admin_permissions JSONB, -- 어드민 권한 설정
  
  -- 타임스탬프
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 프로젝트 테이블
CREATE TABLE projects (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  client_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  designer_id UUID REFERENCES users(id) ON DELETE SET NULL,
  
  title VARCHAR(200) NOT NULL,
  description TEXT NOT NULL,
  project_type project_type NOT NULL,
  status project_status DEFAULT 'creation_pending',
  
  -- 예산 및 기간
  budget_min INTEGER, -- 최소 예산 (원)
  budget_max INTEGER, -- 최대 예산 (원)
  expected_duration INTEGER, -- 예상 기간 (일)
  deadline DATE, -- 마감일
  
  -- 프로젝트 상세 정보
  requirements TEXT, -- 요구사항
  target_audience TEXT, -- 타겟 고객
  preferred_style TEXT, -- 선호 스타일
  reference_materials TEXT[], -- 참고자료 URL 배열
  
  -- 수정 관련
  max_modifications INTEGER DEFAULT 3, -- 최대 수정 횟수
  current_modifications INTEGER DEFAULT 0, -- 현재 수정 횟수
  
  -- 메타데이터
  metadata JSONB, -- 추가 프로젝트 메타데이터
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  completed_at TIMESTAMP WITH TIME ZONE
);

-- 제안서 테이블
CREATE TABLE proposals (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  designer_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  
  title VARCHAR(200) NOT NULL,
  description TEXT NOT NULL,
  proposed_budget INTEGER NOT NULL, -- 제안 예산
  estimated_duration INTEGER NOT NULL, -- 예상 소요 기간 (일)
  
  -- 제안서 상세
  approach TEXT, -- 접근 방법
  deliverables TEXT[], -- 제공할 산출물 목록
  timeline_description TEXT, -- 일정 설명
  sample_works TEXT[], -- 샘플 작품 URL 배열
  
  status proposal_status DEFAULT 'submitted',
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  responded_at TIMESTAMP WITH TIME ZONE
);

-- 프로젝트 파일 테이블
CREATE TABLE project_files (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  uploaded_by UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  
  file_name VARCHAR(255) NOT NULL,
  file_url TEXT NOT NULL, -- Supabase Storage URL
  file_type VARCHAR(50), -- MIME type
  file_size INTEGER, -- 파일 크기 (bytes)
  
  -- 파일 분류
  category VARCHAR(50), -- 'reference', 'deliverable', 'feedback', 'final'
  version INTEGER DEFAULT 1,
  description TEXT,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 피드백 테이블
CREATE TABLE feedback (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  created_by UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  
  feedback_type feedback_type NOT NULL DEFAULT 'general',
  status feedback_status DEFAULT 'pending',
  
  title VARCHAR(200),
  content TEXT NOT NULL,
  
  -- 마크업 관련 (이미지 피드백용)
  target_file_id UUID REFERENCES project_files(id),
  markup_data JSONB, -- 마크업 좌표 및 주석 데이터
  
  -- 수정 요청 관련
  is_modification_request BOOLEAN DEFAULT false,
  modification_priority INTEGER, -- 1: 낮음, 2: 보통, 3: 높음, 4: 긴급
  estimated_hours INTEGER, -- 예상 수정 소요 시간
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  resolved_at TIMESTAMP WITH TIME ZONE
);

-- 피드백 댓글 테이블
CREATE TABLE feedback_comments (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  feedback_id UUID NOT NULL REFERENCES feedback(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  
  content TEXT NOT NULL,
  parent_comment_id UUID REFERENCES feedback_comments(id), -- 대댓글용
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Step 3: Business Logic Tables

-- 결제 테이블
CREATE TABLE payments (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  client_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  designer_id UUID REFERENCES users(id) ON DELETE SET NULL,
  
  amount INTEGER NOT NULL, -- 결제 금액 (원)
  payment_type payment_type DEFAULT 'project_payment',
  status payment_status DEFAULT 'pending',
  
  -- 결제 관련 정보
  payment_method VARCHAR(50), -- 결제 수단
  transaction_id VARCHAR(100), -- 결제 서비스 거래 ID
  
  -- 수수료 정보
  platform_fee INTEGER, -- 플랫폼 수수료
  designer_amount INTEGER, -- 디자이너 정산 금액
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  paid_at TIMESTAMP WITH TIME ZONE,
  refunded_at TIMESTAMP WITH TIME ZONE
);

-- 알림 테이블
CREATE TABLE notifications (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  
  type notification_type NOT NULL,
  title VARCHAR(200) NOT NULL,
  message TEXT NOT NULL,
  
  -- 관련 데이터 ID
  project_id UUID REFERENCES projects(id) ON DELETE SET NULL,
  feedback_id UUID REFERENCES feedback(id) ON DELETE SET NULL,
  
  -- 알림 상태
  is_read BOOLEAN DEFAULT false,
  is_sent BOOLEAN DEFAULT false, -- 푸시 알림 발송 여부
  
  -- 추가 데이터
  metadata JSONB,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  read_at TIMESTAMP WITH TIME ZONE
);

-- Step 4: Admin Tables

-- 분쟁 테이블 (Admin 기능)
CREATE TABLE disputes (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  created_by UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  assigned_admin UUID REFERENCES users(id) ON DELETE SET NULL,
  
  dispute_type dispute_type NOT NULL,
  status dispute_status DEFAULT 'open',
  
  title VARCHAR(200) NOT NULL,
  description TEXT NOT NULL,
  
  -- 분쟁 해결
  admin_notes TEXT,
  resolution TEXT,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  resolved_at TIMESTAMP WITH TIME ZONE
);

-- 사용자 제재 테이블 (Admin 기능)
CREATE TABLE user_sanctions (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  sanctioned_by UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  
  sanction_type sanction_type NOT NULL,
  reason TEXT NOT NULL,
  duration_days INTEGER, -- 제재 기간 (일) - permanent_ban인 경우 NULL
  
  is_active BOOLEAN DEFAULT true,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  expires_at TIMESTAMP WITH TIME ZONE,
  lifted_at TIMESTAMP WITH TIME ZONE
);

-- 관리자 로그 테이블
CREATE TABLE admin_logs (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  admin_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  
  action_type admin_action_type NOT NULL,
  target_user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  target_project_id UUID REFERENCES projects(id) ON DELETE SET NULL,
  
  description TEXT NOT NULL,
  metadata JSONB, -- 추가 로그 데이터
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 공지사항 테이블 (Admin 기능)
CREATE TABLE announcements (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  created_by UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  
  title VARCHAR(200) NOT NULL,
  content TEXT NOT NULL,
  summary TEXT, -- 요약 (알림용)
  
  status announcement_status DEFAULT 'draft',
  target_audience announcement_target DEFAULT 'all',
  
  is_important BOOLEAN DEFAULT false, -- 중요 공지
  is_popup BOOLEAN DEFAULT false, -- 팝업 표시
  
  -- 발행 관련
  published_at TIMESTAMP WITH TIME ZONE,
  expires_at TIMESTAMP WITH TIME ZONE,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 공지사항 읽음 상태 테이블
CREATE TABLE announcement_reads (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  announcement_id UUID NOT NULL REFERENCES announcements(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  
  read_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  
  UNIQUE(announcement_id, user_id)
);

-- Step 5: Indexes for Performance

-- 사용자 관련
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_users_email ON users(email);

-- 프로젝트 관련  
CREATE INDEX idx_projects_client_id ON projects(client_id);
CREATE INDEX idx_projects_designer_id ON projects(designer_id);
CREATE INDEX idx_projects_status ON projects(status);
CREATE INDEX idx_projects_created_at ON projects(created_at);

-- 제안서 관련
CREATE INDEX idx_proposals_project_id ON proposals(project_id);
CREATE INDEX idx_proposals_designer_id ON proposals(designer_id);
CREATE INDEX idx_proposals_status ON proposals(status);

-- 파일 관련
CREATE INDEX idx_project_files_project_id ON project_files(project_id);
CREATE INDEX idx_project_files_category ON project_files(category);

-- 피드백 관련
CREATE INDEX idx_feedback_project_id ON feedback(project_id);
CREATE INDEX idx_feedback_created_by ON feedback(created_by);
CREATE INDEX idx_feedback_status ON feedback(status);
CREATE INDEX idx_feedback_comments_feedback_id ON feedback_comments(feedback_id);

-- 결제 관련
CREATE INDEX idx_payments_project_id ON payments(project_id);
CREATE INDEX idx_payments_client_id ON payments(client_id);
CREATE INDEX idx_payments_status ON payments(status);

-- 알림 관련
CREATE INDEX idx_notifications_user_id ON notifications(user_id);
CREATE INDEX idx_notifications_is_read ON notifications(is_read);
CREATE INDEX idx_notifications_created_at ON notifications(created_at);

-- 분쟁 관련
CREATE INDEX idx_disputes_project_id ON disputes(project_id);
CREATE INDEX idx_disputes_status ON disputes(status);
CREATE INDEX idx_disputes_assigned_admin ON disputes(assigned_admin);

-- 공지사항 관련
CREATE INDEX idx_announcements_status ON announcements(status);
CREATE INDEX idx_announcements_published_at ON announcements(published_at);
CREATE INDEX idx_announcement_reads_user_id ON announcement_reads(user_id);

-- Step 6: Triggers and Functions

-- 트리거 함수: updated_at 자동 업데이트
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$ language 'plpgsql';

-- updated_at 트리거 등록
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_projects_updated_at BEFORE UPDATE ON projects FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_proposals_updated_at BEFORE UPDATE ON proposals FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_feedback_updated_at BEFORE UPDATE ON feedback FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_feedback_comments_updated_at BEFORE UPDATE ON feedback_comments FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_disputes_updated_at BEFORE UPDATE ON disputes FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_announcements_updated_at BEFORE UPDATE ON announcements FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Migration completed successfully
-- Next steps:
-- 1. Run this migration in Supabase SQL editor
-- 2. Set up RLS policies (see 002_rls_policies.sql)
-- 3. Add initial seed data (see 003_seed_data.sql)