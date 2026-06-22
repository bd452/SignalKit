# Getting Started

## Installation

Add SignalKit as a Swift Package Manager dependency in your `Package.swift` or Xcode project:

```swift
dependencies: [
    .package(url: "https://github.com/bd452/SignalKit.git", from: "0.1.0"),
]
```

Add `SignalKit` to your target's dependencies:

```swift
.target(
    name: "MyApp",
    dependencies: ["SignalKit"]
)
```

### Platform support

| Platform | Minimum version | UI layer |
| --- | --- | --- |
| iOS | 15.0 | UIKit |
| Mac Catalyst | 15.0 | UIKit |
| macOS | 13.0 | AppKit |

On iOS and Mac Catalyst, `SKView` is a type alias for `UIView`. On macOS, `SKView` is `NSView`.

## Your first component

A component is a lifecycle object — not a `UIView`. You subclass `Component`, define reactive state as `Signal` properties, construct UIKit views imperatively in `build()`, and return a `Node` describing layout.

```swift
import SignalKit
import UIKit

final class Greeting: Component {
    let name = Signal("World")

    override func build() -> Node {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .title2)

        bind(label, \.text, name) { "Hello, \($0)!" }

        return label.node
    }
}
```

### Mounting

Call `mount()` to run `build()` once and produce a root `SKView`:

```swift
let greeting = Greeting()
let rootView = greeting.mount()

// Add to your hierarchy
viewController.view.addSubview(rootView)
```

`mount()`:

1. Creates a `LifecycleScope`
2. Calls `build()`
3. Consumes the returned `Node` and produces a root view
4. Calls `didMount()`

### Updating

Change state by writing to signals. Bindings and observations update UIKit directly — `build()` is not called again.

```swift
greeting.name.set("SignalKit")
// label.text updates to "Hello, SignalKit!"
```

### Unmounting

When the component is no longer needed, call `unmount()` to dispose subscriptions, unmount children, and remove the root view:

```swift
greeting.unmount()
```

## A complete interactive example

```swift
import SignalKit
import UIKit

final class Counter: Component {
    let count = Signal(0)

    override func build() -> Node {
        let label = UILabel()
        label.textAlignment = .center
        label.font = .preferredFont(forTextStyle: .largeTitle)

        let decrement = UIButton(type: .system)
        decrement.setTitle("−", for: .normal)

        let increment = UIButton(type: .system)
        increment.setTitle("+", for: .normal)

        // Bind signal → UIKit property with a transform
        bind(label, \.text, count) { "Count: \($0)" }

        // Wire UIKit events → signal updates
        track(decrement.onTap { [count] in
            count.update { $0 - 1 }
        })
        track(increment.onTap { [count] in
            count.update { $0 + 1 }
        })

        return VStack(spacing: 16) {
            label
            HStack(spacing: 24) {
                decrement
                increment
            }
        }
    }
}
```

## Using components in view controllers

A typical integration pattern:

```swift
final class CounterViewController: UIViewController {
    private var counter: Counter?

    override func viewDidLoad() {
        super.viewDidLoad()

        let counter = Counter()
        let root = counter.mount()
        root.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(root)

        NSLayoutConstraint.activate([
            root.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            root.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])

        self.counter = counter
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        counter?.unmount()
        counter = nil
    }
}
```

Keep a strong reference to the component for as long as it is mounted. The root view does not retain the component.

## Child components

Nest components declaratively in stacks. The parent automatically tracks child lifetimes:

```swift
final class Screen: Component {
    let user: User

    init(user: User) {
        self.user = user
        super.init()
    }

    override func build() -> Node {
        VStack(spacing: 0) {
            HeaderComponent(user: user)
            BodyComponent(user: user)
            FooterComponent()
        }
    }
}
```

Each child component is mounted, its root view inserted into the stack, and its lifetime tied to the parent's scope.

## Imperative vs declarative split

SignalKit deliberately separates two concerns:

**Imperative** (inside `build()`):

- Create UIKit views
- Configure fonts, colors, constraints on individual views
- Attach bindings and event handlers

**Declarative** (at the `return` boundary):

- Describe how views and child components are arranged (`VStack`, `HStack`, `Slot`, `ForEach`)

```swift
override func build() -> Node {
    // Imperative: create and configure
    let imageView = UIImageView()
    imageView.contentMode = .scaleAspectFill
    imageView.layer.cornerRadius = 12
    imageView.clipsToBounds = true

    let label = UILabel()
    label.font = .preferredFont(forTextStyle: .headline)

    bind(label, \.text, title)

    // Declarative: arrange
    return HStack(spacing: 8) {
        imageView
        label
    }
}
```

## Next steps

- [Architecture Overview](architecture.md) — understand the rendering model
- [Signals](signals.md) — reactive state in depth
- [Binding & Observation](binding-and-observation.md) — connecting state to UI
- [Structural Hosts](structural-hosts.md) — dynamic UI with `Slot` and `ForEach`
