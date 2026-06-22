# Best Practices

Patterns, recommendations, and common pitfalls for building with SignalKit.

## Design principles

### build() is construction, not rendering

Write `build()` as if it runs once — because it does. Do not expect it to re-run when signals change.

```swift
// ❌ Don't read signals expecting re-build
override func build() -> Node {
    let label = UILabel()
    label.text = "Count: \(count.current)"  // stale after first mount
    return label.node
}

// ✅ Bind for reactive updates
override func build() -> Node {
    let label = UILabel()
    bind(label, \.text, count) { "Count: \($0)" }
    return label.node
}
```

### Keep transforms at the binding site

Don't create derived signals for one-off UI formatting:

```swift
// ✅ Transform in bind
bind(label, \.text, date) { $0.formatted(date: .abbreviated, time: .shortened) }

// ❌ Unnecessary indirection
let formattedDate = ... // derived signal machinery
```

### Use the right reactivity primitive

| Need | Use |
| --- | --- |
| One UIKit property | `bind` |
| Multiple properties / logic | `observe` |
| Dynamic child subtree | `Slot` |
| Dynamic list | `ForEach` |
| Button tap → state change | `track(control.onTap { ... })` |

## State management

### Colocate state with the component that owns it

```swift
final class SearchBar: Component {
    let query = Signal("")
    // bindings and events here
}
```

### Share state via constructor injection

```swift
final class Child: Component {
    let count: Signal<Int>
    init(count: Signal<Int>) {
        self.count = count
        super.init()
    }
}
```

### Prefer setIfChanged for Equatable values

Avoids unnecessary observer churn:

```swift
status.setIfChanged(.loaded)  // skips if already .loaded
items.setIfChanged(newItems)    // skips if array is equal
```

## Threading

### Always update signals on the main actor

```swift
Task.detached {
    let data = await fetch()
    await MainActor.run {
        self.dataSignal.set(data)
    }
}
```

### Don't update UIKit directly from background threads

Bindings deliver on the main actor, but if you mutate UIKit outside SignalKit, ensure main-thread execution yourself.

## Lists and performance

### Small lists: ForEach + UIStackView

Fine for settings screens, short menus, form sections (< 20–30 items).

```swift
ForEach(items, id: \.id) { item in
    SettingsRow(item: item)
}
```

### Large lists: UICollectionView / UITableView

For scrollable lists with many rows, use native collection/table views:

1. Create the collection view in `build()`
2. Use a data source that holds row components or cell content
3. Drive updates from signals in `observe` callbacks
4. Diff at the collection level, not with `ForEach`

SignalKit's `ForEach` is a structural host for small dynamic stacks, not a replacement for `UICollectionView`.

### Stable row identity

Pass stable IDs and update row content via signals rather than remounting:

```swift
// Row preserves mount when ID is stable
ForEach(items, id: \.id) { item in
    RowView(store: rowStore, id: item.id)
}
```

## Component composition

### Prefer declarative nesting

```swift
// ✅
VStack {
    HeaderComponent()
    ContentComponent()
}

// ❌ Unnecessary escape hatch
VStack {
    host(HeaderComponent())
}
```

### Use Slot for conditional screens

```swift
Slot(flow) { flow in
    switch flow {
    case .onboarding: OnboardingComponent()
    case .main: MainComponent()
    }
}
```

### Don't use for-loops for dynamic data

```swift
// ❌ Static at mount time — won't update
VStack {
    for item in items.current {
        Row(item)
    }
}

// ✅ Reactive
ForEach(items, id: \.id) { item in
    Row(item)
}
```

## Memory and lifecycle

### Hold strong references to mounted components

```swift
private var screen: MainScreen?

func present() {
    screen = MainScreen()
    view.addSubview(screen!.mount())
}

func dismiss() {
    screen?.unmount()
    screen = nil
}
```

### Always unmount when removing from hierarchy

```swift
override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    if isMovingFromParent {
        component?.unmount()
        component = nil
    }
}
```

### Use capture lists in event handlers

```swift
track(button.onTap { [count] in
    count.update { $0 + 1 }
})
```

## Testing

SignalKit's signal layer is testable without UIKit:

```swift
@Test @MainActor
func counterIncrements() {
    let count = Signal(0)
    var received: [Int] = []
    _ = count.observe { received.append($0) }

    count.update { $0 + 1 }
    #expect(received == [1])
}
```

Component tests require UIKit and should use `@Suite(.serialized)` to avoid window/view conflicts:

```swift
#if canImport(UIKit)
@Suite(.serialized)
@MainActor
struct MyComponentTests {
    @Test func mountsAndUpdates() { ... }
}
#endif
```

## Common pitfalls

### Reading signal.current in build() without binding

The value is captured once at mount. Use `bind` or `observe` for reactive behavior.

### Expecting ForEach to remount rows on data change

Rows are preserved by ID. Push data changes into the row via signals.

### Duplicate ForEach IDs

Crashes with precondition failure. Ensure unique identities.

### Multiple root nodes

Wrap siblings in `VStack` or `HStack`.

### Calling mount() twice

Precondition failure. Create a new component instance instead.

### Forgetting track() on events

Event handlers leak and fire after unmount if not tracked:

```swift
// ❌ Handler survives unmount
button.onTap { ... }

// ✅
track(button.onTap { ... })
```

## macOS considerations

On macOS, `SKView` is `NSView` and stacks use `NSStackView`. `UIControl` event helpers are not available — wire `NSControl` actions manually and wrap in a `Disposable`.

```swift
#if canImport(AppKit) && !canImport(UIKit)
// Use NSButton, NSTextField, NSStackView
// Custom Disposable for control actions
#endif
```

## When not to use SignalKit

SignalKit is a strong fit when you want:

- UIKit-native view construction
- Organized lifecycle and cleanup
- Fine-grained reactive property updates
- Declarative mount-time composition

Consider alternatives when you need:

- Full declarative UI with automatic invalidation (SwiftUI)
- Large-scale list virtualization out of the box
- Cross-platform UI beyond Apple platforms

## Related

- [Architecture Overview](architecture.md) — rendering model
- [Lifecycle](lifecycle.md) — disposal and safety
- [Structural Hosts](structural-hosts.md) — Slot and ForEach behavior
