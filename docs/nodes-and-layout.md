# Nodes & Layout

`Node` is a temporary mount description consumed once during `component.mount()`. It is not a virtual DOM node and not a persistent render tree.

Composition helpers (`VStack`, `HStack`) and the `NodeBuilder` result builder produce nodes that describe how views and child components are arranged.

## What is a Node?

A `Node` wraps one of:

| Content | Source | Mount result |
| --- | --- | --- |
| View | `label.node` | The view itself |
| Component | `MyComponent().node` | Child mounted; child's root view returned |
| Stack | `VStack { ... }` | `UIStackView` / `NSStackView` with arranged children |
| Fragment | Multiple siblings in a builder | Flattened into parent stack children |

```swift
public struct Node {
    // Internal — constructed via .node extensions and layout helpers
}
```

## Converting to nodes

### Views

```swift
let label = UILabel()
return label.node
```

`SKView` is `UIView` on iOS/Catalyst and `NSView` on macOS.

### Components

```swift
return HeaderComponent().node
```

Or simply place the component in a stack (the builder handles conversion):

```swift
return VStack {
    HeaderComponent()
}
```

## VStack and HStack

Vertical and horizontal stack composition helpers backed by `UIStackView` (UIKit) or `NSStackView` (AppKit).

### VStack

```swift
VStack(
    spacing: 12,
    alignment: .fill
) {
    titleLabel
    subtitleLabel
    FooterComponent()
}
```

| Parameter | Type | Default | Description |
| --- | --- | --- | --- |
| `spacing` | `CGFloat` | `0` | Space between arranged subviews |
| `alignment` | `StackAlignment` | `.fill` | Cross-axis alignment |
| `content` | `@NodeBuilder () -> Node` | — | Child nodes |

### HStack

```swift
HStack(spacing: 8, alignment: .center) {
    iconView
    titleLabel
    SpacerView()  // any SKView
}
```

Same parameters as `VStack`, with horizontal axis.

### StackAlignment

| Case | UIKit (`UIStackView.Alignment`) | Description |
| --- | --- | --- |
| `.fill` | `.fill` | Subviews expand to fill cross axis |
| `.leading` | `.leading` | Align to leading edge |
| `.center` | `.center` | Center on cross axis |
| `.trailing` | `.trailing` | Align to trailing edge |
| `.top` | `.top` | Align to top |
| `.bottom` | `.bottom` | Align to bottom |
| `.firstBaseline` | `.firstBaseline` | Align to first text baseline |
| `.lastBaseline` | `.lastBaseline` | Align to last text baseline |

On macOS, some alignments map to the closest `NSStackView` equivalent.

## NodeBuilder

`VStack` and `HStack` use `@NodeBuilder`, a `@resultBuilder` that supports:

| Feature | Example |
| --- | --- |
| Multiple children | `VStack { a; b; c }` |
| `if` / `else` | `VStack { if show { label } }` |
| `if let` | `VStack { if let user { UserView(user) } }` |
| `for` loops | `VStack { for item in items { Row(item) } }` |
| Mixed views and components | `VStack { label; MyComponent() }` |
| Nested stacks | `VStack { HStack { a; b } }` |

### Conditional content

Optional branches that produce no content use an internal `EmptyComponent` (zero-size view):

```swift
VStack {
    if isLoading {
        UIActivityIndicatorView()
    } else {
        contentLabel
    }
}
```

### Array content

`for` loops produce an `ArrayComponent` that flattens into the parent stack's children:

```swift
VStack {
    for item in staticItems {
        ItemView(item)
    }
}
```

For **dynamic** collections that change over time, use [`ForEach`](structural-hosts.md) instead.

## Root node rules

A component's `build()` must return a **single** root node. Multiple top-level siblings without a stack trigger a precondition failure:

```swift
// ❌ Invalid — fragment at root
override func build() -> Node {
    NodeBuilder.buildBlock(label.node, button.node)
}

// ✅ Valid — wrapped in a stack
override func build() -> Node {
    VStack {
        label
        button
    }
}

// ✅ Valid — single view
override func build() -> Node {
    label.node
}
```

Error message: `"Multiple root nodes must be wrapped in VStack { } or HStack { }"`.

## Mounting behavior

When `NodeMounter.mount` processes a node:

### View node

Returns the view unchanged. No wrapper is added.

### Component node

1. Calls `scope.trackChild(component)`
2. Calls `component.mount()`
3. Returns the child's root view

### Stack node

1. Creates a `UIStackView` / `NSStackView` with axis, spacing, alignment
2. Mounts each child recursively
3. Adds each child view as an arranged subview
4. Returns the stack view

### Fragment node

Cannot be a mount root. Must be flattened inside a stack.

## Layout beyond stacks

SignalKit provides `VStack` and `HStack` only. For other layout:

- Use Auto Layout constraints on views created in `build()`
- Use `UIStackView` distribution and spacing properties directly (access the stack after mount if needed)
- Embed custom container views

```swift
override func build() -> Node {
    let container = UIView()
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    container.addSubview(label)
    NSLayoutConstraint.activate([
        label.centerXAnchor.constraint(equalTo: container.centerXAnchor),
        label.centerYAnchor.constraint(equalTo: container.centerYAnchor),
    ])
    return container.node
}
```

## Nesting components

```swift
final class Screen: Component {
    override func build() -> Node {
        VStack(spacing: 0) {
            NavigationBar()
            HStack(spacing: 16) {
                Sidebar()
                MainContent()
            }
            TabBar()
        }
    }
}
```

Each nested `Component` is independently mounted with its own scope, tracked as a child of `Screen`.

## API reference

```swift
extension SKView {
    public var node: Node { get }
}

extension Component {
    public var node: Node { get }
}

@MainActor
public func VStack(
    spacing: CGFloat = 0,
    alignment: StackAlignment = .fill,
    @NodeBuilder content: () -> Node
) -> Node

@MainActor
public func HStack(
    spacing: CGFloat = 0,
    alignment: StackAlignment = .fill,
    @NodeBuilder content: () -> Node
) -> Node

public enum StackAxis: Sendable {
    case horizontal
    case vertical
}

public enum StackAlignment: Sendable {
    case fill, leading, center, trailing
    case top, bottom, firstBaseline, lastBaseline
}
```

## Related

- [Components](components.md) — `build()` and mounting
- [Structural Hosts](structural-hosts.md) — `Slot`, `ForEach` for dynamic structure
