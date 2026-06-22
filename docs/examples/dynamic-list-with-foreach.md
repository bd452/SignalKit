# Example: Dynamic List with ForEach

A reactive list that inserts, removes, and reorders rows as the backing signal changes.

**Concepts:** `ForEach`, keyed identity, row components, stable IDs

## Model

```swift
struct TodoItem: Equatable {
    let id: UUID
    var title: String
    var isDone: Bool
}
```

## Row component

Each row owns its display state. For stable IDs, push data changes into the row via signals:

```swift
final class TodoRow: Component {
    let item: Signal<TodoItem>
    let onToggle: () -> Void
    let onDelete: () -> Void

    init(item: TodoItem, onToggle: @escaping () -> Void, onDelete: @escaping () -> Void) {
        self.item = Signal(item)
        self.onToggle = onToggle
        self.onDelete = onDelete
        super.init()
    }

    func updateItem(_ newItem: TodoItem) {
        item.set(newItem)
    }

    override func build() -> Node {
        let checkbox = UIButton(type: .system)
        let titleLabel = UILabel()
        titleLabel.font = .preferredFont(forTextStyle: .body)

        let deleteButton = UIButton(type: .system)
        deleteButton.setTitle("Delete", for: .normal)
        deleteButton.setTitleColor(.systemRed, for: .normal)

        observe(item) { [checkbox, titleLabel] todo in
            checkbox.setTitle(todo.isDone ? "☑" : "☐", for: .normal)
            titleLabel.text = todo.title
            titleLabel.textColor = todo.isDone ? .secondaryLabel : .label
        }

        track(checkbox.onTap { [onToggle] in onToggle() })
        track(deleteButton.onTap { [onDelete] in onDelete() })

        return HStack(spacing: 12) {
            checkbox
            titleLabel
            deleteButton
        }
    }
}
```

## List host

```swift
final class TodoList: Component {
    let items = Signal<[TodoItem]>([
        TodoItem(id: UUID(), title: "Buy groceries", isDone: false),
        TodoItem(id: UUID(), title: "Walk the dog", isDone: true),
    ])

    override func build() -> Node {
        let addField = UITextField()
        addField.placeholder = "New todo"
        addField.borderStyle = .roundedRect

        let addButton = UIButton(type: .system)
        addButton.setTitle("Add", for: .normal)

        track(addButton.onTap { [weak self, addField] in
            guard let self,
                  let text = addField.text,
                  !text.isEmpty else { return }
            addField.text = nil
            self.items.update { $0 + [TodoItem(id: UUID(), title: text, isDone: false)] }
        })

        return VStack(spacing: 16) {
            HStack(spacing: 8) {
                addField
                addButton
            }
            ForEach(items, id: \.id) { item in
                TodoRow(
                    item: item,
                    onToggle: { [weak self] in self?.toggle(item.id) },
                    onDelete: { [weak self] in self?.delete(item.id) }
                )
            }
        }
    }

    private func toggle(_ id: UUID) {
        items.update { list in
            list.map { item in
                guard item.id == id else { return item }
                var copy = item
                copy.isDone.toggle()
                return copy
            }
        }
    }

    private func delete(_ id: UUID) {
        items.update { $0.filter { $0.id != id } }
    }
}
```

## Usage

```swift
let list = TodoList()
view.addSubview(list.mount())
```

## ForEach behavior demonstrated

### Add item

```text
items.update { $0 + [newItem] }
  → ForEach sees new ID
  → mounts new TodoRow
  → adds row view to stack
```

### Delete item

```text
items.update { $0.filter { ... } }
  → ForEach sees removed ID
  → releaseChild(row) — unmounts row
  → removes view from stack
```

### Reorder

```swift
list.items.set([
    items[2], items[0], items[1],
])
// Rows with stable IDs are preserved and reordered in the stack
```

### Same ID, updated data

When you update an item in the array but keep the same `id`, ForEach **preserves** the mounted row. Update the row's internal signal:

```swift
// If you hold a reference to the row, call updateItem
// Or restructure so rows read from a shared store keyed by ID
```

## Important: unique IDs

```swift
// ❌ Crashes — duplicate IDs
items.set([
    TodoItem(id: sameUUID, title: "A"),
    TodoItem(id: sameUUID, title: "B"),
])
```

Precondition: `"ForEach data contains duplicate IDs"`.

## When to use UITableView instead

This pattern uses a vertical `UIStackView` under the hood. It works well for short lists (< 20–30 rows). For long scrollable lists, use `UITableView` or `UICollectionView` and manage row components at the cell level.

## Related

- [Structural Hosts](../structural-hosts.md)
- [Best Practices](../best-practices.md) — list performance
