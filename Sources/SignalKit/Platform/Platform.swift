import Foundation

public enum StackAxis: Sendable {
    case horizontal
    case vertical
}

#if canImport(UIKit)
import UIKit

public typealias SKView = UIView

public enum StackAlignment: Sendable {
    case fill
    case leading
    case center
    case trailing
    case top
    case bottom
    case firstBaseline
    case lastBaseline

    var uiKitValue: UIStackView.Alignment {
        switch self {
        case .fill: .fill
        case .leading: .leading
        case .center: .center
        case .trailing: .trailing
        case .top: .top
        case .bottom: .bottom
        case .firstBaseline: .firstBaseline
        case .lastBaseline: .lastBaseline
        }
    }
}

@MainActor
enum SKStack {
    static func make(
        axis: StackAxis,
        spacing: CGFloat,
        alignment: StackAlignment
    ) -> UIStackView {
        let stack = UIStackView()
        stack.axis = axis == .vertical ? .vertical : .horizontal
        stack.spacing = spacing
        stack.alignment = alignment.uiKitValue
        return stack
    }

    static func configure(
        _ stack: UIStackView,
        axis: StackAxis,
        spacing: CGFloat,
        alignment: StackAlignment
    ) {
        stack.axis = axis == .vertical ? .vertical : .horizontal
        stack.spacing = spacing
        stack.alignment = alignment.uiKitValue
    }

    static func arrangedSubviews(of stack: UIStackView) -> [SKView] {
        stack.arrangedSubviews
    }

    static func addArrangedSubview(_ stack: UIStackView, _ view: SKView) {
        stack.addArrangedSubview(view)
    }

    static func removeArrangedSubview(_ stack: UIStackView, _ view: SKView) {
        stack.removeArrangedSubview(view)
    }

    static func insertArrangedSubview(_ stack: UIStackView, _ view: SKView, at index: Int) {
        stack.insertArrangedSubview(view, at: index)
    }
}

#elseif canImport(AppKit)
import AppKit

public typealias SKView = NSView

public enum StackAlignment: Sendable {
    case fill
    case leading
    case center
    case trailing
    case top
    case bottom
    case firstBaseline
    case lastBaseline

    var appKitAlignment: NSLayoutConstraint.Attribute {
        switch self {
        case .fill, .firstBaseline, .lastBaseline: .leading
        case .leading, .top: .leading
        case .center: .centerX
        case .trailing, .bottom: .trailing
        }
    }

    var appKitDistribution: NSStackView.Distribution {
        switch self {
        case .fill: .fill
        default: .gravityAreas
        }
    }
}

@MainActor
enum SKStack {
    static func make(
        axis: StackAxis,
        spacing: CGFloat,
        alignment: StackAlignment
    ) -> NSStackView {
        let stack = NSStackView()
        stack.orientation = axis == .vertical ? .vertical : .horizontal
        stack.spacing = spacing
        stack.alignment = alignment.appKitAlignment
        stack.distribution = alignment.appKitDistribution
        return stack
    }

    static func configure(
        _ stack: NSStackView,
        axis: StackAxis,
        spacing: CGFloat,
        alignment: StackAlignment
    ) {
        stack.orientation = axis == .vertical ? .vertical : .horizontal
        stack.spacing = spacing
        stack.alignment = alignment.appKitAlignment
        stack.distribution = alignment.appKitDistribution
    }

    static func arrangedSubviews(of stack: NSStackView) -> [SKView] {
        stack.arrangedSubviews
    }

    static func addArrangedSubview(_ stack: NSStackView, _ view: SKView) {
        stack.addArrangedSubview(view)
    }

    static func removeArrangedSubview(_ stack: NSStackView, _ view: SKView) {
        stack.removeArrangedSubview(view)
    }

    static func insertArrangedSubview(_ stack: NSStackView, _ view: SKView, at index: Int) {
        stack.insertArrangedSubview(view, at: index)
    }
}
#endif
