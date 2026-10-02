# 쌍둥이의 첫 삶 — 새 프로젝트

아이폰에서 Apple Intelligence 온디바이스 언어 모델로 진행하는 오프라인 우선 역할극 앱입니다.

## 새 버전 설계
- 루데우스와 루시우스의 첫 삶, 탄생 직후 장면에서 시작
- 두 아이에게 전생이나 이전 삶의 기억을 부여하지 않음
- 사용자가 루시우스의 행동과 대사를 맡고, AI는 다른 인물과 장면을 진행
- Apple Foundation Models의 구조화된 응답으로 장면 서술과 인물 대사를 분리
- 세로 화면과 좁은 폭에 맞춘 SwiftUI 레이아웃
- 대화는 기기 안에 저장
- 기본 답변은 기기 내 모델에서 생성하며, 인터넷 검색은 사용자가 검색 버튼을 눌렀을 때만 실행
- 검색 버튼은 최근 사용자 입력에서 검색어를 만들고 Google 검색 페이지를 엽니다. 대화 전체를 전송하지 않습니다.

## 요구 사항
- iOS 26 이상 및 Apple Intelligence 지원 기기
- Apple Intelligence 언어 모델 다운로드가 완료되어야 오프라인 답변 생성 가능
- 네트워크 검색은 검색 버튼을 눌렀을 때 인터넷 연결을 사용

## 빌드
Codemagic 앱에 GitHub webhook이 연결되어 있으면 `main`에 push할 때 자동 빌드됩니다. 수동으로도 `ios-development` 워크플로를 실행할 수 있습니다. 워크플로는 저장소의 `LuciusStoryAppleAI.xcodeproj`를 직접 빌드하고 unsigned IPA를 생성합니다. 기기에 설치하려면 Sideloadly 등으로 개인 Apple ID 서명을 해야 할 수 있습니다.
