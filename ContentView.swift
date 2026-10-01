import SwiftUI

struct ContentView: View {
    @State private var store = ChatStore()
    @FocusState private var inputFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if !store.modelReady {
                    Label("오프라인 AI 모델을 사용할 수 없는 기기입니다.", systemImage: "exclamationmark.triangle")
                        .font(.footnote)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background(.yellow.opacity(0.18))
                }

                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            if store.messages.isEmpty {
                                openingCard
                            }
                            ForEach(store.messages) { message in
                                MessageBubble(message: message)
                                    .id(message.id)
                            }
                            if store.isGenerating {
                                HStack { ProgressView(); Text("이야기를 이어가는 중…").foregroundStyle(.secondary) }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal)
                            }
                            if let status = store.status {
                                Text(status).font(.footnote).foregroundStyle(.secondary).padding()
                            }
                        }
                        .padding(.vertical)
                    }
                    .onChange(of: store.messages.count) {
                        if let last = store.messages.last { withAnimation { proxy.scrollTo(last.id, anchor: .bottom) } }
                    }
                }

                HStack(alignment: .bottom, spacing: 8) {
                    TextField("루시우스의 말이나 행동을 입력하세요", text: $store.draft, axis: .vertical)
                        .lineLimit(1...5)
                        .textFieldStyle(.roundedBorder)
                        .focused($inputFocused)
                    Button {
                        Task { await store.send() }
                    } label: {
                        Image(systemName: "arrow.up.circle.fill").font(.system(size: 32))
                    }
                    .disabled(store.draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || store.isGenerating)
                }
                .padding()
                .background(.bar)
            }
            .navigationTitle("쌍둥이의 첫 번째 삶")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("처음부터") {
                        store.resetStory()
                        Task { await store.startStory() }
                    }
                }
            }
            .task { await store.startStory() }
        }
    }

    private var openingCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("이야기 시작").font(.headline)
            Text("루데우스와 루시우스의 첫 번째 삶입니다. 두 아이에게 전생의 기억은 없습니다. 탄생 장면부터 이야기를 시작합니다.")
                .font(.subheadline).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }
}

private struct MessageBubble: View {
    let message: ChatMessage
    private var isUser: Bool { message.role == .user }

    var body: some View {
        HStack {
            if isUser { Spacer(minLength: 36) }
            Text(message.text)
                .padding(12)
                .foregroundStyle(isUser ? .white : .primary)
                .background(isUser ? Color.accentColor : Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
            if !isUser { Spacer(minLength: 36) }
        }
        .padding(.horizontal)
    }
}



