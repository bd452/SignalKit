# Events

SignalKit wraps UIKit control events as disposable registrations. Event handlers are installed during `build()` and tracked via `Component.track(_:)` so they are removed automatically on unmount.

> **Platform note:** `UIControl` event helpers are available on iOS and Mac Catalyst (`#if canImport(UIKit)`). On macOS (AppKit-only), use `NSControl` target/action patterns directly and wrap them in a custom `Disposable`, or use `track` with a manual registration.

## UIControl extensions

### `onTap(_:)`

Registers a handler for `.touchUpInside`:

```swift
track(button.onTap {
    count.update { $0 + 1 }
})
```

### `onEvent(_:handler:)`

Registers a handler for any `UIControl.Event`:

```swift
track(textField.onEvent(.editingChanged) {
    query.set(textField.text ?? "")
})

track(slider.onEvent(.valueChanged) {
    volume.set(slider.value)
})

track(button.onEvent(.touchDown) {
  // pressed state
})
```

Common `UIControl.Event` values:

| Event | Typical use |
| --- | --- |
| `.touchUpInside` | Button tap (default for `onTap`) |
| `.touchDown` | Press began |
| `.touchUpInside` | Press completed inside bounds |
| `.editingChanged` | Text field content changed |
| `.valueChanged` | Slider, switch, segmented control |

## The track pattern

Always wrap event registrations with `track` inside `build()`:

```swift
override func build() -> Node {
    let button = UIButton(type: .system)
    button.setTitle("Save", for: .normal)

    track(button.onTap { [self] in
        save()
    })

    return button.node
}
```

`track` registers the returned `Disposable` with the component's lifecycle scope. On unmount:

1. The target/action pair is removed from the control
2. The handler will not fire again

## Event → signal → UI flow

The typical reactive cycle:

```text
UIKit event (tap)
  → handler runs
  → signal.update / signal.set
  → bindings / observations run
  → UIKit properties mutate
```

Example:

```swift
final class Counter: Component {
    let count = Signal(0)

    override func build() -> Node {
        let label = UILabel()
        let button = UIButton(type: .system)

        bind(label, \.text, count) { "Count: \($0)" }
        button.setTitle("+", for: .normal)

        track(button.onTap { [count] in
            count.update { $0 + 1 }
        })

        return VStack { label; button }
    }
}
```

## Capture lists

Use explicit capture lists to avoid retain cycles and clarify ownership:

```swift
// Capture the signal, not self
track(button.onTap { [count] in
    count.update { $0 + 1 }
})

// Capture self when calling instance methods
track(button.onTap { [self] in
    handleTap()
})

// Weak self for potentially long-lived references
track(button.onTap { [weak self] in
    self?.submit()
})
```

## How event registration works

Internally, `onEvent` creates:

1. A `ControlEventTarget` object holding the handler closure
2. A `ControlEventRegistration` conforming to `Disposable`
3. A target/action pair on the `UIControl`

On `dispose()`:

- `removeTarget(_:action:for:)` is called
- The weak reference to the control is cleared

## Custom events and gestures

SignalKit currently ships `UIControl` helpers only. For other UIKit event sources, create a custom `Disposable`:

```swift
final class GestureRegistration: Disposable {
    private var gesture: UITapGestureRecognizer?
    private weak var view: UIView?

    init(view: UIView, handler: @escaping () -> Void) {
        self.view = view
        let gesture = UITapGestureRecognizer(target: nil, action: nil)
        // ... wire up handler ...
        view.addGestureRecognizer(gesture)
        self.gesture = gesture
    }

    func dispose() {
        if let gesture, let view {
            view.removeGestureRecognizer(gesture)
        }
        gesture = nil
        view = nil
    }
}
```

Then track it:

```swift
track(GestureRegistration(view: cardView) {
    onCardTapped()
})
```

## API reference

```swift
extension UIControl {
    public func onTap(_ handler: @escaping () -> Void) -> any Disposable

    public func onEvent(
        _ event: UIControl.Event,
        handler: @escaping () -> Void
    ) -> any Disposable
}
```

```swift
// On Component:
@discardableResult
func track(_ disposable: any Disposable) -> any Disposable
```

## Related

- [Components](components.md) — `track` and lifecycle
- [Binding & Observation](binding-and-observation.md) — signal-driven UI updates after events
- [Lifecycle](lifecycle.md) — event handler disposal
