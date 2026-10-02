# 루시우스의 이야기 — 오프라인 iPhone 역할극

새로 받은 SwiftUI 화면과 캐릭터 이미지, 기존 TwinBirthRoleplay 저장소의 ChatStore에서 사용한 문맥 제한·반복 문단 정리 방식을 합친 iOS 프로젝트입니다.

## 기능
- Apple Foundation Models 기기 내 생성
- 인터넷 검색 코드 없음: 설정 검색은 앱 번들 안에 든 텍스트 파일만 읽음
- 루데우스와 루시우스의 첫 삶, 쌍둥이 탄생 직후 자동 시작
- 둘은 전생이나 이전 삶의 기억이 없으며 신생아로 행동
- 사용자가 루시우스만 연기, AI는 다른 인물과 세계 반응을 작성
- 캐릭터 이미지, 최근 대화, 장기 기억 저장
- 같은 문단 반복 제거 및 문맥 길이 제한
- 처음부터 다시 시작 메뉴

## 빌드
Codemagic 저장소 루트에 `LuciusStoryAppleAI_source.zip`과 `codemagic.yaml`을 둡니다. `Lucius Story - iOS IPA Build` 워크플로가 unsigned `LuciusStoryAppleAI.ipa`를 만듭니다. Sideloadly 설치 시 개인 Apple ID 서명이 필요할 수 있습니다.

## 기기 요구 사항
Xcode 26 이상으로 빌드하며, Apple Foundation Models를 쓸 수 있는 iOS 기기와 다운로드된 온디바이스 모델이 필요합니다. iPhone 15 Pro Max에서 한국어 생성과 오프라인 동작은 실제 기기에서 확인해야 합니다.

앱은 대화 생성 과정에서 URLSession, 웹 검색, 외부 AI 서버를 사용하지 않습니다. 빌드 과정은 Codemagic 인터넷 연결을 사용합니다.
