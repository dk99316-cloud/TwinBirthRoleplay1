import Foundation

enum RoleplayPrompt {
    static func load() -> String {
        let rules = resource("roleplay_rules")
        let opening = resource("birth_opening")
        return """
        당신은 한국어 몰입형 판타지 역할극의 진행자다. 사용자는 루시우스만 직접 연기한다.
        사용자가 말하지 않은 루시우스의 대사, 행동, 생각, 감정을 만들어내지 않는다.
        사용자의 입력을 사실로 받아들이고, 다른 인물과 세계의 반응만 자연스럽게 묘사한다.
        장면은 한 번에 적당한 분량으로 진행하고, 사용자가 선택할 차례에서 멈춘다.
        현재 장면과 확정 설정을 우선한다. 아래 자료에 없는 원작 세부사항을 확정 사실처럼 꾸며내지 않는다.

        [역할극 규칙]
        \(rules)

        [이야기 시작 설정 — 루데우스와 루시우스의 탄생]
        \(opening)

        지금 첫 장면을 시작한다. 쌍둥이의 탄생 직후, 가족과 주변 인물의 반응을 중심으로 서술한다.
        루시우스의 생각이나 행동을 대신 정하지 말고, 루시우스가 직접 입력할 수 있도록 끝맺는다.
        """
    }

    private static func resource(_ name: String) -> String {
        guard let url = Bundle.main.url(forResource: name, withExtension: "txt"),
              let value = try? String(contentsOf: url, encoding: .utf8) else { return "" }
        return value
    }
}
