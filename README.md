# 🌿 잎로그(LeafLog)

> ****반려식물의 성장과 관리 기록을 돕는 iOS 식물 다이어리 애플리케이션****

<img width="1920" height="1080" alt="브로슈어 표지" src="https://github.com/user-attachments/assets/67cd794d-4c82-4f9c-8c7d-749ecf2f25a0" />

잎로그는 사용자가 키우는 식물을 등록하고, 물주기와 관리 기록을 날짜별로 남길 수 있는 앱입니다.

식물 검색, AI 식물 식별, 캘린더 기록, 다이어리, 푸시 알림 기능을 통해 반려식물을 꾸준히 관리할 수 있습니다.

<br>

# 📅 프로젝트 기간

2026.03.31. ~ (2026.05.07.)

<br>

# 👥 팀 소개

**Team Jooslin**

| 이름 | 담당 기능 |
|---|---|
| 변예린 | RxFlow 초기 세팅, 알림, 홈 화면, 캘린더 화면, AI 식물 식별 |
| 김주희 | Supabase 설정, 스플래시 화면, 소셜 로그인 및 회원탈퇴, 마이페이지, 식물 상세 - 기록탭 / 타임라인 탭 |
| 장예슬 | API 검색, 공용 UI, 식물 검색, 식물 등록, 식물 상세 - 정보탭 |
| 김아정 | UX/UI 디자인, 로고 및 아이콘 제작 |

<br>

# 📂 프로젝트 폴더 구조

프로젝트는 ****ReactorKit 기반 구조에 맞게 역할별로 디렉토리를 분리****하여 관리했습니다.

```text

LeafLog
│
├── App
│ ├── Flows
│ ├── Notification
│ ├── AppConfig
│ └── SupabaseManager
│
├── Auth
│
├── Model
│
├── Network
│
├── Reactor
│
├── Service
│
├── Util
│
└── View

```

<br>

# 🧰 기술 스택

| 분류 | 라이브러리 |
|---|---|
| Language | Swift |
| Architecture | ReactorKit, RxFlow, RxSwift |
| UI | UIKit, SnapKit, Then |
| Database | Supabase |
| Network | Alamofire, XMLCoder, Kingfisher |
| Auth | Apple Login, Google Sing-In, Kakao Login |
| AI | TensorFlowLiteSwift |
| Notifications | Firebase Messaging |

<br>

# 🏗 아키텍처

### ReactorKit 채택 이유

- Massive ViewController 이슈 방지
- UI / 비즈니스 로직 분리 - 병렬 개발 용이
- 단방향 코드 흐름으로 인해 비교적 낮은 버그 발생 가능성
- 상태 관리의 용이성

### RxFlow 채택 이유

- 화면 전환 로직을 ViewController에서 분리 → 책임 경량화
- 화면 흐름을 한 곳에서 쉽게 파악 가능

### Swift Dependency 채택 이유

- 주입 객체를 상수로 선언하지 않아 사이드 이펙트를 줄일 수 있음
- preview에서 실제로 동작하기 힘든 부분을 mock up 데이터를 사용한 객체로 임시 실행 가능

<br>

# 📋 의사 결정 기록


# ⭐ 핵심 기능

## 🔐 소셜 로그인

<p align=center><img width=50% src="https://github.com/user-attachments/assets/8ce19120-3fa2-45f0-b838-004c85152544" /></p>


LeafLog는 Supabase를 통한 Google, Kakao 소셜 로그인과 on-device 라이브러리를 통한 Apple 로그인을 지원합니다.

로그인 성공 시 메인 화면으로 이동하며, 실패 시 알림창을 통해 오류 메시지를 안내합니다.

하단에는 이용약관과 개인정보처리방침 링크를 제공하며, 선택 시 SFSafariViewController를 통해 해당 문서로 이동합니다.

로그인 성공 후 FCM 토큰을 저장하여 Supabase에 저장된 토큰과 동기화합니다.


## 🏠 홈 화면

