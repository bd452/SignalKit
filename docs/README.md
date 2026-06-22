# SignalKit Documentation

SignalKit is a UIKit-native (and AppKit on macOS) component framework with signal-driven updates and declarative mount-time composition. It is **not** a SwiftUI clone and **not** a React renderer — UIKit remains the rendering layer.

## How SignalKit works

```text
Component builds once
  → build() returns a temporary Node
  → Node mounts into real UIKit views
  → signals update specific UIKit properties
  → structural hosts (Slot, ForEach) handle dynamic child replacement
```

Ordinary signal updates do **not** call `build()` again. There is no virtual DOM and no generalized reconciliation pass.

## Documentation

| Guide | Description |
| --- | --- |
| [Getting Started](getting-started.md) | Installation, first component, mounting into a view hierarchy |
| [Architecture Overview](architecture.md) | Mental model, ownership boundaries, update flows |
| [Signals](signals.md) | `Signal<Value>`, observers, delivery modes, nested writes |
| [Components](components.md) | `Component`, `build()`, mount/unmount, lifecycle hooks |
| [Nodes & Layout](nodes-and-layout.md) | `Node`, `VStack`, `HStack`, `NodeBuilder`, composition |
| [Binding & Observation](binding-and-observation.md) | `bind`, `observe`, when to use each |
| [Events](events.md) | `UIControl` event helpers, `track` |
| [Structural Hosts](structural-hosts.md) | `Slot`, `ForEach`, `host()`, `ComponentHostView` |
| [Lifecycle](lifecycle.md) | `LifecycleScope`, disposal order, safety guarantees |
| [Best Practices](best-practices.md) | Patterns, pitfalls, threading, list performance |
| [Examples](examples/README.md) | Runnable examples — counter, forms, lists, async loading |

## Requirements

- Swift 6.0+
- iOS 15+, macOS 13+, or Mac Catalyst 15+
- All public APIs are `@MainActor` isolated

## Quick reference

```swift
import SignalKit
import UIKit

final class Counter: Component {
    let count = Signal(0)

    override func build() -> Node {
        let label = UILabel()
        let button = UIButton(type: .system)

        bind(label, \.text, count) { "Count: \($0)" }
        button.setTitle("Increment", for: .normal)

        track(button.onTap { [count] in
            count.update { $0 + 1 }
        })

        return VStack(spacing: 12) {
            label
            button
        }
    }
}

let counter = Counter()
let rootView = counter.mount()
parentView.addSubview(rootView)
```

## API surface at a glance

| Type / API | Module area | Purpose |
| --- | --- | --- |
| `Signal<Value>` | Reactive state | Observable value container |
| `ObserverDelivery` | Reactive state | `.immediate` or `.main` delivery |
| `Disposable` | Core | Cleanup handle for observers and events |
| `Component` | Components | Lifecycle owner with `build()` |
| `Node` | Nodes | Temporary mount description |
| `VStack` / `HStack` | Layout | Stack composition helpers |
| `bind(_:_:_:)` | Components | Signal → UIKit key path |
| `observe(_:_:)` | Components | Lifecycle-tracked imperative effects |
| `track(_:)` | Components | Lifecycle-tracked disposable |
| `Slot(_:content:)` | Structural | Dynamic single-child replacement |
| `ForEach(_:id:content:)` | Structural | Keyed dynamic collections |
| `host(_:)` | Components | Embed child in a container view |
| `UIControl.onTap` / `onEvent` | Events | Disposable UIKit event registration |

For the original design rationale, see also [ARCHITECTURE.md](../ARCHITECTURE.md) in the repository root.
