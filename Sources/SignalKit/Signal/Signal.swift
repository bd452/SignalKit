import Foundation

@MainActor
public final class Signal<Value> {
    private var value: Value
    private var observers: [UInt64: ObserverEntry] = [:]
    private var nextObserverID: UInt64 = 0
    private var isNotifying = false
    private var pendingValue: Value?
    private var hasPendingNotification = false

    public init(_ value: Value) {
        self.value = value
    }

    public var current: Value {
        value
    }

    public func set(_ newValue: Value) {
        value = newValue
        if isNotifying {
            // Coalesce nested writes during delivery: `current` is always latest,
            // but observers receive at most one follow-up pass with the final value.
            pendingValue = newValue
            hasPendingNotification = true
            return
        }
        deliver(newValue)
    }

    public func setIfChanged(_ newValue: Value) where Value: Equatable {
        guard value != newValue else { return }
        set(newValue)
    }

    public func update(_ transform: (Value) -> Value) {
        set(transform(value))
    }

    public func updateIfChanged(_ transform: (Value) -> Value) where Value: Equatable {
        setIfChanged(transform(value))
    }

    @discardableResult
    public func observe(
        on delivery: ObserverDelivery = .immediate,
        _ handler: @escaping (Value) -> Void
    ) -> any Disposable {
        let id = registerObserver(delivery: delivery, handler: handler)
        return ClosureDisposable { [weak self] in
            self?.removeObserver(id: id)
        }
    }

    private struct ObserverEntry {
        let id: UInt64
        let delivery: ObserverDelivery
        let handler: (Value) -> Void
    }

    private func registerObserver(
        delivery: ObserverDelivery,
        handler: @escaping (Value) -> Void
    ) -> UInt64 {
        let id = nextObserverID
        nextObserverID &+= 1
        observers[id] = ObserverEntry(id: id, delivery: delivery, handler: handler)
        return id
    }

    private func removeObserver(id: UInt64) {
        observers.removeValue(forKey: id)
    }

    private func deliver(_ value: Value) {
        isNotifying = true
        defer {
            isNotifying = false
            if hasPendingNotification, let pendingValue {
                hasPendingNotification = false
                self.pendingValue = nil
                deliver(pendingValue)
            }
        }
        notify(Array(observers.values), with: value)
    }

    private func notify(_ snapshot: [ObserverEntry], with value: Value) {
        for entry in snapshot {
            ObserverScheduler.schedule(entry.delivery) {
                entry.handler(value)
            }
        }
    }
}
