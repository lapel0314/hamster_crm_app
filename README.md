# 뵤펫 CRM

로컬 오프라인 전용 Flutter Windows CRM입니다. 기존 `crm_app`과 분리된 신규 프로젝트입니다.

## MVP 포함 기능

- 대시보드: 고객 수, 가망고객 수, 이번달 매출/순이익, 월별 정산현황, 분양/구매 순위
- 고객등록: 날짜, 고객명, 성별, 휴대폰번호, 분양, 구매, 매출, 원가, 메모 저장
- 고객DB: 검색 가능한 고객 목록
- 가망고객: 상담날짜/방문예정날짜 기반 간단 등록 및 목록
- 로컬 SQLite 저장소 (`sqflite_common_ffi`)

## 개발 실행

```powershell
flutter pub get
flutter run -d windows
```

## 검증

```powershell
flutter test
flutter analyze
```

## 데이터 방향

운영 DB 경로는 앱 지원 폴더 아래 `GoldenHamsterCRM/hamster_crm.db`를 사용합니다. 설치 경로와 데이터 경로는 분리합니다.
