import Foundation
import FoundationModels
import Observation

@MainActor
@Observable
final class ChatStore {
    private(set) var turns: [StoryTurn] = []
    var draft = ""
    private(set) var isGenerating = false
    private(set) var status: String?
    private(set) var modelIsAvailable = false

    private let saveKey = "LuciusFreshStart.turns.v1"
    private let model = SystemLanguageModel.default

    var latestSearchQuery: String { query(for: turns) }

    func searchQuery(for turn: StoryTurn) -> String {
        guard let index = turns.firstIndex(where: { $0.id == turn.id }) else {
            return latestSearchQuery
        }
        return query(for: Array(turns.prefix(index + 1)))
    }

    private func query(for history: [StoryTurn]) -> String {
        let userText = history.last(where: { $0.kind == .user })?.input
        let query = (userText ?? "쌍둥이 탄생 역할극 설정").trimmingCharacters(in: .whitespacesAndNewlines)
        return "무직전생 \(String(query.prefix(120)))"
    }

    init() {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let saved = try? JSONDecoder().decode([StoryTurn].self, from: data) {
            turns = saved
        }
        refreshAvailability()
    }

    func refreshAvailability() {
        if case .available = model.availability,
           model.supportsLocale(Locale(identifier: "ko-KR")) {
            modelIsAvailable = true
            status = nil
        } else {
            modelIsAvailable = false
            status = "기기 내 한국어 모델을 사용할 수 없어요. Apple Intelligence와 한국어 모델이 준비된 기기인지 확인해 주세요."
        }
    }

    func beginIfNeeded() async {
        guard turns.isEmpty, !isGenerating else { return }
        await generate(userInput: nil)
    }

    func send() async {
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isGenerating else { return }
        draft = ""
        turns.append(StoryTurn(kind: .user, input: text))
        save()
        await generate(userInput: text)
    }

    func restart() async {
        guard !isGenerating else { return }
        turns = []
        status = nil
        UserDefaults.standard.removeObject(forKey: saveKey)
        await generate(userInput: nil)
    }

    private func generate(userInput: String?) async {
        guard modelIsAvailable else { refreshAvailability(); return }
        isGenerating = true
        status = nil
        defer { isGenerating = false }

        let history = turns.suffix(12).map { turn -> String in
            switch turn.kind {
            case .user:
                return "사용자(루시우스): \(String(turn.input.suffix(240)))"
            case .story:
                let dialogue = turn.lines.map { "\($0.speaker): \($0.text)" }.joined(separator: " / ")
                return "장면: \(String(turn.narration.suffix(380))) 대사: \(String(dialogue.suffix(420)))"
            }
        }.joined(separator: "\n")

        let rules = """
        너는 한국어 오프라인 판타지 역할극의 진행자다. 사용자는 루시우스만 연기한다. 루시우스의 행동, 대사, 생각, 감정을 지어내지 않는다.
        이야기는 루데우스와 루시우스의 진짜 첫 번째 삶, 두 아이가 막 태어난 순간부터 시작한다. 둘 다 전생이나 이전 삶의 기억이 없다. 신생아는 말하거나 걷거나 의식적으로 행동하지 않는다. 탄생 직후 장면에는 부모 파울로와 제니스가 함께 있고, 첫 응답에서 두 사람 모두 짧게 한 번씩 말한다.
        실피, 록시, 에리스 등 아직 장면에 없는 인물을 탄생 장면에 불러오지 않는다. 이후에도 현재 장면에 있는 인물만 말하게 한다. 설정이나 대화 기록을 복사하지 말고, 입력 직후에 이어지는 새 반응만 1~3문장으로 쓴다. 루시우스가 반응할 수 있게 끝낸다.
        출력은 지정된 구조를 사용한다. narration에는 장면 묘사만 둔다. dialogue 배열에는 실제 인물별 대사를 각각 별도 항목으로 둔다. 대사를 narration에 섞지 않는다.
        """

        let prompt: String
        if let userInput {
            prompt = """
            지금까지의 이야기 기록:
            \(history)

            최신 사용자 입력(루시우스의 입력):
            \(userInput)

            이 입력에 직접 반응하는 새 장면만 만들고 루시우스의 다음 행동은 사용자에게 맡긴다. 관련 있는 NPC가 있으면 각자 대사를 구조화해 포함한다.
            """
        } else {
            prompt = """
            첫 장면을 만든다. 루데우스와 루시우스가 태어난 직후이며 파울로와 제니스가 곁에 있다. 두 부모가 놀람과 안도 속에서 각자 짧게 한마디씩 한다. 두 신생아에게 의식이나 전생 기억을 부여하지 말고, 루시우스가 반응하기 전에 멈춘다.
            """
        }

        do {
            let session = LanguageModelSession(instructions: rules)
            let response = try await session.respond(
                to: prompt,
                generating: GeneratedStoryTurn.self,
                options: GenerationOptions(maximumResponseTokens: 260)
            )
            let generated = response.content
            let dialogue = generated.dialogue
                .map { StoryLine(speaker: $0.speaker.trimmingCharacters(in: .whitespacesAndNewlines), text: $0.text.trimmingCharacters(in: .whitespacesAndNewlines)) }
                .filter { !$0.speaker.isEmpty && !$0.text.isEmpty }
            let story = StoryTurn(kind: .story, narration: generated.narration.trimmingCharacters(in: .whitespacesAndNewlines), lines: dialogue)
            guard !story.narration.isEmpty || !story.lines.isEmpty else {
                status = "응답이 비어 있어요. 다시 시도해 주세요."
                return
            }
            turns.append(story)
            save()
        } catch {
            status = "이야기를 만들지 못했어요. 모델 상태를 확인한 뒤 다시 시도해 주세요. (\(error.localizedDescription))"
        }
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(turns) else { return }
        UserDefaults.standard.set(data, forKey: saveKey)
    }
}
