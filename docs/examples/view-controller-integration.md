# Example: View Controller Integration

How to mount a SignalKit component inside a `UIViewController`, retain it correctly, and clean up on dismiss.

**Concepts:** `mount`, `unmount`, component retention, Auto Layout

## Screen component

```swift
import SignalKit
import UIKit

final class WelcomeScreen: Component {
    let name = Signal("Guest")

    override func build() -> Node {
        let greeting = UILabel()
        greeting.font = .preferredFont(forTextStyle: .title1)
        greeting.textAlignment = .center
        greeting.numberOfLines = 0

        let field = UITextField()
        field.placeholder = "Enter your name"
        field.borderStyle = .roundedRect
        field.textAlignment = .center

        let button = UIButton(type: .system)
        button.setTitle("Greet", for: .normal)

        bind(greeting, \.text, name) { "Welcome, \($0)!" }

        track(field.onEvent(.editingChanged) { [field, name] in
            name.set(field.text?.isEmpty == false ? field.text! : "Guest")
        })

        track(button.onTap { [field, name] in
            field.resignFirstResponder()
            if let text = field.text, !text.isEmpty {
                name.set(text)
            }
        })

        return VStack(spacing: 20) {
            greeting
            field
            button
        }
    }
}
```

## View controller

```swift
final class WelcomeViewController: UIViewController {
    private var screen: WelcomeScreen?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Welcome"

        let screen = WelcomeScreen()
        let root = screen.mount()
        root.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(root)

        NSLayoutConstraint.activate([
            root.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 24),
            root.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -24),
            root.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
        ])

        self.screen = screen
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        guard isMovingFromParent || isBeingDismissed else { return }
        screen?.unmount()
        screen = nil
    }
}
```

## App delegate / scene setup

```swift
// In SceneDelegate or AppDelegate
let nav = UINavigationController(rootViewController: WelcomeViewController())
window?.rootViewController = nav
window?.makeKeyAndVisible()
```

## Key points

### Retain the component, not just the view

The root view does **not** retain the component. Store a strong reference:

```swift
private var screen: WelcomeScreen?  // ✅
```

If you only keep the `UIView`, the component may deallocate while still mounted, breaking bindings and events.

### Unmount when leaving the hierarchy

Unmount in `viewDidDisappear` when the controller is being removed:

```swift
if isMovingFromParent || isBeingDismissed {
    screen?.unmount()
    screen = nil
}
```

This disposes observers and event handlers so they don't fire after the screen is gone.

### Pinning with Auto Layout

Always set `translatesAutoresizingMaskIntoConstraints = false` on the mounted root before adding constraints.

## Child view controller pattern

To embed a component as a child VC's entire content:

```swift
final class ComponentViewController<C: Component>: UIViewController {
    private let component: C

    init(component: C) {
        self.component = component
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        let root = component.mount()
        root.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(root)
        NSLayoutConstraint.activate([
            root.topAnchor.constraint(equalTo: view.topAnchor),
            root.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            root.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            root.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        guard isMovingFromParent || isBeingDismissed else { return }
        component.unmount()
    }
}

// Usage:
let vc = ComponentViewController(component: WelcomeScreen())
navigationController?.pushViewController(vc, animated: true)
```

## Related

- [Components](../components.md)
- [Lifecycle](../lifecycle.md)
