import Foundation
import FoundationModels
import Observation

@MainActor
@Observable
final class ChatStore {
    var messages: [ChatMessage] = []
    var draft = ""
    var isGenerating = false
    var status: String?

    private let storageKey = "twinBirthRoleplay.firstLife.messages.v2"

    init() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let saved = try? JSONDecoder().decode([ChatMessage].self, from: data),
           !saved.isEmpty {
            messages = saved
        }
    }

    var modelReady: Bool {
        SystemLanguageModel.default.availability == .available
    }

    func startStory() async {
        guard messages.isEmpty else { return }
        await generate(prompt: "이야기를 시작해 주세요.", includeAsUserMessage: false)
    }

    func send() async {
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isGenerating else { return }

        draft = ""
        messages.append(ChatMessage(role: .user, text: text))
        save()
        await generate(prompt: text, includeAsUserMessage: true)
    }

    func resetStory() {
        messages = []
        status = nil
        UserDefaults.standard.removeObject(forKey: storageKey)
    }

    private func generate(prompt: String, includeAsUserMessage: Bool) async {
        guard modelReady else {
            status = "이 iPhone에서 기기 내 언어 모델을 사용할 수 없어요. Apple Intelligence 지원 기기에서 모델 준비가 끝난 뒤 이용해 주세요."
            return
        }

        isGenerating = true
        status = nil
        defer { isGenerating = false }

        do {
            let session = LanguageModelSession(instructions: RoleplayPrompt.load())
            let history = messages.suffix(4).map { message in
                let speaker = message.role == .user ? "루시우스(사용자)" : "진행자"
                let shortenedText = String(message.text.suffix(300))
                return "\(speaker): \(shortenedText)"
            }.joined(separator: "\n")

            let request: String
            if includeAsUserMessage {
                request = """
                최근 대화의 마지막 시점 바로 다음부터 이어 쓴다. 같은 장면을 다시 시작하지 않는다.
                \(history)

                이 대화 다음에 일어나는 새로운 반응이나 사건 하나만 짧게 써 주세요. 루시우스의 행동, 대사, 생각은 대신 정하지 마세요.
                """
            } else {
                request = "첫 장면을 시작해 주세요. 쌍둥이가 태어난 직후 가족의 반응을 짧게 묘사하고, 루시우스가 반응할 차례에 멈추세요."
            }

            let options = GenerationOptions(maximumResponseTokens: 350)
            let response = try await session.respond(to: request, options: options)
            let cleanedResponse = removingRepeatedParagraphs(from: response.content)
            messages.append(ChatMessage(role: .assistant, text: cleanedResponse))
            save()
        } catch {
            status = "응답을 만들지 못했어요. 잠시 뒤 다시 시도해 주세요. (\(error.localizedDescription))"
        }
    }

    private func removingRepeatedParagraphs(from text: String) -> String {
        let normalizedText = text.replacingOccurrences(of: "\r\n", with: "\n")
        let paragraphs = normalizedText
            .components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        var seen = Set<String>()
        let uniqueParagraphs = paragraphs.filter { paragraph in
            let key = String(paragraph.filter { !$0.isWhitespace }).lowercased()
            return seen.insert(key).inserted
        }
        return uniqueParagraphs.joined(separator: "\n\n")
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(messages) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }
}
