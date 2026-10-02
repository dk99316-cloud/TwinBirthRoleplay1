import Foundation
import FoundationModels

struct StoryLine: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var speaker: String
    var text: String
}

struct StoryTurn: Identifiable, Codable, Equatable {
    enum Kind: String, Codable { case user, story }
    var id: UUID = UUID()
    var kind: Kind
    var input: String = ""
    var narration: String = ""
    var lines: [StoryLine] = []
    var sources: [SearchSource] = []
    var createdAt: Date = .now
}

struct SearchSource: Identifiable, Codable, Equatable {
    var id: String { url }
    var title: String
    var url: String
    var snippet: String
}

@Generable
struct GeneratedStoryTurn {
    @Guide(description: "사용자 역할 캐릭터인 루시우스의 행동을 대신 쓰지 않고, 현재 상황의 짧은 장면 묘사")
    var narration: String

    @Guide(description: "현재 장면에서 실제로 말하는 인물들의 이름과 대사. 첫 탄생 장면에서는 파울로와 제니스가 각각 말한다.")
    var dialogue: [GeneratedDialogue]
}

@Generable
struct GeneratedDialogue {
    @Guide(description: "대사를 말하는 인물의 이름. 장면에 실제로 있는 인물만 선택한다.")
    var speaker: String

    @Guide(description: "그 인물의 짧고 상황에 맞는 한국어 대사")
    var text: String
}
