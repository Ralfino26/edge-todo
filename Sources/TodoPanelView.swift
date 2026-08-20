import SwiftUI

struct TodoPanelView: View {
    @Bindable var store: TodoStore
    var isExpanded: Bool

    @State private var draft = ""
    @State private var contentVisible = false
    @FocusState private var inputFocused: Bool

    var body: some View {
        panelBody
            .frame(width: EdgePanelController.expandedWidth)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
            .environment(\.colorScheme, .dark)
            .onChange(of: isExpanded) { _, expanded in
                withAnimation(.easeOut(duration: 0.28)) {
                    contentVisible = expanded
                }
                if expanded {
                    focusInputSoon()
                } else {
                    inputFocused = false
                }
            }
            .onAppear {
                contentVisible = isExpanded
            }
    }

    private var panelBody: some View {
        VStack(alignment: .leading, spacing: 0) {
            inputRow
            list
        }
        .padding(.horizontal, 14)
        .padding(.top, 14)
        .padding(.bottom, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(glassBackground)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(Color.white.opacity(0.08), lineWidth: 0.5)
        )
        .padding(10)
        .opacity(contentVisible ? 1 : 0)
        .offset(x: contentVisible ? 0 : 18)
    }

    private var glassBackground: some View {
        RoundedRectangle(cornerRadius: 22, style: .continuous)
            .fill(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color.black.opacity(0.38))
            )
    }

    private var inputRow: some View {
        HStack(spacing: 10) {
            TextField("", text: $draft, prompt: Text("New").foregroundStyle(.white.opacity(0.28)))
                .textFieldStyle(.plain)
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(.white.opacity(0.92))
                .focused($inputFocused)
                .onSubmit(submitDraft)

            if !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Button(action: submitDraft) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(.white.opacity(0.55))
                }
                .buttonStyle(.plain)
                .transition(.opacity.combined(with: .scale(scale: 0.85)))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.08), lineWidth: 0.5)
                )
        )
        .padding(.bottom, 10)
        .animation(.easeOut(duration: 0.18), value: draft.isEmpty)
    }

    private var list: some View {
        Group {
            if store.items.isEmpty {
                Color.clear
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(alignment: .leading, spacing: 2) {
                        ForEach(Array(store.items.enumerated()), id: \.element.id) { index, item in
                            TodoRow(
                                item: item,
                                onToggle: { store.toggle(item.id) },
                                onDelete: { store.remove(item.id) }
                            )
                            .transition(
                                .asymmetric(
                                    insertion: .opacity.combined(with: .move(edge: .trailing)),
                                    removal: .opacity.combined(with: .scale(scale: 0.96))
                                )
                            )
                            .animation(
                                .easeOut(duration: 0.28).delay(Double(min(index, 6)) * 0.03),
                                value: contentVisible
                            )
                        }

                        if store.items.contains(where: \.isDone) {
                            Button {
                                withAnimation(.easeOut(duration: 0.22)) {
                                    store.clearDone()
                                }
                            } label: {
                                Text("Clear")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(.white.opacity(0.28))
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                                    .padding(.top, 10)
                                    .padding(.trailing, 4)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    private func submitDraft() {
        let value = draft
        guard !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        withAnimation(.easeOut(duration: 0.22)) {
            store.add(value)
        }
        draft = ""
        inputFocused = true
    }

    private func focusInputSoon() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) {
            inputFocused = true
        }
    }
}

private struct TodoRow: View {
    let item: TodoItem
    let onToggle: () -> Void
    let onDelete: () -> Void

    @State private var hovering = false

    var body: some View {
        HStack(spacing: 10) {
            Button(action: onToggle) {
                Image(systemName: item.isDone ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(
                        item.isDone
                            ? Color.white.opacity(0.28)
                            : Color.white.opacity(hovering ? 0.55 : 0.35)
                    )
            }
            .buttonStyle(.plain)

            Text(item.title)
                .font(.system(size: 13.5, weight: .regular))
                .strikethrough(item.isDone, color: .white.opacity(0.2))
                .foregroundStyle(item.isDone ? Color.white.opacity(0.28) : Color.white.opacity(0.88))
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button(action: onDelete) {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.35))
                    .frame(width: 18, height: 18)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .opacity(hovering ? 1 : 0)
            .allowsHitTesting(hovering)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(hovering ? Color.white.opacity(0.05) : Color.clear)
        )
        .contentShape(Rectangle())
        .onHover { hovering = $0 }
        .animation(.easeOut(duration: 0.15), value: hovering)
    }
}
