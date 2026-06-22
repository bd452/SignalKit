# Examples

Runnable SignalKit examples organized by pattern. Each example is self-contained — copy into an iOS target with SignalKit as a dependency.

All examples assume:

```swift
import SignalKit
import UIKit
```

## Examples

| Example | Concepts demonstrated |
| --- | --- |
| [Counter](counter.md) | Signals, `bind`, `onTap`, `VStack`/`HStack` |
| [View Controller Integration](view-controller-integration.md) | Mounting, retaining components, cleanup on dismiss |
| [Conditional UI with Slot](conditional-ui-with-slot.md) | `Slot`, dynamic child replacement |
| [Dynamic List with ForEach](dynamic-list-with-foreach.md) | `ForEach`, keyed identity, insert/remove/reorder |
| [Form with Validation](form-with-validation.md) | Multiple signals, `observe`, derived UI state |
| [Nested Components](nested-components.md) | Child components, composition, shared state |
| [Async Data Loading](async-data-loading.md) | Background fetch, main-actor signal updates, loading states |

## Running an example

### In a view controller

Most examples end with mounting into a view controller:

```swift
final class ExampleViewController: UIViewController {
    private var component: SomeComponent?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        let component = SomeComponent()
        let root = component.mount()
        root.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(root)

        NSLayoutConstraint.activate([
            root.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            root.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            root.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
        ])

        self.component = component
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if isMovingFromParent || isBeingDismissed {
            component?.unmount()
            component = nil
        }
    }
}
```

### In tests

SignalKit's own test suite mirrors several of these examples. Run tests with:

```bash
make test        # iOS Simulator
make test-macos  # macOS
```

## Related guides

- [Getting Started](../getting-started.md)
- [Best Practices](../best-practices.md)
