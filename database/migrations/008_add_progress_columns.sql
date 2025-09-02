-- projects 테이블에 진행률 관련 컬럼 추가
ALTER TABLE projects 
ADD COLUMN IF NOT EXISTS progress_percentage DECIMAL(5,2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS total_milestones INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS completed_milestones INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS last_milestone_updated_at TIMESTAMP;

-- 제약 조건 추가
ALTER TABLE projects 
ADD CONSTRAINT IF NOT EXISTS valid_progress_percentage 
CHECK (progress_percentage >= 0 AND progress_percentage <= 100);

-- 진행률 자동 계산 함수
CREATE OR REPLACE FUNCTION calculate_project_progress(project_uuid UUID)
RETURNS DECIMAL(5,2) AS $$
DECLARE
    total_weight DECIMAL(10,2) := 0;
    completed_weight DECIMAL(10,2) := 0;
    progress DECIMAL(5,2) := 0;
BEGIN
    -- 총 가중치 계산
    SELECT COALESCE(SUM(weight), 0) INTO total_weight
    FROM project_milestones
    WHERE project_id = project_uuid;
    
    -- 완료된 마일스톤의 가중치 계산
    SELECT COALESCE(SUM(weight), 0) INTO completed_weight
    FROM project_milestones
    WHERE project_id = project_uuid AND status = 'completed';
    
    -- 진행률 계산
    IF total_weight > 0 THEN
        progress := ROUND((completed_weight / total_weight) * 100, 2);
    END IF;
    
    -- projects 테이블 업데이트
    UPDATE projects 
    SET 
        progress_percentage = progress,
        total_milestones = (
            SELECT COUNT(*) FROM project_milestones 
            WHERE project_id = project_uuid
        ),
        completed_milestones = (
            SELECT COUNT(*) FROM project_milestones 
            WHERE project_id = project_uuid AND status = 'completed'
        ),
        last_milestone_updated_at = NOW()
    WHERE id = project_uuid;
    
    RETURN progress;
END;
$$ LANGUAGE plpgsql;

-- 마일스톤 상태 변경 시 자동으로 진행률 업데이트하는 트리거
CREATE OR REPLACE FUNCTION update_project_progress_trigger()
RETURNS TRIGGER AS $$
BEGIN
    -- 마일스톤이 변경된 프로젝트의 진행률 재계산
    PERFORM calculate_project_progress(
        COALESCE(NEW.project_id, OLD.project_id)
    );
    
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- 트리거 생성
DROP TRIGGER IF EXISTS trigger_update_project_progress ON project_milestones;
CREATE TRIGGER trigger_update_project_progress
    AFTER INSERT OR UPDATE OR DELETE ON project_milestones
    FOR EACH ROW
    EXECUTE FUNCTION update_project_progress_trigger();