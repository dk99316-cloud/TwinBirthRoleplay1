import Foundation

struct ChatMessage: Identifiable, Codable {
    enum Role: String, Codable {
        case user
        case assistant
    }

    var id: UUID
    var role: Role
    var text: String

    init(id: UUID = UUID(), role: Role, text: String) {
        self.id = id
        self.role = role
        self.text = text
    }
}
