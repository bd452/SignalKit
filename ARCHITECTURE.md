# Architecture Summary

The framework is a UIKit-native component system with signal-driven mutation and one-time structural mounting.

It is not a SwiftUI clone and not a React renderer. UIKit remains the rendering layer. Components provide lifecycle and ownership. Signals provide fine-grained reactive state. Composition is declarative at mount time, but updates are direct UIKit mutations rather than rerenders.

The core shape is:

```text
Component builds once
→ build returns a temporary Node
→ Node mounts into real UIKit views
→ signals update specific UIKit properties
→ structural hosts handle dynamic child replacement/lists
```

---

# Component

A `Component` is a lifecycle object, not a `UIView`.

It owns:

- a lifecycle scope
- tracked subscriptions
- tracked UIKit event handlers
- child component lifetimes
- mounted structural hosts
- teardown behavior

A component’s `build()` function constructs real UIKit objects imperatively, attaches bindings/events, and returns a mountable composition node.

```swift
final class Counter: Component {
    let count = Signal(0)

    override func build() -> Node {
        let label = UILabel()
        let button = UIButton(type: .system)

        bind(label, \.text, count) {
            "Count: \($0)"
        }

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
```

`build()` is not a render function. It is a construction function.

It runs once per mount. Ordinary signal updates do not call `build()` again.

---

# Node

`Node` is a temporary mount description.

It is not a virtual DOM and not a persistent render tree. It exists only during mounting.

A node can represent:

- a real `UIView`
- a child `Component`
- a stack/container composition
- a `Slot`
- a `ForEach`
- a group of nodes

UIKit classes are not wrapped as alternate framework components. A `UILabel` remains a `UILabel`. A `UIButton` remains a `UIButton`.

Composition helpers like `VStack` and `HStack` produce nodes that mount into real UIKit containers, usually `UIStackView`.

```swift
return VStack(spacing: 12) {
    titleLabel
    subtitleLabel
    FooterComponent()
}
```

This means:

```text
create/configure a real UIStackView
insert titleLabel directly
insert subtitleLabel directly
mount FooterComponent as a child
insert its root UIView
track its lifetime in the parent scope
```

---

# UIKit Usage

UIKit construction stays imperative.

Components do not replace UIKit APIs. They organize UIKit objects.

```swift
let imageView = UIImageView()
imageView.contentMode = .scaleAspectFill
imageView.layer.cornerRadius = 12

let label = UILabel()
label.font = .preferredFont(forTextStyle: .headline)
```

Composition is declarative only at the return boundary:

```swift
return HStack(spacing: 8) {
    imageView
    label
}
```

The split is:

```text
Imperative:
  create views
  configure views
  attach bindings
  attach events

Declarative:
  describe how mounted views/components are arranged
```

---

# Signal

A `Signal<Value>` is a main-actor observable value container.

It owns:

- the current value
- an observer registry
- stable observer IDs
- update/set behavior
- observer delivery scheduling

Observers are stored by stable IDs:

```swift
[UInt64: Observer<Value>]
```

not as a `Set` of closures. Swift closures are not `Hashable`, and ID-backed removal gives predictable disposal.

Signals do not know about UIKit, components, views, bindings, or layout.

Core operations:

```swift
signal.set(value)
signal.update { old in new }
signal.observe(on: .main) { value in ... }
```

`set` publishes by default. Equality suppression is opt-in:

```swift
signal.setIfChanged(value)
signal.updateIfChanged { ... }
```

This avoids baking `Equatable` into every signal and preserves the ability to publish repeated equal values intentionally.

---

# Observer Delivery

Signals are main-actor isolated. Reads and writes must happen on the main actor; observers choose delivery policy.

Typical delivery modes:

```swift
.immediate   // run synchronously from the writer's MainActor context
.main        // deliver on the MainActor (async when called off the main thread)
```

Bindings always deliver on the main actor because UI mutation must be main-threaded.

Background work must hop to the main actor before updating a signal:

```swift
Task.detached {
    let user = await loadUser()
    await MainActor.run {
        userSignal.set(user)
    }
}
```

The signal stores the value on the main actor, snapshots observers, and schedules each callback according to its delivery policy. Nested writes during delivery are coalesced: `current` always reflects the latest value, but observers may receive one follow-up notification with the final value rather than every intermediate step.

---

# Binding

A binding connects a signal to a UIKit property mutation.

```swift
bind(label, \.text, count) {
    "Count: \($0)"
}
```

If the signal value already matches the UIKit property type, no transform is needed:

```swift
bind(button, \.isEnabled, canSubmit)
```

The transform belongs at the binding site. Signals do not create derived signal chains for one-off UI transformations.

A binding:

- subscribes to the signal
- delivers on `MainActor`
- checks the component lifecycle scope
- weakly targets the UIKit object
- mutates the property
- disposes automatically on unmount

Conceptually:

```text
signal changes
→ binding callback scheduled on main
→ lifecycle guard passes
→ target view still exists
→ UIKit property mutates
```

---

# Observation

For UIKit mutations that are not simple key-path assignment, components use tracked observation.

