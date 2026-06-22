# Architecture Overview

This document explains SignalKit's mental model. For API details, see the topic-specific guides linked from [README](README.md).

## Design principles

SignalKit is built around four ideas:

1. **UIKit construction** — views are real `UILabel`, `UIButton`, `UIStackView` instances, configured with standard UIKit APIs.
2. **Declarative mount composition** — `VStack`, `HStack`, child components, `Slot`, and `ForEach` describe structure at mount time.
3. **Signal-driven direct mutation** — state changes update specific UIKit properties; there is no rerender.
4. **Component-owned lifetime** — every subscription, binding, event handler, and child is tracked and disposed on unmount.

## The update model

### Ordinary updates (no structural change)

```text
signal.set(newValue)
  → observers notified
  → bindings / observations run
  → specific UIKit properties mutate
```

`build()` is **not** called. No virtual DOM diff runs.

### Structural updates

```text
signal changes
  → Slot or ForEach observes the change
  → host performs targeted mount / unmount / reorder
```

Only structural hosts change hierarchy shape. Everything else is property-level mutation.

## Core types and ownership

```text
Signal
  owns: current value, observer registry

Component
  owns: lifecycle scope, build logic

LifecycleScope
  owns: disposables, child components, cleanup closures

Node
  owns: nothing persistent — consumed once during mount

UIView / NSView
  owns: visual state and UIKit behavior

Binding (via Component.bind)
  connects: signal values → UIKit key path mutations

Slot
  owns: one dynamic child position

ForEach
  owns: keyed dynamic child positions
```

**Signals do not know about UIKit.**  
**UIKit views do not know about components.**  
**Components coordinate lifecycle, composition, and cleanup.**

## Mounting flow

```text
component.mount()
  → create LifecycleScope
  → run build()
  → consume returned Node
  → produce UIView root
  → call didMount()
```

A mounted component has one root `SKView`, but the component itself is not a view.

## Unmounting flow

```text
component.unmount()
  → call willUnmount()
  → mark scope dead
  → dispose signal observers and event handlers
  → unmount child components / structural hosts
  → remove root view from superview
  → release references
```

Disposal order inside `LifecycleScope.dispose()`:

1. Mark scope as dead (late callbacks are dropped)
2. Dispose all tracked disposables (observers, bindings, events)
3. Unmount all tracked child components
4. Run cleanup closures

## Node: temporary mount description

`Node` is not a virtual DOM node. It exists only during mounting and represents one of:

| Node content | Mount behavior |
| --- | --- |
| `SKView` | Returned as-is |
| `Component` | Child is mounted; root view returned |
| Stack (`VStack` / `HStack`) | Creates `UIStackView` / `NSStackView`, mounts children |
| Fragment | Must be wrapped in a stack at the root level |

UIKit types are never wrapped. A `UILabel` in a node is a real `UILabel`.

## Component vs view

| | `Component` | `UIView` |
| --- | --- | --- |
| Purpose | Lifecycle, state, composition | Visual rendering |
| Instantiation | `Counter()` | `UILabel()` inside `build()` |
| Mounting | `mount()` → root view | Added to hierarchy directly |
| Updates | Via signals → bindings | Direct property mutation |
| `build()` | Runs once per mount | N/A |

## Binding vs observation vs raw observe

| API | Lifecycle tracked | Delivery | Use case |
| --- | --- | --- | --- |
| `bind(target, keyPath, signal)` | Yes | Main actor | Single UIKit property assignment |
| `observe(signal, handler)` | Yes | Main actor | Arbitrary UIKit mutations |
| `signal.observe(handler)` | No (manual dispose) | Configurable | Non-UI logic, tests, manual lifetime |

## Structural hosts

### Slot

Replaces a single child component when a driving signal changes. The slot container view remains stable; only the child subtree swaps.

```swift
Slot(isLoggedIn) { loggedIn in
    loggedIn ? ProfileComponent() : LoginComponent()
}
```

### ForEach

Manages a keyed collection of child components. Stable IDs preserve mounted row components across data updates. Inserts, removes, and reorders views in a vertical stack.

```swift
ForEach(items, id: \.id) { item in
    RowComponent(item)
}
```

Duplicate IDs trigger a runtime precondition failure.

## Threading model

All `Signal` and `Component` APIs are `@MainActor` isolated. Signal reads and writes must happen on the main actor.

Background work must hop to the main actor before updating signals:

```swift
Task.detached {
    let user = await loadUser()
    await MainActor.run {
        userSignal.set(user)
    }
}
```

Bindings and component `observe` always deliver on the main actor.

## Comparison with other approaches

| | SignalKit | SwiftUI | React |
| --- | --- | --- | --- |
| Rendering | UIKit directly | SwiftUI renderer | Virtual DOM → DOM |
| Update model | Property mutation | View invalidation | Reconciliation |
| `build()` / render | Once per mount | On state change | On state change |
| View types | Real UIKit classes | SwiftUI views | DOM elements |
| State | `Signal<Value>` | `@State`, `@Observable` | `useState`, etc. |

SignalKit targets teams that want UIKit-native construction with organized lifecycle and fine-grained reactive updates — without adopting a full declarative UI framework.

## Debug diagnostics

In debug builds, SignalKit logs:

- Dropped late callbacks when a scope is already disposed
- Invalid lifecycle operations (e.g., `track` on a dead scope)

Look for `[SignalKit]` prefixed messages in the console.
