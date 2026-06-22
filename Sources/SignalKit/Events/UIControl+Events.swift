#if canImport(UIKit)
import UIKit

private final class ControlEventTarget: NSObject {
    let handler: () -> Void

    init(handler: @escaping () -> Void) {
        self.handler = handler
    }

    @objc func invoke() {
        handler()
    }
}

@MainActor
private final class ControlEventRegistration: Disposable {
    private weak var control: UIControl?
    private let target: ControlEventTarget
    private let event: UIControl.Event

    init(control: UIControl, event: UIControl.Event, handler: @escaping () -> Void) {
        self.control = control
        self.event = event
        self.target = ControlEventTarget(handler: handler)
        control.addTarget(target, action: #selector(ControlEventTarget.invoke), for: event)
    }

    func dispose() {
        control?.removeTarget(target, action: #selector(ControlEventTarget.invoke), for: event)
        control = nil
    }
}

extension UIControl {
    public func onTap(_ handler: @escaping () -> Void) -> any Disposable {
        onEvent(.touchUpInside, handler: handler)
    }

    public func onEvent(_ event: UIControl.Event, handler: @escaping () -> Void) -> any Disposable {
        ControlEventRegistration(control: self, event: event, handler: handler)
    }
}
#endif
