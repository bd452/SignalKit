# Example: Counter

The canonical SignalKit example — a label and two buttons driven by a single `Signal<Int>`.

**Concepts:** `Signal`, `bind`, `track`, `onTap`, `VStack`, `HStack`

## Full source

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
        decrement.titleLabel?.font = .preferredFont(forTextStyle: .title1)

        let increment = UIButton(type: .system)
        increment.setTitle("+", for: .normal)
        increment.titleLabel?.font = .preferredFont(forTextStyle: .title1)

        // Signal → UIKit property (with transform)
        bind(label, \.text, count) { "Count: \($0)" }

        // UIKit event → signal update
        track(decrement.onTap { [count] in
            count.update { $0 - 1 }
        })
        track(increment.onTap { [count] in
            count.update { $0 + 1 }
        })

        return VStack(spacing: 24) {
            label
            HStack(spacing: 48) {
                decrement
                increment
            }
        }
    }
}
```

## Mount and use

```swift
let counter = Counter()
let root = counter.mount()
parentView.addSubview(root)

// Programmatic update — label updates without re-running build()
counter.count.set(10)

// Cleanup when done
counter.unmount()
```

## What happens step by step

### On mount

```text
mount()
  → build() creates UILabel + UIButtons
  → bind sets label.text to "Count: 0" and subscribes to count
  → track registers tap handlers on both buttons
  → VStack mounts into a UIStackView
  → didMount() (default, no-op)
```

### On tap "+"

```text
button.onTap fires
  → count.update { $0 + 1 }  // 0 → 1
  → bind callback runs on main actor
  → label.text = "Count: 1"
```

`build()` is **not** called again.

### On unmount

```text
unmount()
  → willUnmount()
  → tap handlers removed from buttons
  → bind observer disposed
  → root UIStackView removed from superview
```

## Variations

### Direct type binding (no transform)

When the signal type matches the property type:

```swift
let isEnabled = Signal(true)
bind(button, \.isEnabled, isEnabled)
```

### Reset button

```swift
let reset = UIButton(type: .system)
reset.setTitle("Reset", for: .normal)

track(reset.onTap { [count] in
    count.set(0)
})
```

## Related

- [Binding & Observation](../binding-and-observation.md)
- [Events](../events.md)
