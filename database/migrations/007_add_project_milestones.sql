-- 프로젝트 마일스톤 테이블 생성
CREATE TABLE IF NOT EXISTS project_milestones (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id UUID REFERENCES projects(id) ON DELETE CASCADE,
  title VARCHAR(255) NOT NULL,
  description TEXT,
  sequence_order INTEGER NOT NULL,
  weight DECIMAL(5,2) DEFAULT 1.0,
  status VARCHAR(50) DEFAULT 'pending',
  completed_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  
  -- 인덱스
  CONSTRAINT valid_status CHECK (status IN ('pending', 'in_progress', 'completed')),
  CONSTRAINT positive_weight CHECK (weight > 0),
  CONSTRAINT positive_sequence CHECK (sequence_order > 0)
);

-- 인덱스 생성
CREATE INDEX IF NOT EXISTS idx_project_milestones_project_id ON project_milestones(project_id);
CREATE INDEX IF NOT EXISTS idx_project_milestones_sequence ON project_milestones(project_id, sequence_order);

-- RLS 정책 (Row Level Security)
ALTER TABLE project_milestones ENABLE ROW LEVEL SECURITY;

-- 프로젝트 참여자만 마일스톤 조회 가능
CREATE POLICY "Users can view milestones of their projects" ON project_milestones
  FOR SELECT USING (
    project_id IN (
      SELECT id FROM projects 
      WHERE client_id = auth.uid() OR designer_id = auth.uid()
    )
  );

-- 디자이너만 마일스톤 상태 업데이트 가능
CREATE POLICY "Designers can update milestones" ON project_milestones
  FOR UPDATE USING (
    project_id IN (
      SELECT id FROM projects 
      WHERE designer_id = auth.uid()
    )
  );

-- 관리자는 모든 권한
CREATE POLICY "Admins have full access to milestones" ON project_milestones
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );