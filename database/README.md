# Deegongso Database Setup Guide

## 개요
이 폴더는 Deegongso (디공소) 플랫폼의 Supabase PostgreSQL 데이터베이스 스키마와 관련 파일들을 포함합니다.

## 파일 구조
```
database/
├── schema.sql              # 완전한 데이터베이스 스키마 (전체 한번에 실행)
├── migrations/
│   ├── 001_initial_schema.sql    # 초기 스키마 (단계별 실행용)
│   ├── 002_rls_policies.sql      # Row Level Security 정책
│   └── 003_seed_data.sql         # 테스트용 시드 데이터
└── README.md              # 이 파일
```

## 데이터베이스 설정 순서

### 1. Supabase 프로젝트 생성
1. [Supabase Dashboard](https://app.supabase.com)에서 새 프로젝트 생성
2. PostgreSQL 데이터베이스가 자동으로 생성됨
3. 프로젝트 설정에서 Database URL과 anon key 확인

### 2. 스키마 실행 (옵션 A: 전체 한번에)
```sql
-- Supabase SQL Editor에서 schema.sql 내용 전체 실행
-- 또는 psql 명령어 사용:
-- psql -h <호스트> -p <포트> -U postgres -d postgres -f schema.sql
```

### 2. 스키마 실행 (옵션 B: 단계별)
```sql
-- 1단계: 기본 스키마
\i migrations/001_initial_schema.sql

-- 2단계: RLS 정책  
\i migrations/002_rls_policies.sql

-- 3단계: 시드 데이터 (선택사항)
\i migrations/003_seed_data.sql
```

### 3. Supabase Storage 설정
```sql
-- 파일 업로드용 Storage Bucket 생성
INSERT INTO storage.buckets (id, name, public) 
VALUES ('project-files', 'project-files', false);

-- Storage RLS 정책
CREATE POLICY "Users can upload files" ON storage.objects
FOR INSERT WITH CHECK (
  bucket_id = 'project-files' AND
  auth.role() = 'authenticated'
);

CREATE POLICY "Users can view accessible files" ON storage.objects
FOR SELECT USING (
  bucket_id = 'project-files' AND
  (
    auth.uid()::text = (storage.foldername(name))[1] OR
    auth.is_admin()
  )
);
```

### 4. Authentication 설정
1. Supabase Dashboard → Authentication → Providers
2. Google OAuth 설정 (클라이언트 ID, 시크릿)
3. 이메일 확인 설정 (선택사항)

## 데이터베이스 구조

### 핵심 테이블
- **users**: 사용자 정보 (클라이언트, 디자이너, 관리자)
- **projects**: 프로젝트 정보
- **proposals**: 디자이너 제안서
- **feedback**: 피드백 및 수정 요청
- **project_files**: 프로젝트 관련 파일
- **payments**: 결제 정보
- **notifications**: 알림 시스템

### 관리자 테이블
- **disputes**: 분쟁 관리
- **user_sanctions**: 사용자 제재
- **admin_logs**: 관리자 활동 로그
- **announcements**: 공지사항

### 주요 Enum Types
- `user_role`: 'client', 'designer', 'admin'
- `project_status`: 프로젝트 진행 상태 (11가지)
- `project_type`: 프로젝트 분류 (10가지)
- `feedback_type`: 피드백 유형
- `payment_status`: 결제 상태

## RLS (Row Level Security) 정책
모든 테이블에 적절한 RLS 정책이 적용되어 있습니다:
- 사용자는 자신의 데이터만 접근 가능
- 프로젝트 참여자는 해당 프로젝트 데이터 접근 가능  
- 관리자는 모든 데이터 접근 가능
- 공개 데이터는 인증된 사용자 모두 접근 가능

## 테스트 데이터
`003_seed_data.sql`에는 다음 테스트 데이터가 포함되어 있습니다:
- 관리자 1명, 클라이언트 2명, 디자이너 2명
- 다양한 상태의 프로젝트 3개
- 제안서, 피드백, 알림 등

## 환경별 설정

### 개발 환경
```env
SUPABASE_URL=your_supabase_project_url
SUPABASE_ANON_KEY=your_anon_key  
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key
```

### 프로덕션 환경
- Database 백업 설정
- Connection pooling 설정
- Performance 모니터링 설정

## 마이그레이션 관리
향후 스키마 변경 시:
1. 새로운 마이그레이션 파일 생성 (`004_xxx.sql`)
2. 변경사항을 점진적으로 적용
3. 롤백 스크립트 준비
4. 프로덕션 적용 전 스테이징에서 테스트

## 문제해결

### 자주 발생하는 오류
1. **RLS 정책 오류**: 사용자 권한 확인
2. **Foreign Key 오류**: 관련 데이터 존재 여부 확인
3. **Auth 오류**: Supabase Auth 설정 확인

### 로그 확인
```sql
-- Supabase 로그 확인
SELECT * FROM auth.users ORDER BY created_at DESC LIMIT 10;
SELECT * FROM admin_logs ORDER BY created_at DESC LIMIT 20;
```

## 성능 최적화
- 모든 주요 쿼리에 인덱스 적용됨
- JOIN이 많은 쿼리는 성능 모니터링 필요
- 대용량 파일은 Supabase Storage 사용

## 백업 및 복구
```bash
# 백업
pg_dump -h <host> -U postgres -d postgres > backup.sql

# 복구  
psql -h <host> -U postgres -d postgres < backup.sql
```