# Example: Nested Components

Compose a screen from child components with shared state passed via constructor injection.

**Concepts:** child components, shared signals, `VStack` composition, automatic lifetime tracking

## Shared model

```swift
struct Product: Equatable {
    let id: String
    let name: String
    let price: Decimal
}

final class CartStore {
    let items = Signal<[Product]>([])
    let total = Signal<Decimal>(0)

    func add(_ product: Product) {
        items.update { $0 + [product] }
        recalculateTotal()
    }

    func remove(at index: Int) {
        items.update { list in
            var copy = list
            guard copy.indices.contains(index) else { return copy }
            copy.remove(at: index)
            return copy
        }
        recalculateTotal()
    }

    private func recalculateTotal() {
        total.set(items.current.reduce(0) { $0 + $1.price })
    }
}
```

## Product row (leaf component)

```swift
final class ProductRow: Component {
    let product: Product
    let onAdd: () -> Void

    init(product: Product, onAdd: @escaping () -> Void) {
        self.product = product
        self.onAdd = onAdd
        super.init()
    }

    override func build() -> Node {
        let nameLabel = UILabel()
        nameLabel.text = product.name
        nameLabel.font = .preferredFont(forTextStyle: .body)

        let priceLabel = UILabel()
        priceLabel.text = "$\(product.price)"
        priceLabel.textColor = .secondaryLabel

        let addButton = UIButton(type: .system)
        addButton.setTitle("Add", for: .normal)

        track(addButton.onTap { [onAdd] in onAdd() })

        return HStack(spacing: 12) {
            nameLabel
            priceLabel
            addButton
        }
    }
}
```

## Cart summary (child component)

```swift
final class CartSummary: Component {
    let store: CartStore

    init(store: CartStore) {
        self.store = store
        super.init()
    }

    override func build() -> Node {
        let titleLabel = UILabel()
        titleLabel.font = .preferredFont(forTextStyle: .headline)
        titleLabel.text = "Cart"

        let countLabel = UILabel()
        let totalLabel = UILabel()
        totalLabel.font = .preferredFont(forTextStyle: .title3)

        bind(countLabel, \.text, store.items) { "Items: \($0.count)" }
        bind(totalLabel, \.text, store.total) { "Total: $\($0)" }

        return VStack(spacing: 8) {
            titleLabel
            countLabel
            totalLabel
        }
    }
}
```

## Product list (child component)

```swift
final class ProductList: Component {
    let store: CartStore
    let products: [Product]

    init(store: CartStore, products: [Product]) {
        self.store = store
        self.products = products
        super.init()
    }

    override func build() -> Node {
        VStack(spacing: 12) {
            for product in products {
                ProductRow(product: product) { [store] in
                    store.add(product)
                }
            }
        }
    }
}
```

## Shop screen (parent)

```swift
final class ShopScreen: Component {
    let store = CartStore()

    private let catalog: [Product] = [
        Product(id: "1", name: "Widget", price: 9.99),
        Product(id: "2", name: "Gadget", price: 24.99),
        Product(id: "3", name: "Gizmo", price: 4.99),
    ]

    override func build() -> Node {
        VStack(spacing: 24) {
            CartSummary(store: store)
            ProductList(store: store, products: catalog)
        }
    }
}
```

## Usage

```swift
let shop = ShopScreen()
view.addSubview(shop.mount())

// Tap "Add" on any product → store.items updates → CartSummary bindings refresh
```

## Lifetime diagram

```text
ShopScreen (parent scope)
  ├── CartSummary (child — tracked, unmounts with parent)
  └── ProductList (child)
        ├── ProductRow (static for-loop children at mount)
        ├── ProductRow
        └── ProductRow
```

When `shop.unmount()`:

```text
  → ShopScreen scope disposes
  → CartSummary.unmount()
  → ProductList.unmount()
  → all ProductRow children unmount
```

## Sharing state

Pass shared objects (stores, signals) via `init`:

```swift
init(store: CartStore) {
    self.store = store
    super.init()
}
```

All children observing `store.total` receive updates when any sibling mutates the store.

## Static vs dynamic children

`ProductList` uses a `for` loop — the catalog is fixed at mount time. For a dynamic catalog loaded from the network, use `ForEach` with a signal:

```swift
ForEach(products, id: \.id) { product in
    ProductRow(product: product) { [store] in store.add(product) }
}
```

## Related

- [Components](../components.md)
- [Nodes & Layout](../nodes-and-layout.md)
