#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

public struct Node {
    enum Content {
        case view(SKView)
        case component(Component)
        case stack(axis: StackAxis, spacing: CGFloat, alignment: StackAlignment, children: [Node])
        case fragment([Node])
    }

    let content: Content

    init(_ content: Content) {
        self.content = content
    }
}

extension SKView {
    @MainActor
    public var node: Node {
        Node(.view(self))
    }
}

extension Component {
    @MainActor
    public var node: Node {
        Node(.component(self))
    }
}

@resultBuilder
@MainActor
public enum NodeBuilder {
    public static func buildBlock(_ components: Node...) -> Node {
        Node(.fragment(Array(components)))
    }

    public static func buildOptional(_ component: Node?) -> Node {
        component ?? EmptyComponent().node
    }

    public static func buildEither(first component: Node) -> Node {
        component
    }

    public static func buildEither(second component: Node) -> Node {
        component
    }

    public static func buildArray(_ components: [Node]) -> Node {
        ArrayComponent(nodes: components).node
    }

    public static func buildExpression(_ view: SKView) -> Node {
        view.node
    }

    public static func buildExpression(_ component: Component) -> Node {
        component.node
    }

    public static func buildExpression(_ node: Node) -> Node {
        node
    }
}

@MainActor
public func VStack(
    spacing: CGFloat = 0,
    alignment: StackAlignment = .fill,
    @NodeBuilder content: () -> Node
) -> Node {
    let child = content()
    let children = NodeMounter.flattenChildren(child)
    return Node(.stack(axis: .vertical, spacing: spacing, alignment: alignment, children: children))
}

@MainActor
public func HStack(
    spacing: CGFloat = 0,
    alignment: StackAlignment = .fill,
    @NodeBuilder content: () -> Node
) -> Node {
    let child = content()
    let children = NodeMounter.flattenChildren(child)
    return Node(.stack(axis: .horizontal, spacing: spacing, alignment: alignment, children: children))
}

@MainActor
enum NodeMounter {
    static func flattenChildren(_ node: Node) -> [Node] {
        switch node.content {
        case .fragment(let children):
            return children.flatMap { flattenChildren($0) }
        case .component(let component as ArrayComponent):
            return component.nodes.flatMap { flattenChildren($0) }
        default:
            return [node]
        }
    }

    static func mount(_ node: Node, scope: LifecycleScope, parent: Component) -> SKView {
        switch node.content {
        case .view(let view):
            return view

        case .component(let component):
            scope.trackChild(component)
            return component.mount()

        case .stack(let axis, let spacing, let alignment, let children):
            let stack = SKStack.make(axis: axis, spacing: spacing, alignment: alignment)
            for child in children {
                let childView = mount(child, scope: scope, parent: parent)
                SKStack.addArrangedSubview(stack, childView)
            }
            return stack

        case .fragment:
            preconditionFailure(
                "Multiple root nodes must be wrapped in VStack { } or HStack { }"
            )
        }
    }
}