<p align=center><img width=50% src="https://github.com/user-attachments/assets/54ed3d33-731f-4b95-a107-18d53e6e6379" /></p>

사용자가 등록한 식물을 한눈에 확인할 수 있는 메인화면입니다.

'물주기 버튼'으로 빠르게 급수 기록을 저장할 수 있어 사용자의 관리 흐름을 간단하게 하였습니다.

UICollectionView로 구현되었으며, 선반 모양을 구현하기 위해 snapshot에 사용되는 dataSource는 3의 배수로 생성됩니다.


## 🔍 식물 등록 및 검색

<p align=center><img width=70% src="https://github.com/user-attachments/assets/6dd5802f-d351-47e9-8c9b-55f6bc835840" /></p>

검색어와 필터링을 통해 원하는 식물을 검색하고 기본 정보를 불러올 수 있습니다.

식물 이름, 상세 정보, 이미지 정보를 조회에는 **농사로 API**를 활용하였습니다.

검색어 외에 on-Device AI를 활용한 카메라 검색 기능을 통해 이미지로도 식물을 식별할 수 있습니다.

검색 결과에서 식물을 선택하여 해당 정보를 가지고 식물 등록 화면에서 '내 식물'로 저장할 수 있습니다.


## 📆 캘린더 화면

<p align=center><img width=60% src="https://github.com/user-attachments/assets/1f351bfd-89ec-4e45-b2b7-35e0cfde69b0" /></p>

캘린더 화면에서는 날짜별 식물 관리 기록을 월 단위로 확인할 수 있습니다.

각 관리 항목에 따른 필터링 기능을 제공하여 원하는 기록만 골라 볼 수 있습니다.

특정 날짜를 선택하면 해당 날짜에 기록된 상세 관리 내역을 확인하고, 해당 식물 기록으로 이동할 수 있습니다.


## 📝 식물 관리 화면

식물 관리 화면에서는 날짜별로 관리 기록을 남기거나 식물 정보, 식물 기록을 조회할 수 있습니다.

UISegmentControl로 구현된 탭 Component를 통해 사용자가 손쉽게 필요한 카테고리로 전환할 수 있습니다.

### 관리 기록 기능

<p align=center><img width=60% src="https://github.com/user-attachments/assets/513d2c9f-0b6f-4aff-9f6a-110a60aecd63" /></p>


물주기, 분갈이, 비료, 치료 기록과 '오늘의 일기' 기록을 날짜별로 저장할 수 있습니다.

### 식물 정보, 타임라인 기능

<p align=center><img width=60% src="https://github.com/user-attachments/assets/41764d1b-c99d-4cc0-8520-97058b2780b6" /></p>

식물 정보 탭에서는 등록한 식물의 기본 정보와 관리 가이드를 확인할 수 있습니다.

타임라인 탭에서는 지금까지 저장한 관리 기록을 시간 순서대로 확인할 수 있습니다.


## 👤 마이페이지

<p align=center><img width=50% src="https://github.com/user-attachments/assets/34ca2fcf-05dd-4c50-a871-637f8fd74bd8" /></p>

마이페이지에서는 사용자 프로필과 알림 설정, 사용자 계정(로그아웃 및 회원 탈퇴) 관리를 할 수 있습니다.

토글을 통해 푸시 알림 설정을 변경할 수 있으며, 문의하기 등 앱 지원에 관한 사항과 앱 버전 확인 기능을 제공합니다.

<br>

## 🔔 알림 센터 화면

<p align=center><img width=70% src="https://github.com/user-attachments/assets/32381034-0c11-42c6-b143-18ed8d4d3996" /></p>

알림 센터에서는 식물 관리와 관련된 알림 기록을 확인할 수 있습니다.

사용자는 FCM 기반 푸시 알림을 통해 급수가 필요한 식물에 대해 관리 시점을 놓치지 않고 확인할 수 있습니다.


# 🛠 Troubleshooting

<br>

# 🚀 향후 개선 사항

- 커뮤니티 기능
- 온보딩 화면
- 식물 검색 결과 다양화
- AI 식별 모델 정확도 개선
