# Hamster CRM 개발 계획

## 확정 조건
- 기존 `crm_app`과 별개인 신규 프로그램.
- 서버 없음.
- 로컬 오프라인 Windows 데스크톱 앱.
- 로그인 없음.
- 개인 PC 1인 사용.
- 설치파일: Inno Setup.
- 디자인 우선: 골든햄스터 컨셉.

## 권장 기술 스택

### 앱
- Flutter Windows 권장.
- 이유:
  - Windows 데스크톱 앱 제작 가능.
  - UI 커스터마이징이 쉬움.
  - SQLite/차트/파일 백업 연동이 안정적.
  - Inno Setup으로 설치파일 제작 가능.

### 로컬 DB
- SQLite.
- Flutter 패키지 후보:
  - `sqflite_common_ffi`
  - `sqlite3_flutter_libs`
  - `path_provider`
  - `path`
  - `intl`

### 차트
- `fl_chart` 후보.
- 월별 분양/구매 추이 막대 그래프 구현.

### 설치파일
- Inno Setup.
- 앱 실행파일과 Flutter Windows release 파일 포함.
- 사용자 데이터 폴더 `%APPDATA%\GoldenHamsterCRM`은 설치/삭제와 분리.

## 데이터 저장 위치

DB 파일:
- `%APPDATA%\GoldenHamsterCRM\hamster_crm.db`

백업 폴더:
- `%APPDATA%\GoldenHamsterCRM\backups\`

앱 설치 폴더:
- `C:\Program Files\Golden Hamster CRM\` 또는 사용자 선택 경로

## 데이터 모델

### customers
실제 고객DB 테이블.

필드:
- `id` INTEGER PRIMARY KEY AUTOINCREMENT
- `date` TEXT NOT NULL — 날짜, `YYYY-MM-DD`
- `customer_name` TEXT NOT NULL
- `gender` TEXT
- `phone` TEXT
- `adoption` TEXT — 분양 항목
- `purchase` TEXT — 구매 항목
- `revenue` INTEGER DEFAULT 0 — 매출
- `cost` INTEGER DEFAULT 0 — 원가
- `memo` TEXT
- `created_at` TEXT NOT NULL
- `updated_at` TEXT NOT NULL
- `deleted_at` TEXT NULL — 소프트 삭제

### prospects
가망고객 테이블.

필드:
- `id` INTEGER PRIMARY KEY AUTOINCREMENT
- `consultation_date` TEXT NOT NULL — 상담날짜
- `visit_date` TEXT — 방문예정날짜
- `customer_name` TEXT NOT NULL
- `gender` TEXT
- `phone` TEXT
- `adoption` TEXT
- `purchase` TEXT
- `revenue` INTEGER DEFAULT 0
- `cost` INTEGER DEFAULT 0
- `memo` TEXT
- `created_at` TEXT NOT NULL
- `updated_at` TEXT NOT NULL
- `deleted_at` TEXT NULL

### app_settings
앱 설정 테이블.

필드:
- `key` TEXT PRIMARY KEY
- `value` TEXT

용도:
- 마지막 자동 백업 날짜
- 표시 설정
- 휴대폰번호 마스킹 여부 등

## SQL 스키마 초안

```sql
CREATE TABLE IF NOT EXISTS customers (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  date TEXT NOT NULL,
  customer_name TEXT NOT NULL,
  gender TEXT,
  phone TEXT,
  adoption TEXT,
  purchase TEXT,
  revenue INTEGER NOT NULL DEFAULT 0,
  cost INTEGER NOT NULL DEFAULT 0,
  memo TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  deleted_at TEXT
);

CREATE INDEX IF NOT EXISTS idx_customers_date ON customers(date);
CREATE INDEX IF NOT EXISTS idx_customers_name ON customers(customer_name);
CREATE INDEX IF NOT EXISTS idx_customers_phone ON customers(phone);

CREATE TABLE IF NOT EXISTS prospects (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  consultation_date TEXT NOT NULL,
  visit_date TEXT,
  customer_name TEXT NOT NULL,
  gender TEXT,
  phone TEXT,
  adoption TEXT,
  purchase TEXT,
  revenue INTEGER NOT NULL DEFAULT 0,
  cost INTEGER NOT NULL DEFAULT 0,
  memo TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  deleted_at TEXT
);

