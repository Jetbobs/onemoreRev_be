-- Migration: 003_add_modification_requests
-- Description: Add project modification requests table for tracking client modification proposals
-- Created: 2025-09-01

-- Create project modification requests table
CREATE TABLE project_modification_requests (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  proposal_id UUID REFERENCES proposals(id) ON DELETE SET NULL,
  requested_by UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  
  -- 원본 데이터 백업 (수정 전 상태 보존)
  original_budget INTEGER,
  original_duration INTEGER,
  original_max_modifications INTEGER,
  original_additional_modification_fee INTEGER,
  original_start_date DATE,
  original_draft_deadline DATE,
  original_final_deadline DATE,
  
  -- 수정 요청 내용
  new_budget INTEGER,
  new_duration INTEGER,
  new_max_modifications INTEGER,
  new_additional_modification_fee INTEGER,
  new_start_date DATE,
  new_draft_deadline DATE,
  new_final_deadline DATE,
  
  -- 추가 요구사항
  additional_requirements TEXT,
  attached_files JSONB, -- 첨부파일 정보 [{name, url, size}...]
  
  -- 결제 조건 수정
  new_payment_method VARCHAR(50),
  new_payment_terms JSONB, -- 결제 조건 상세 정보
  
  -- 상태 관리
  status VARCHAR(20) DEFAULT 'pending', -- pending, approved, rejected, withdrawn
  rejection_reason TEXT, -- 거부 시 사유
  
  -- 메타데이터
  metadata JSONB, -- 추가 메타데이터
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  responded_at TIMESTAMP WITH TIME ZONE,
  responded_by UUID REFERENCES users(id) ON DELETE SET NULL
);

-- Add indexes for performance
CREATE INDEX idx_modification_requests_project_id ON project_modification_requests(project_id);
CREATE INDEX idx_modification_requests_status ON project_modification_requests(status);
CREATE INDEX idx_modification_requests_requested_by ON project_modification_requests(requested_by);
CREATE INDEX idx_modification_requests_created_at ON project_modification_requests(created_at);

-- Add updated_at trigger
CREATE TRIGGER update_modification_requests_updated_at 
BEFORE UPDATE ON project_modification_requests 
FOR EACH ROW 
EXECUTE FUNCTION update_updated_at_column();

-- Add comments for clarity
COMMENT ON TABLE project_modification_requests IS '프로젝트 수정 제안 요청 테이블';
COMMENT ON COLUMN project_modification_requests.status IS '상태: pending(대기), approved(승인), rejected(거부), withdrawn(철회)';
COMMENT ON COLUMN project_modification_requests.original_budget IS '수정 전 원본 예산 (백업용)';
COMMENT ON COLUMN project_modification_requests.new_budget IS '수정 요청된 새로운 예산';
COMMENT ON COLUMN project_modification_requests.additional_requirements IS '추가 요구사항 및 수정 사유';
COMMENT ON COLUMN project_modification_requests.attached_files IS '첨부파일 정보 JSON 배열';

-- Add RLS policies
ALTER TABLE project_modification_requests ENABLE ROW LEVEL SECURITY;

-- 클라이언트는 자신이 요청한 수정 제안만 볼 수 있음
CREATE POLICY "Clients can view own modification requests" ON project_modification_requests
  FOR SELECT USING (
    requested_by = auth.uid() OR 
    project_id IN (
      SELECT id FROM projects WHERE client_id = auth.uid() OR designer_id = auth.uid()
    )
  );

-- 클라이언트는 자신의 프로젝트에 대해서만 수정 제안 생성 가능
CREATE POLICY "Clients can create modification requests" ON project_modification_requests
  FOR INSERT WITH CHECK (
    requested_by = auth.uid() AND
    project_id IN (SELECT id FROM projects WHERE client_id = auth.uid())
  );

-- 디자이너는 자신의 프로젝트에 대한 수정 제안에 응답 가능
CREATE POLICY "Designers can update modification requests" ON project_modification_requests
  FOR UPDATE USING (
    project_id IN (SELECT id FROM projects WHERE designer_id = auth.uid())
  );

-- 관리자는 모든 수정 제안 관리 가능
CREATE POLICY "Admins can manage all modification requests" ON project_modification_requests
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() AND users.role = 'admin'
    )
  );