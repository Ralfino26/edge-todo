import SwiftUI

struct TodoPanelView: View {
    @Bindable var store: TodoStore
    var isExpanded: Bool

    @State private var draft = ""
    @FocusState private var inputFocused: Bool

    var body: some View {
        // Full drawer content, trailing-aligned. Collapsed window is an invisible
        // 4pt edge zone — hovering the right screen edge slides this open.
        panelBody
            .frame(width: EdgePanelController.expandedWidth)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
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
            header
            Divider().opacity(0.35)
            inputRow
            Divider().opacity(0.25)
            list
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.18), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.28), radius: 18, x: -4, y: 6)
        )
        .padding(.vertical, 10)
        .padding(.horizontal, 8)
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Edge Todo")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                Text(openCountLabel)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if store.items.contains(where: \.isDone) {
                Button("Clear done") {
                    store.clearDone()
                }
                .buttonStyle(.plain)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
            }
        }
        .padding(.bottom, 10)
    }

    private var inputRow: some View {
        HStack(spacing: 8) {
            TextField("Add a todo…", text: $draft)
                .textFieldStyle(.plain)
                .font(.system(size: 13, design: .rounded))
                .focused($inputFocused)
                .onSubmit(submitDraft)

            Button(action: submitDraft) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 18))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 9)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.primary.opacity(0.06))
        )
        .padding(.vertical, 10)
    }

    private var list: some View {
        Group {
            if store.items.isEmpty {
                VStack(spacing: 8) {
                    Spacer(minLength: 24)
                    Image(systemName: "checklist")
                        .font(.system(size: 28, weight: .light))
                        .foregroundStyle(.tertiary)
                    Text("Type a todo and press Enter")
                        .font(.system(size: 12, design: .rounded))
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 4) {
                        ForEach(store.items) { item in
                            TodoRow(
                                item: item,
                                onToggle: { store.toggle(item.id) },
                                onDelete: { store.remove(item.id) }
                            )
                        }
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 4)
                }
            }
        }
    }

    private var openCountLabel: String {
        let open = store.items.filter { !$0.isDone }.count
        return open == 1 ? "1 open" : "\(open) open"
    }

    private func submitDraft() {
        store.add(draft)
        draft = ""
        inputFocused = true
    }

    private func focusInputSoon() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            inputFocused = true
        }
    }
}

private struct TodoRow: View {
    let item: TodoItem
    let onToggle: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Button(action: onToggle) {
                Image(systemName: item.isDone ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 16))
                    .foregroundStyle(item.isDone ? Color.primary.opacity(0.55) : Color.secondary.opacity(0.7))
            }
            .buttonStyle(.plain)

            Text(item.title)
                .font(.system(size: 13, design: .rounded))
                .strikethrough(item.isDone, color: .secondary)
                .foregroundStyle(item.isDone ? .secondary : .primary)
                .lineLimit(3)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button(action: onDelete) {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.secondary.opacity(0.7))
                    .padding(4)
            }
            .buttonStyle(.plain)
            .opacity(0.75)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.primary.opacity(0.04))
        )
    }
}