CREATE INDEX IF NOT EXISTS idx_prospects_consultation_date ON prospects(consultation_date);
CREATE INDEX IF NOT EXISTS idx_prospects_visit_date ON prospects(visit_date);
CREATE INDEX IF NOT EXISTS idx_prospects_name ON prospects(customer_name);
CREATE INDEX IF NOT EXISTS idx_prospects_phone ON prospects(phone);

CREATE TABLE IF NOT EXISTS app_settings (
  key TEXT PRIMARY KEY,
  value TEXT
);
```

## 화면 구조

### 공통 레이아웃
- 좌측 사이드바:
  - 대시보드
  - 고객등록
  - 고객DB
  - 가망고객
- 우측 콘텐츠 영역.
- 디자인 시스템: `hamster_crm/design-system.md` 기준.

### 고객등록
기능:
- 신규 고객 입력.
- 날짜 기본값 오늘.
- 매출/원가 숫자 입력.
- 저장 후 고객DB에 반영.
- 저장 성공 메시지.

검증:
- 고객명 필수.
- 날짜 필수.
- 매출/원가는 빈 값이면 0.

### 고객DB
기능:
- 고객 목록 표.
- 날짜 달력 필터.
- 검색: 고객명, 휴대폰번호, 분양, 구매, 메모 대상.
- 상세 보기/수정/삭제.
- 삭제는 확인 팝업 후 `deleted_at` 처리.

### 가망고객
기능:
- 가망고객 목록/등록/수정/삭제.
- 상담날짜 필터.
- 방문예정날짜 필터.
- 검색.
- 추후 “고객DB로 전환” 버튼 추가 가능.

### 대시보드
기능:
- 월별 분양 추이: `customers.adoption` 기준 집계.
- 월별 구매 추이: `customers.purchase` 기준 집계.
- 정산현황: 월별 총 매출/총 원가/순이익.
- 이번달 분양 순위: adoption 텍스트 그룹 count.
- 이번달 구매 순위: purchase 텍스트 그룹 count.

## 폴더 구조 후보

```text
hamster_crm_app/
  lib/
    main.dart
    app.dart
    core/
      theme/
      database/
      backup/
      utils/
    data/
      models/
      repositories/
    features/
      dashboard/
      customer_registration/
      customer_db/
      prospects/
    shared/
      widgets/
  assets/
    images/
      golden_hamster_mascot.png
  windows/
  installer/
    GoldenHamsterCRM.iss
```

## 개발 순서

### 1단계: 프로젝트 생성
- Flutter Windows 프로젝트 생성.
- 앱 이름: Golden Hamster CRM.
- 마스코트 이미지 asset 등록.

### 2단계: 디자인 시스템 적용
- 색상/폰트/버튼/카드/입력창 공통 위젯 제작.
- 좌측 사이드바와 라우팅 구현.

### 3단계: SQLite 연결
- DB 초기화.
- customers/prospects/app_settings 생성.
- repository 계층 작성.

### 4단계: 고객등록
- 입력 폼 구현.
- 저장 기능 구현.
- 고객명/날짜 필수 검증.

### 5단계: 고객DB
- 목록 표.
- 날짜 필터.
- 검색.
- 수정/삭제.

### 6단계: 가망고객
- 목록/등록/수정/삭제.
- 상담날짜/방문예정날짜 필터.
- 검색.

### 7단계: 대시보드
- 월별 분양/구매 집계.
- 정산현황.
- 이번달 순위.

### 8단계: 백업/복원
- 앱 실행 시 하루 1회 자동 백업.
- 수동 백업/복원 버튼.

### 9단계: Inno 설치파일
- Windows release build 후 Inno Setup 스크립트 작성.
- 업데이트 시 `%APPDATA%\GoldenHamsterCRM` 보존.

## 주의사항
- 서버/로그인/권한 기능 추가하지 않는다.
- 기존 `crm_app`은 수정하지 않는다.
- 디자인 방향을 유지한다.
- 빌드/설치파일 제작은 랭가 승인 후 진행한다.