```swift
observe(user) { user in
    imageView.image = user.avatar
    nameLabel.text = user.name
}
```

Inside a component, `observe` is lifecycle-tracked by default. It is the general imperative effect API.

The distinction is:

```text
bind(...)
  tracked property assignment

observe(...)
  tracked arbitrary callback

signal.observe(...)
  raw subscription returning a disposable
```

---

# Events

UIKit events are wrapped as disposable registrations.

```swift
track(button.onTap {
    count.update { $0 + 1 }
})
```

An event helper:

- installs the UIKit target/action or gesture recognizer
- returns a disposable
- removes or invalidates the handler on disposal
- is owned by the component lifecycle scope

The flow is:

```text
UIKit event
→ handler runs
→ signal updates
→ observers/bindings run
→ UIKit properties mutate
```

---

# Lifecycle Scope

Every component owns a `LifecycleScope`.

The scope tracks:

- signal observers
- bindings
- UIKit event handlers
- child components
- `Slot` hosts
- `ForEach` hosts
- cleanup closures

Unmounting a component disposes its scope.

Disposal order:

```text
mark scope dead
stop accepting new tracked work
remove event handlers
dispose signal observers
unmount child components / structural hosts
remove views from superviews
release retained closures and targets
```

Every scheduled callback checks whether its owning scope is still alive before running. Late callbacks are dropped. In debug builds, dropped callbacks and invalid lifecycle operations can log warnings.

---

# Mounting

Mounting consumes a component’s `Node` once and produces a real UIKit root view.

```text
component.mount()
→ create lifecycle scope
→ run build()
→ consume returned Node
→ produce UIView root
→ call didMount
```

A mounted component has one root UIKit view, but the component itself is not a view.

Unmounting reverses ownership:

```text
willUnmount
→ dispose scope
→ unmount children
→ remove root view
→ release references
```

---

# Child Components

Child ownership is inferred from declarative composition.

Users should not usually call `mountChild(...)`.

This:

```swift
return VStack {
    HeaderComponent(user)
    bodyView
    FooterComponent()
}
```

automatically means:

```text
HeaderComponent is mounted as a child
FooterComponent is mounted as a child
their root views are inserted into the stack
their lifetimes are tracked by the parent scope
```

A child component can appear in a node composition position, but it is not itself a `UIView`.

For raw UIKit APIs that require a view immediately, the framework may provide an explicit escape hatch:

```swift
ComponentHostView(HeaderComponent(user))
```

But normal composition should not require that.

---

# Slot

`Slot` handles dynamic single-child replacement.

```swift
Slot(isLoggedIn) { loggedIn in
    loggedIn ? ProfileComponent() : LoginComponent()
}
```

A slot owns:

- a placeholder UIKit container
- a subscription to the driving signal
- the currently mounted child (tracked in the lifecycle scope)
- replacement/unmount logic via `trackChild` / `releaseChild`

When the signal changes:

```text
old child released from scope and unmounted
new child mounted and tracked in scope
new child root view replaces old root view
slot container remains stable
```

`Slot` is the structural equivalent of a binding. A binding updates a property; a slot updates a child subtree.

---

# ForEach

`ForEach` handles keyed dynamic collections.

```swift
ForEach(items, id: \.id) { item in
    RowComponent(item)
}
```

It owns:

- a keyed child registry
- item identity tracking
- insert/remove/reorder behavior
- row component lifetimes tracked in the lifecycle scope via `trackChild` / `releaseChild`

For small lists, it can back onto stack mutation.

For serious lists, it should use `UICollectionView` or `UITableView`, with the framework managing signal-backed data, keyed identity, and row/cell component scopes.

`ForEach` is not a generalized rerendering loop. It is a specialized structural host.

When an element's identity is stable, its mounted row component is preserved. Data changes for an existing ID should be handled inside the row component (via signals and bindings), not by remounting the row.

Duplicate IDs in the collection are rejected at runtime via precondition.

---

# Rendering Model

Mounting is structural. Updates are reactive.

Ordinary update flow:

```text
signal.set(...)
→ observers notified
→ bindings/observations run
→ specific UIKit properties mutate
```

No component rerender. No virtual DOM diff. No generalized reconciliation pass.

Structural update flow:

```text
signal changes
→ Slot or ForEach observes change
→ host performs targeted mount/unmount/reorder
```

Only structural hosts change hierarchy shape.

---

# Ownership Boundaries

The final ownership model is:

```text
Signal
  owns value and observer registry

Component
  owns lifecycle and build scope

LifecycleScope
  owns disposables, callbacks, and all child components (static and structural)

Node
  temporary mount description consumed once

UIView
  owns UIKit visual state and behavior

Binding
  connects signal values to UIKit mutations

Slot
  owns one dynamic child position

ForEach
  owns keyed dynamic child positions
```

Signals do not know about UIKit.

UIKit views do not know about components.

Components coordinate lifecycle, composition, and cleanup.

The architecture’s center is:

**UIKit construction, declarative mount composition, signal-driven direct mutation, component-owned lifetime.**
