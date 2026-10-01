import Foundation

struct ChatMessage: Identifiable, Codable {
    enum Role: String, Codable { case user, assistant }
    var id: UUID
    var role: Role
    var text: String
    var date: Date

    init(role: Role, text: String, date: Date = .now) {
        self.id = UUID()
        self.role = role
        self.text = text
        self.date = date
    }
}
