#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

@MainActor
public func Slot<Value>(
    _ signal: Signal<Value>,
    content: @escaping (Value) -> Component
) -> Node {
    SlotComponent(signal: signal, content: content).node
}

@MainActor
final class SlotComponent<Value>: Component {
    private let signal: Signal<Value>
    private let content: (Value) -> Component
    private let container = SKView()
    private var currentChild: Component?

    init(signal: Signal<Value>, content: @escaping (Value) -> Component) {
        self.signal = signal
        self.content = content
        super.init()
    }

    override func build() -> Node {
        mountChild(content(signal.current))
        let disposable = signal.observe(on: .main) { [weak self] value in
            guard let self else { return }
            self.scope?.guardAlive(owner: "SlotComponent") {
                self.replaceChild(self.content(value))
            }
        }
        track(disposable)
        return container.node
    }

    override func willUnmount() {
        currentChild = nil
        super.willUnmount()
    }

    private func mountChild(_ component: Component) {
        let view = component.mount()
        view.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(view)
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: container.topAnchor),
            view.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])
        trackChild(component)
        currentChild = component
    }

    private func replaceChild(_ component: Component) {
        if let currentChild {
            releaseChild(currentChild)
        }
        currentChild = nil
        container.subviews.forEach { $0.removeFromSuperview() }
        mountChild(component)
    }
}
