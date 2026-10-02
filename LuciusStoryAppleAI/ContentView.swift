import SwiftUI

struct ContentView: View {
    @State private var store = ChatStore()
    @FocusState private var inputFocused: Bool
    @Environment(\.openURL) private var openURL

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if let status = store.status {
                    VStack(alignment: .leading, spacing: 8) {
                        Label(status, systemImage: "info.circle.fill")
                            .font(.footnote)
                            .foregroundStyle(.yellow)
                        if !store.modelIsAvailable || !store.turns.isEmpty {
                            Button {
                                openWebSearch(store.latestSearchQuery)
                            } label: {
                                Label("웹에서 설정 검색", systemImage: "magnifyingglass")
                                    .font(.subheadline.weight(.semibold))
                            }
                        }
                        Text("검색을 누르면 검색어만 Google에 전달됩니다.")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.yellow.opacity(0.1))
                }

                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 16) {
                            if store.turns.isEmpty {
                                welcomeCard
                            }

                            ForEach(store.turns) { turn in
                                turnView(turn)
                                    .id(turn.id)
                            }

                            if store.isGenerating {
                                HStack(spacing: 10) {
                                    ProgressView()
                                    Text("기기 안에서 이야기를 쓰고 있어요…")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                            }
                        }
                        .frame(maxWidth: 640, alignment: .leading)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                    }
                    .scrollDismissesKeyboard(.interactively)
                    .onChange(of: store.turns.count) {
                        guard let last = store.turns.last else { return }
                        withAnimation(.easeOut(duration: 0.2)) {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }

                composer
            }
            .background(Color(uiColor: .systemBackground))
            .navigationTitle("첫 번째 삶")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("처음부터") {
                        Task { await store.restart() }
                    }
                    .disabled(store.isGenerating)
                }
            }
            .task { await store.beginIfNeeded() }
        }
        .preferredColorScheme(.dark)
    }

    private var welcomeCard: some View {
        VStack(spacing: 14) {
            HStack(spacing: 12) {
                portrait("rudeus", label: "루데우스", size: 62)
                Image(systemName: "sparkle")
                    .foregroundStyle(.orange)
                portrait("lucius", label: "루시우스", size: 62)
            }

            Text("쌍둥이의 첫 번째 삶")
                .font(.title2.bold())
                .multilineTextAlignment(.center)

            Text("전생의 기억 없이, 두 아이가 태어난 순간부터 시작합니다. 루시우스의 선택은 당신이 직접 정해요.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Label("Apple Intelligence · 기기 내 생성", systemImage: "apple.intelligence")
                .font(.caption.weight(.medium))
                .foregroundStyle(.teal)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 22))
        .padding(.horizontal, 16)
    }

    @ViewBuilder
    private func turnView(_ turn: StoryTurn) -> some View {
        if turn.kind == .user {
            HStack {
                Spacer(minLength: 40)
                Text(turn.input)
                    .font(.body)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(13)
                    .foregroundStyle(.white)
                    .background(.blue.gradient, in: RoundedRectangle(cornerRadius: 18))
            }
            .padding(.horizontal, 16)
        } else {
            VStack(alignment: .leading, spacing: 12) {
                if !turn.narration.isEmpty {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "book.closed.fill")
                            .foregroundStyle(.orange)
                            .padding(.top, 3)
                        Text(turn.narration)
                            .font(.body)
                            .lineSpacing(4)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 18))
                }

                ForEach(turn.lines) { line in
                    dialogueCard(line)
                }

                Button {
                    openWebSearch(store.searchQuery(for: turn))
                } label: {
                    Label("응답이 어긋났나요? 웹 검색", systemImage: "magnifyingglass")
                        .font(.caption.weight(.medium))
                }
                .buttonStyle(.borderless)
                .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
        }
    }

    private func dialogueCard(_ line: StoryLine) -> some View {
        HStack(alignment: .top, spacing: 12) {
            characterPortrait(for: line.speaker)
            VStack(alignment: .leading, spacing: 5) {
                Text(line.speaker)
                    .font(.caption.bold())
                    .foregroundStyle(.teal)
                Text("“\(line.text)”")
                    .font(.body)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(uiColor: .tertiarySystemBackground), in: RoundedRectangle(cornerRadius: 18))
    }

    @ViewBuilder
    private func characterPortrait(for speaker: String) -> some View {
        let name = speaker.trimmingCharacters(in: .whitespacesAndNewlines)
        if name.contains("실피") {
            portrait("sylphie", label: name, size: 42)
        } else if name.contains("록시") {
            portrait("roxy", label: name, size: 42)
        } else if name.contains("에리스") {
            portrait("eris", label: name, size: 42)
        } else if name.contains("루데우스") {
            portrait("rudeus", label: name, size: 42)
        } else if name.contains("루시우스") {
            portrait("lucius", label: name, size: 42)
        } else {
            Image(systemName: name.contains("파울로") ? "figure.stand" : "person.crop.circle")
                .font(.title2)
                .foregroundStyle(.secondary)
                .frame(width: 42, height: 42)
                .background(.quaternary, in: Circle())
                .accessibilityLabel(name)
        }
    }

    private func portrait(_ asset: String, label: String, size: CGFloat) -> some View {
        Image(asset)
            .resizable()
            .scaledToFill()
            .frame(width: size, height: size)
            .clipShape(Circle())
            .overlay(Circle().stroke(.white.opacity(0.45), lineWidth: 1))
            .accessibilityLabel(label)
    }

    private var composer: some View {
        HStack(alignment: .bottom, spacing: 10) {
            TextField("루시우스의 말이나 행동을 입력하세요", text: $store.draft, axis: .vertical)
                .lineLimit(1...4)
                .textFieldStyle(.plain)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 20))
                .focused($inputFocused)
                .submitLabel(.send)
                .onSubmit { Task { await store.send() } }

            Button {
                inputFocused = false
                Task { await store.send() }
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 36))
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.white, .blue)
            }
            .disabled(store.draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || store.isGenerating)
            .accessibilityLabel("보내기")
        }
        .frame(maxWidth: 640)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.bar)
    }

    private func openWebSearch(_ query: String) {
        var components = URLComponents(string: "https://www.google.com/search")
        components?.queryItems = [URLQueryItem(name: "q", value: query)]
        if let url = components?.url { openURL(url) }
    }
}
