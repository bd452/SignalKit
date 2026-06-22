#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

@MainActor
public func ForEach<Data, ID, Content>(
    _ data: Signal<Data>,
    id keyPath: KeyPath<Data.Element, ID>,
    content: @escaping (Data.Element) -> Content
) -> Node where Data: RandomAccessCollection, ID: Hashable, Content: Component {
    ForEachComponent(data: data, id: keyPath, content: content).node
}

@MainActor
final class ForEachComponent<Data, ID, Content>: Component where
    Data: RandomAccessCollection,
    ID: Hashable,
    Content: Component
{
    private let data: Signal<Data>
    private let idKeyPath: KeyPath<Data.Element, ID>
    private let content: (Data.Element) -> Content
    #if canImport(UIKit)
    private let stack = UIStackView()
    #elseif canImport(AppKit)
    private let stack = NSStackView()
    #endif
    private var mountedChildren: [AnyHashable: Component] = [:]
    private var orderedIDs: [AnyHashable] = []

    init(
        data: Signal<Data>,
        id keyPath: KeyPath<Data.Element, ID>,
        content: @escaping (Data.Element) -> Content
    ) {
        self.data = data
        self.idKeyPath = keyPath
        self.content = content
        super.init()
    }

    override func build() -> Node {
        SKStack.configure(stack, axis: .vertical, spacing: 0, alignment: .fill)
        apply(data.current)
        let disposable = data.observe(on: .main) { [weak self] collection in
            guard let self else { return }
            self.scope?.guardAlive(owner: "ForEachComponent") {
                self.apply(collection)
            }
        }
        track(disposable)
        return stack.node
    }

    override func willUnmount() {
        mountedChildren.removeAll()
        orderedIDs.removeAll()
        super.willUnmount()
    }

    private func apply(_ data: Data) {
        var newIDs: [AnyHashable] = []
        var newElements: [AnyHashable: Data.Element] = [:]

        for element in data {
            let identity = AnyHashable(element[keyPath: idKeyPath])
            newIDs.append(identity)
            newElements[identity] = element
        }

        precondition(
            newIDs.count == Set(newIDs).count,
            "ForEach data contains duplicate IDs; each element must have a unique identity"
        )

        let oldIDSet = Set(orderedIDs)
        let newIDSet = Set(newIDs)

        for removedID in oldIDSet.subtracting(newIDSet) {
            if let child = mountedChildren.removeValue(forKey: removedID) {
                releaseChild(child)
                if let view = child.rootView {
                    SKStack.removeArrangedSubview(stack, view)
                    view.removeFromSuperview()
                }
            }
        }

        for identity in newIDs {
            guard mountedChildren[identity] == nil, let element = newElements[identity] else { continue }
            let newComponent = content(element)
            _ = newComponent.mount()
            trackChild(newComponent)
            mountedChildren[identity] = newComponent
            if let view = newComponent.rootView {
                SKStack.addArrangedSubview(stack, view)
            }
        }

        syncViewOrder(newIDs)
        orderedIDs = newIDs
    }

    private func syncViewOrder(_ newIDs: [AnyHashable]) {
        let arrangedSubviews = SKStack.arrangedSubviews(of: stack)
        for (targetIndex, identity) in newIDs.enumerated() {
            guard let view = mountedChildren[identity]?.rootView else { continue }

            if !arrangedSubviews.contains(view) {
                SKStack.insertArrangedSubview(
                    stack,
                    view,
                    at: min(targetIndex, SKStack.arrangedSubviews(of: stack).count)
                )
                continue
            }

            guard let currentIndex = SKStack.arrangedSubviews(of: stack).firstIndex(of: view),
                  currentIndex != targetIndex else { continue }

            SKStack.removeArrangedSubview(stack, view)
            SKStack.insertArrangedSubview(stack, view, at: targetIndex)
        }
    }
}
