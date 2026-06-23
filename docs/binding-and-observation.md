# Binding & Observation

SignalKit provides three ways to react to signal changes. They differ in lifecycle tracking, delivery policy, and intended use case.

## Overview

| API | Lifecycle tracked | Main actor | Use case |
| --- | --- | --- | --- |
| `bind(target, keyPath, signal)` | Yes | Yes | Assign one UIKit property from a signal |
| `bind(target, keyPath, signal, transform:)` | Yes | Yes | Assign with value transformation |
| `observe(signal, handler)` | Yes | Yes | Arbitrary UIKit mutations |
| `signal.observe(handler)` | No | Configurable | Manual subscriptions, non-UI logic |

All component methods (`bind`, `observe`) must be called from `build()` during mounting.

## bind

Connects a signal to a UIKit writable key path. The binding:

1. Sets the initial value from `signal.current`
2. Subscribes to future changes with `.main` delivery
3. Weakly holds the target to avoid retain cycles
4. Checks lifecycle scope before mutating
5. Disposes automatically on unmount

### Direct type match

When the signal value type matches the property type:

```swift
bind(button, \.isEnabled, canSubmit)
bind(imageView, \.isHidden, isLoading)
bind(slider, \.value, volume)  // when types align
```

Equivalent to:

```swift
bind(button, \.isEnabled, canSubmit, transform: { $0 })
```

### With transform

When the signal value needs conversion before assignment:

```swift
bind(label, \.text, count) { "Count: \($0)" }

bind(label, \.textColor, isError) { $0 ? .systemRed : .label }

bind(progressView, \.progress, downloadProgress) { Float($0) }
```

The transform runs at the binding site. SignalKit does not provide derived signal chains — keep one-off UI transformations in the binding.

### How bindings work

```text
signal changes
  → binding callback scheduled on main actor
  → lifecycle guard passes (scope alive)
  → target view still exists (weak reference)
  → key path assignment
```

If the component unmounts before a scheduled callback runs, the callback is dropped (debug builds log a warning).

## observe (component)

Lifecycle-tracked observation for imperative UIKit mutations that don't map to a single key path:

```swift
observe(user) { user in
    imageView.image = user.avatar
    nameLabel.text = user.name
    badgeView.isHidden = user.isVerified
}
```

When a side effect depends on more than one signal, pass them all — the handler runs whenever **any** of them changes, with each signal's current value:

```swift
observe(firstName, lastName) { first, last in
    fullNameLabel.text = "\(first) \(last)"
}

observe(price, quantity, discount) { price, qty, discount in
    totalLabel.text = formatTotal(price: price, quantity: qty, discount: discount)
}
```

### fireImmediately

Defaults to `true`. The handler runs once immediately with `signal.current`, then on every subsequent change:

```swift
observe(count, fireImmediately: true) { value in
    // runs immediately with current value, then on each change
}

observe(count, fireImmediately: false) { value in
    // runs only on changes after subscription
}
```

### When to use observe vs bind

| Scenario | Use |
| --- | --- |
| Single property assignment | `bind` |
| Multiple properties from one signal | `observe` |
| Conditional logic before mutation | `observe` |
| Side effects without UI (logging) | `signal.observe` or `observe` |
| Non-UIKit work | `signal.observe` |

```swift
// ✅ bind — one property, one signal
bind(label, \.text, title)

// ✅ observe — multiple mutations
observe(theme) { theme in
    label.textColor = theme.primaryColor
    backgroundView.backgroundColor = theme.backgroundColor
    iconView.tintColor = theme.accentColor
}

// ❌ avoid — use bind instead
observe(title) { label.text = $0 }
```

## signal.observe (raw)

Low-level subscription returning a `Disposable`. Not lifecycle-tracked unless you pass it to `track`:

```swift
let disposable = signal.observe(on: .immediate) { value in
    print(value)
}
disposable.dispose()
```

Or track it manually in a component:

```swift
track(signal.observe { value in
    // custom logic
})
```

For side effects that depend on multiple signals, use the module-level `observe` overload:

```swift
let disposable = observe(count, label, fireImmediately: false) { count, label in
    print("\(label): \(count)")
}
disposable.dispose()
```

The handler runs whenever **any** of the signals changes, receiving the current value from each.

### Delivery modes

```swift
signal.observe(on: .immediate) { ... }  // synchronous (default)
signal.observe(on: .main) { ... }       // main actor delivery
```

See [Signals](signals.md) for delivery mode details.

## Comparison diagram

```text
┌─────────────────────────────────────────────────────────┐
│                      Signal<Value>                       │
│                    value changes                         │
└────────────────────────┬────────────────────────────────┘
                         │
         ┌───────────────┼───────────────┐
         ▼               ▼               ▼
    bind(...)      observe(...)    signal.observe(...)
         │               │               │
    key path         arbitrary       manual lifetime
    assignment       UIKit work      any callback
         │               │               │
         ▼               ▼               ▼
    auto-disposed    auto-disposed    Disposable.dispose()
    on unmount       on unmount
```

## Complete example

```swift
final class UserCard: Component {
    let user = Signal<User?>(nil)

    override func build() -> Node {
        let avatar = UIImageView()
        avatar.contentMode = .scaleAspectFill
        avatar.layer.cornerRadius = 24
        avatar.clipsToBounds = true

        let nameLabel = UILabel()
        nameLabel.font = .preferredFont(forTextStyle: .headline)

        let emailLabel = UILabel()
        emailLabel.font = .preferredFont(forTextStyle: .subheadline)
        emailLabel.textColor = .secondaryLabel

        let placeholder = UILabel()
        placeholder.text = "No user loaded"
        placeholder.textColor = .tertiaryLabel

        // Imperative effect for multi-property update
        observe(user) { user in
            if let user {
                avatar.image = user.avatar
                nameLabel.text = user.name
                emailLabel.text = user.email
                placeholder.isHidden = true
            } else {
                avatar.image = nil
                nameLabel.text = nil
                emailLabel.text = nil
                placeholder.isHidden = false
            }
        }

        return VStack(spacing: 8) {
            avatar
            nameLabel
            emailLabel
            placeholder
        }
    }
}
```

## API reference

```swift
// On Component:

@discardableResult
func bind<Target: AnyObject, Value>(
    _ target: Target,
    _ keyPath: ReferenceWritableKeyPath<Target, Value>,
    _ signal: Signal<Value>
) -> any Disposable

@discardableResult
func bind<Target: AnyObject, SignalValue, PropertyValue>(
    _ target: Target,
    _ keyPath: ReferenceWritableKeyPath<Target, PropertyValue>,
    _ signal: Signal<SignalValue>,
    transform: @escaping (SignalValue) -> PropertyValue
) -> any Disposable

@discardableResult
func observe<Value>(
    _ signal: Signal<Value>,
    fireImmediately: Bool = true,
    _ handler: @escaping (Value) -> Void
) -> any Disposable

@discardableResult
func observe<A, B>(
    _ a: Signal<A>,
    _ b: Signal<B>,
    fireImmediately: Bool = true,
    _ handler: @escaping (A, B) -> Void
) -> any Disposable

// ...and similarly through ten signals.
```

## Related

- [Signals](signals.md) — signal read/write API
- [Events](events.md) — UIKit events that trigger signal updates
- [Lifecycle](lifecycle.md) — what happens to bindings on unmount
