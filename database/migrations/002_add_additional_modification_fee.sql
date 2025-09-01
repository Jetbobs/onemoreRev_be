-- Migration: 002_add_additional_modification_fee
-- Description: Add additional_modification_fee field to proposals table
-- Created: 2025-09-01

-- Add additional_modification_fee column to proposals table
ALTER TABLE proposals
ADD COLUMN additional_modification_fee INTEGER DEFAULT 0;

-- Update existing proposals with a default value (10% of proposed_budget or 50000)
UPDATE proposals 
SET additional_modification_fee = GREATEST(proposed_budget * 0.1, 50000)
WHERE additional_modification_fee IS NULL OR additional_modification_fee = 0;

-- Add comment to clarify the purpose
COMMENT ON COLUMN proposals.additional_modification_fee IS '추가 수정 요금 (원/회) - 무료 수정 횟수 초과 시 건당 부과될 요금';