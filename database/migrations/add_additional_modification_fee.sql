-- 제안서 테이블에 additional_modification_fee 컬럼 추가
-- 2025-09-02: 추가 수정 요금 컬럼 추가

ALTER TABLE proposals 
ADD COLUMN additional_modification_fee INTEGER DEFAULT 0;

-- 컬럼에 코멘트 추가
COMMENT ON COLUMN proposals.additional_modification_fee IS '추가 수정 요금 (원)';