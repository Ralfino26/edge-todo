import SwiftUI

struct TodoPanelView: View {
    @Bindable var store: TodoStore
    var isExpanded: Bool

    @State private var draft = ""
    @FocusState private var inputFocused: Bool

    var body: some View {
        panelBody
            .frame(width: EdgePanelController.expandedWidth)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
            .environment(\.colorScheme, .dark)
            .onChange(of: isExpanded) { _, expanded in
                if expanded {
                    focusInputSoon()
                } else {
                    inputFocused = false
                }
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
    }

    private var glassBackground: some View {
        RoundedRectangle(cornerRadius: 22, style: .continuous)
            .fill(Color(red: 0.09, green: 0.09, blue: 0.1).opacity(0.92))
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(.ultraThinMaterial)
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
                        ForEach(store.items) { item in
                            TodoRow(
                                item: item,
                                onToggle: {
                                    withAnimation(.easeOut(duration: 0.2)) {
                                        store.toggle(item.id)
                                    }
                                },
                                onDelete: {
                                    withAnimation(.spring(response: 0.36, dampingFraction: 0.86)) {
                                        store.remove(item.id)
                                    }
                                }
                            )
                            .transition(.todoRow)
                        }

                        if store.items.contains(where: \.isDone) {
                            Button {
                                withAnimation(.spring(response: 0.36, dampingFraction: 0.86)) {
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
                            .transition(.opacity)
                        }
                    }
                    .animation(.spring(response: 0.36, dampingFraction: 0.86), value: store.items)
                }
            }
        }
    }

    private func submitDraft() {
        let value = draft
        guard !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        withAnimation(.spring(response: 0.36, dampingFraction: 0.86)) {
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

private extension AnyTransition {
    static var todoRow: AnyTransition {
        .asymmetric(
            insertion: .opacity
                .combined(with: .offset(x: 18))
                .combined(with: .scale(scale: 0.98, anchor: .trailing)),
            removal: .opacity
                .combined(with: .offset(x: 64))
                .combined(with: .scale(scale: 0.92, anchor: .leading))
        )
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
