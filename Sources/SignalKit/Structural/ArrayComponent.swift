@MainActor
final class EmptyComponent: Component {
    override func build() -> Node {
        SKView().node
    }
}

@MainActor
final class ArrayComponent: Component {
    let nodes: [Node]

    init(nodes: [Node]) {
        self.nodes = nodes
        super.init()
    }

    override func build() -> Node {
        preconditionFailure("ArrayComponent must be used inside VStack or HStack")
    }
}
