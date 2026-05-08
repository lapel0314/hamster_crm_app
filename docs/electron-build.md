# Electron 무설치 빌드

햄스터 CRM은 Flutter web 결과물을 Electron으로 감싸고 `electron-builder`로 무설치 패키지를 만든다.

## 데이터 파일

Electron 앱 데이터는 아래 JSON 파일에 저장된다.

- macOS: `~/Documents/GoldenHamsterCRM/hamster_crm_data.json`
- Windows: `%USERPROFILE%\\Documents\\GoldenHamsterCRM\\hamster_crm_data.json`

앱을 종료한 뒤 이 파일을 복사하면 맥/윈도우 간 데이터를 옮길 수 있다.

## Windows 무설치 빌드

```bash
npm install
npm run dist:win
```

결과물:

```text
output/electron/뵤펫 CRM 1.0.0.exe
```

## macOS 무설치 빌드

macOS 환경에서 실행해야 한다.

```bash
npm install
npm run dist:mac
```

결과물:

```text
output/electron/뵤펫 CRM-1.0.0-arm64-mac.zip
output/electron/뵤펫 CRM-1.0.0-mac.zip
```

`zip` 파일을 풀어서 바로 실행하는 무설치 방식이다.
