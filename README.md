# SignalKit

A UIKit-native component framework with signal-driven updates and declarative mount-time composition.

SignalKit is not a SwiftUI clone and not a React renderer. UIKit remains the rendering layer. Components own lifecycle and structure. Signals drive fine-grained reactive state. `build()` runs once per mount; ordinary updates mutate specific UIKit properties instead of rerendering the tree.

## Requirements

- Swift 6.0+
- iOS 15+, macOS 13+, or Mac Catalyst 15+

## Installation

Add SignalKit as a Swift Package Manager dependency:

```swift
dependencies: [
    .package(url: "https://github.com/bd452/SignalKit.git", from: "0.1.0"),
]
```

Then add `SignalKit` to your target dependencies.

## Quick start

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

// Mount into your view hierarchy
let counter = Counter()
let rootView = counter.mount()
parentView.addSubview(rootView)
```

## Core concepts

| Concept | Role |
| --- | --- |
| **Component** | Lifecycle owner. `build()` constructs UIKit views once and returns a mountable `Node`. |
| **Signal** | Main-actor observable value. Observers receive updates; bindings connect signals to UIKit properties. |
| **Node** | Temporary mount description consumed once — a view, child component, stack, `Slot`, or `ForEach`. |
| **bind** | Connects a signal to a UIKit key path with optional transform. |
| **observe** | Lifecycle-tracked imperative effects for non-key-path UI updates. |
| **Slot** | Dynamic single-child replacement driven by a signal. |
| **ForEach** | Keyed dynamic collections with stable row identity. |

Structural composition helpers (`VStack`, `HStack`) arrange mounted views and child components. Dynamic structure is handled by `Slot` and `ForEach`, not by re-running `build()`.

## Development

```bash
# macOS tests (AppKit-backed)
make test-macos

# iOS Simulator tests (UIKit-backed)
make test

# Build for iOS Simulator
make build
```

Or use SwiftPM directly:

```bash
swift test
swift build
```

## Architecture

See [ARCHITECTURE.md](ARCHITECTURE.md) for a detailed design overview — mounting model, lifecycle scopes, observer delivery, binding vs observation, and structural hosts.

## License

SignalKit is released under the MIT License. See [LICENSE](LICENSE) for details.
