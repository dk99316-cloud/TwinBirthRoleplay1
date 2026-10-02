import Foundation
import FoundationModels
import SwiftUI
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
            // 기기 내 모델 용량에 맞게 최근 대화 기억 개수를 18개에서 4개로 조정 (핵심 해결책)
            let history = messages.suffix(4).map { message in
                let speaker = message.role == .user ? "루시우스" : "진행자"
                return "\(speaker): \(message.text)"
            }.joined(separator: "\n")
            
            let request = includeAsUserMessage
                ? "상황:\n\(history)\n\n다음 반응을 이어 써 주세요. 루시우스의 행동은 정하지 마세요."
                : "이야기를 시작해 주세요."
                
            let response = try await session.respond(to: request)
            messages.append(ChatMessage(role: .assistant, text: response.content))
            save()
        } catch {
            status = "응답을 만들지 못했어요. 잠시 뒤 다시 시도해 주세요. (\(error.localizedDescription))"
        }
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(messages) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }
}
