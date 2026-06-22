import Foundation

public enum ObserverDelivery: Sendable {
    case immediate
    case main
}

@MainActor
enum ObserverScheduler {
    static func schedule(_ delivery: ObserverDelivery, _ work: @MainActor @escaping () -> Void) {
        switch delivery {
        case .immediate:
            work()
        case .main:
            if Thread.isMainThread {
                MainActor.assumeIsolated {
                    work()
                }
            } else {
                DispatchQueue.main.async {
                    MainActor.assumeIsolated {
                        work()
                    }
                }
            }
        }
    }
}
