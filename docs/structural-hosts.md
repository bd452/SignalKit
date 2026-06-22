# Structural Hosts

Structural hosts manage dynamic view hierarchy changes without re-running `build()`. SignalKit provides two built-in hosts: `Slot` for single-child replacement and `ForEach` for keyed collections.

## Slot

Replaces a single child component when a driving signal changes. The slot's container view remains stable; only the child subtree swaps.

### Basic usage

```swift
final class AuthScreen: Component {
    let isLoggedIn = Signal(false)

    override func build() -> Node {
        Slot(isLoggedIn) { loggedIn in
            loggedIn ? ProfileComponent() : LoginComponent()
        }
    }
}
```

When `isLoggedIn` changes:

```text
old child released from scope and unmounted
new child mounted and tracked in scope
new child root view replaces old root view
slot container remains stable
```

### API

```swift
@MainActor
public func Slot<Value>(
    _ signal: Signal<Value>,
    content: @escaping (Value) -> Component
) -> Node
```

| Parameter | Description |
| --- | --- |
| `signal` | Driving signal — any `Value` type |
| `content` | Factory that returns a `Component` for the current value |

### Enum-driven slots

```swift
enum Tab { case home, settings, profile }

final class TabHost: Component {
    let selectedTab = Signal(Tab.home)

    override func build() -> Node {
        Slot(selectedTab) { tab in
            switch tab {
            case .home: HomeComponent()
            case .settings: SettingsComponent()
            case .profile: ProfileComponent()
            }
        }
    }
}
```

### Optional content

```swift
Slot(selectedItem) { item in
    if let item {
        DetailComponent(item: item)
    } else {
        EmptyStateComponent()
    }
}
```

The `content` closure must always return a `Component`. Use an empty or placeholder component for nil cases.

### Nesting slots

```swift
VStack {
    Slot(authState) { state in
        switch state {
        case .loggedOut: LoginComponent()
        case .loggedIn(let user): DashboardComponent(user: user)
        }
    }
    FooterComponent()
}
```

## ForEach

Manages a keyed collection of child components with insert, remove, and reorder support.

### Basic usage

```swift
struct Item: Equatable {
    let id: Int
    let title: String
}

final class ListScreen: Component {
    let items = Signal<[Item]>([])

    override func build() -> Node {
        ForEach(items, id: \.id) { item in
            RowComponent(item: item)
        }
    }
}
```

### API

```swift
@MainActor
public func ForEach<Data, ID, Content>(
    _ data: Signal<Data>,
    id keyPath: KeyPath<Data.Element, ID>,
    content: @escaping (Data.Element) -> Content
) -> Node
where Data: RandomAccessCollection,
      ID: Hashable,
      Content: Component
```

| Parameter | Description |
| --- | --- |
| `data` | Signal of a `RandomAccessCollection` |
| `id` | Key path to a `Hashable` identity per element |
| `content` | Factory returning a row `Component` per element |

### Identity and preservation

When an element's ID is stable across data updates, its mounted row component is **preserved** — not remounted:

```swift
// Initial: [{ id: 1, title: "A" }]
// Update:  [{ id: 1, title: "B" }]
// Row component is NOT remounted — title stays "A" in the label
```

Data changes for an existing ID should be handled **inside** the row component via signals and bindings, not by expecting `ForEach` to rebuild the row.

```swift
final class Row: Component {
    let item: Signal<Item>

    init(item: Item) {
        self.item = Signal(item)
        super.init()
    }

    override func build() -> Node {
        let label = UILabel()
        bind(label, \.text, item) { $0.title }
        return label.node
    }

    func updateItem(_ newItem: Item) {
        item.set(newItem)
    }
}
```

Or pass a shared signal:

```swift
ForEach(items, id: \.id) { item in
    Row(item: item)  // row reads from a model store by ID
}
```

### Insert, remove, reorder

`ForEach` diffs the collection by ID:

| Change | Behavior |
| --- | --- |
| New ID | Mount new row component, add to stack |
| Removed ID | Unmount row, remove from stack |
| Reordered IDs | Reorder arranged subviews in stack |
| Same ID, new data | Row preserved (no remount) |

```swift
// [A, B] → [B, C]
// A removed, C inserted, B preserved and moved to index 0
```

### Duplicate IDs

Duplicate IDs in the collection trigger a runtime precondition failure:

```text
ForEach data contains duplicate IDs; each element must have a unique identity
```

Ensure your `id` key path produces unique values.

### Static vs dynamic lists

| Pattern | When to use |
| --- | --- |
| `for item in items { Row(item) }` in `VStack` | Static list known at mount time |
| `ForEach(signal, id:)` | Dynamic list that changes over time |

## host() and ComponentHostView

### `host(_:)` on Component

Embeds a child component in a container view when you need a view reference immediately (e.g., for UIKit APIs that require a `UIView`):

```swift
override func build() -> Node {
    let container = UIView()
    let headerView = host(HeaderComponent())
    container.addSubview(headerView)
    // ... constraints ...
    return container.node
}
```

The child's lifetime is tied to the parent's scope.

### `ComponentHostView`

Internal container used by `host()`. Can also be constructed directly when needed:

```swift
let hostView = ComponentHostView(component: MyComponent())
parentView.addSubview(hostView)
```

`ComponentHostView`:

- Mounts the component on init
- Pins the component's root view to its bounds with Auto Layout
- Unmounts the component on deinit

> Prefer declarative composition in stacks over `ComponentHostView` when possible. Use the escape hatch only when an API requires a view upfront.

## Combining structural hosts

```swift
final class App: Component {
    let user = Signal<User?>(nil)
    let items = Signal<[Item]>([])

    override func build() -> Node {
        VStack {
            Slot(user) { user in
                user != nil ? HeaderComponent() : LoginPrompt()
            }
            ForEach(items, id: \.id) { item in
                RowComponent(item: item)
            }
        }
    }
}
```

## Performance considerations

### ForEach with UIStackView

The built-in `ForEach` backs onto a vertical `UIStackView`. This works well for small lists (roughly < 20–30 rows). For larger lists:

- Use `UICollectionView` or `UITableView`
- Manage cell/row components via the collection/table data source
- Use signals for data and keyed identity at the collection level

See [Best Practices](best-practices.md) for list performance guidance.

## API reference

```swift
@MainActor
public func Slot<Value>(
    _ signal: Signal<Value>,
    content: @escaping (Value) -> Component
) -> Node

@MainActor
public func ForEach<Data, ID, Content>(
    _ data: Signal<Data>,
    id keyPath: KeyPath<Data.Element, ID>,
    content: @escaping (Data.Element) -> Content
) -> Node
where Data: RandomAccessCollection, ID: Hashable, Content: Component

// On Component:
public func host(_ child: Component) -> SKView
```

## Related

- [Nodes & Layout](nodes-and-layout.md) — static composition with stacks
- [Components](components.md) — child component lifetimes
- [Lifecycle](lifecycle.md) — `trackChild` / `releaseChild` internals
