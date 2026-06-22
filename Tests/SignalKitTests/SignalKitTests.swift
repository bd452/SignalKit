import Testing
@testable import SignalKit

@Test @MainActor
func signalSetNotifiesObservers() {
    let signal = Signal(0)
    var received: [Int] = []
    let disposable = signal.observe { received.append($0) }

    signal.set(1)
    signal.set(2)
    disposable.dispose()
    signal.set(3)

    #expect(received == [1, 2])
}

@Test @MainActor
func signalSetIfChangedSuppressesEqualValues() {
    let signal = Signal(0)
    var count = 0
    _ = signal.observe { _ in count += 1 }

    signal.setIfChanged(0)
    signal.setIfChanged(1)
    signal.setIfChanged(1)

    #expect(count == 1)
}

@Test @MainActor
func signalDeliversOnMainQueue() async {
    let signal = Signal(0)
    var receivedOnMain = false
    _ = signal.observe(on: .main) { _ in
        receivedOnMain = Thread.isMainThread
    }

    await Task.detached {
        await MainActor.run {
            signal.set(1)
        }
    }.value

    try? await Task.sleep(nanoseconds: 50_000_000)
    #expect(receivedOnMain)
}

@Test @MainActor
func signalCoalescesNestedWritesDuringDelivery() {
    let signal = Signal(0)
    var received: [Int] = []
    _ = signal.observe(on: .immediate) { value in
        received.append(value)
        if value == 1 {
            signal.set(2)
            signal.set(3)
        }
    }

    signal.set(1)

    #expect(signal.current == 3)
    #expect(received == [1, 3])
}

#if canImport(UIKit)
import UIKit

@Suite(.serialized)
@MainActor
struct ComponentTests {
    @Test
    func counterComponentBindsAndIncrements() {
        final class Counter: Component {
            let count = Signal(0)

            override func build() -> Node {
                let label = UILabel()
                let button = UIButton(type: .system)

                bind(label, \.text, count) { "Count: \($0)" }
                button.setTitle("Increment", for: .normal)
                track(button.onTap { [count] in
                    count.update { $0 + 1 }
                })

                return VStack(spacing: 12) {
                    label
                    button
                }
            }
        }

        let counter = Counter()
        let root = counter.mount()

        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        window.rootViewController = UIViewController()
        window.makeKeyAndVisible()
        window.rootViewController!.view.addSubview(root)

        let stack = root as! UIStackView
        let label = stack.arrangedSubviews[0] as! UILabel
        let button = stack.arrangedSubviews[1] as! UIButton

        #expect(label.text == "Count: 0")

        counter.count.set(1)
        #expect(label.text == "Count: 1")

        if let target = button.allTargets.first {
            let selector = NSSelectorFromString("invoke")
            if (target as AnyObject).responds(to: selector) {
                _ = (target as AnyObject).perform(selector)
            }
        }
        #expect(label.text == "Count: 2")

        counter.unmount()
        #expect(counter.rootView == nil)
    }

    @Test
    func slotReleasesChildOnReplace() {
        final class UnmountFlag {
            var count = 0
        }

        final class LabelComponent: Component {
            let flag: UnmountFlag
            let text: String
            init(flag: UnmountFlag, _ text: String) {
                self.flag = flag
                self.text = text
            }
            override func build() -> Node {
                let label = UILabel()
                label.text = text
                return label.node
            }
            override func willUnmount() {
                flag.count += 1
            }
        }

        final class Host: Component {
            let flag = UnmountFlag()
            let isLoggedIn = Signal(false)
            override func build() -> Node {
                Slot(isLoggedIn) { [flag] loggedIn in
                    LabelComponent(flag: flag, loggedIn ? "Profile" : "Login")
                }
            }
        }

        let host = Host()
        _ = host.mount()
        #expect(host.flag.count == 0)

        host.isLoggedIn.set(true)
        #expect(host.flag.count == 1)

        host.unmount()
    }

    @Test
    func slotReplacesChildComponent() {
        final class LabelComponent: Component {
            let text: String
            init(_ text: String) { self.text = text }
            override func build() -> Node {
                let label = UILabel()
                label.text = text
                return label.node
            }
        }

        final class Host: Component {
            let isLoggedIn = Signal(false)
            override func build() -> Node {
                Slot(isLoggedIn) { loggedIn in
                    loggedIn ? LabelComponent("Profile") : LabelComponent("Login")
                }
            }
        }

        let host = Host()
        _ = host.mount()
        let slotContainer = host.rootView!
        #expect((slotContainer.subviews.first as? UILabel)?.text == "Login")

        host.isLoggedIn.set(true)
        #expect((slotContainer.subviews.first as? UILabel)?.text == "Profile")

        host.isLoggedIn.set(false)
        #expect((slotContainer.subviews.first as? UILabel)?.text == "Login")

        host.unmount()
    }

    @Test
    func forEachInsertsRemovesAndReorders() {
        struct Item: Equatable {
            let id: Int
            let title: String
        }

        final class Row: Component {
            let title: String
            init(_ title: String) { self.title = title }
            override func build() -> Node {
                let label = UILabel()
                label.text = title
                return label.node
            }
        }

        final class ListHost: Component {
            let items = Signal<[Item]>([])
            override func build() -> Node {
                ForEach(items, id: \.id) { item in
                    Row(item.title)
                }
            }
        }

        let host = ListHost()
        _ = host.mount()
        let stack = host.rootView as! UIStackView

        host.items.set([Item(id: 1, title: "A"), Item(id: 2, title: "B")])
        #expect(stack.arrangedSubviews.count == 2)
        #expect((stack.arrangedSubviews[0] as! UILabel).text == "A")
        #expect((stack.arrangedSubviews[1] as! UILabel).text == "B")

        host.items.set([Item(id: 2, title: "B"), Item(id: 3, title: "C")])
        #expect(stack.arrangedSubviews.count == 2)
        #expect((stack.arrangedSubviews[0] as! UILabel).text == "B")
        #expect((stack.arrangedSubviews[1] as! UILabel).text == "C")

        host.unmount()
    }

    @Test
    func forEachReordersExistingRows() {
        struct Item: Equatable {
            let id: Int
            let title: String
        }

        final class Row: Component {
            let title: String
            init(_ title: String) { self.title = title }
            override func build() -> Node {
                let label = UILabel()
                label.text = title
                return label.node
            }
        }

        final class ListHost: Component {
            let items = Signal<[Item]>([
                Item(id: 1, title: "A"),
                Item(id: 2, title: "B"),
                Item(id: 3, title: "C"),
            ])
            override func build() -> Node {
                ForEach(items, id: \.id) { item in
                    Row(item.title)
                }
            }
        }

        let host = ListHost()
        _ = host.mount()
        let stack = host.rootView as! UIStackView

        host.items.set([
            Item(id: 3, title: "C"),
            Item(id: 1, title: "A"),
            Item(id: 2, title: "B"),
        ])

        #expect(stack.arrangedSubviews.count == 3)
        #expect((stack.arrangedSubviews[0] as! UILabel).text == "C")
        #expect((stack.arrangedSubviews[1] as! UILabel).text == "A")
        #expect((stack.arrangedSubviews[2] as! UILabel).text == "B")

        host.unmount()
    }

    @Test
    func forEachPreservesRowWhenIDIsStable() {
        struct Item: Equatable {
            let id: Int
            let title: String
        }

        final class Row: Component {
            let title: String
            init(_ title: String) { self.title = title }
            override func build() -> Node {
                let label = UILabel()
                label.text = title
                return label.node
            }
        }

        final class ListHost: Component {
            let items = Signal<[Item]>([Item(id: 1, title: "A")])
            override func build() -> Node {
                ForEach(items, id: \.id) { item in
                    Row(item.title)
                }
            }
        }

        let host = ListHost()
        _ = host.mount()
        let stack = host.rootView as! UIStackView

        host.items.set([Item(id: 1, title: "B")])

        #expect((stack.arrangedSubviews[0] as! UILabel).text == "A")

        host.unmount()
    }

    @Test
    func childComponentsUnmountWithParent() {
        final class Child: Component {
            var didUnmount = false
            override func build() -> Node {
                UILabel().node
            }
            override func willUnmount() {
                didUnmount = true
            }
        }

        final class Parent: Component {
            let child = Child()
            override func build() -> Node {
                VStack { child }
            }
        }

        let parent = Parent()
        parent.mount()
        parent.unmount()
        #expect(parent.child.didUnmount)
    }

    @Test
    func observeStopsAfterUnmount() {
        final class Host: Component {
            let value = Signal(0)
            var observationCount = 0
            override func build() -> Node {
                observe(value) { [self] _ in
                    observationCount += 1
                }
                return UILabel().node
            }
        }

        let host = Host()
        host.mount()
        #expect(host.observationCount == 1)

        host.value.set(1)
        #expect(host.observationCount == 2)

        host.unmount()
        host.value.set(2)
        #expect(host.observationCount == 2)
    }

    @Test
    func hostViewUnmountsChildOnDeinit() {
        final class UnmountFlag {
            var didUnmount = false
        }

        final class Child: Component {
            let flag: UnmountFlag
            init(flag: UnmountFlag) { self.flag = flag }
            override func build() -> Node {
                UILabel().node
            }
            override func willUnmount() {
                flag.didUnmount = true
            }
        }

        let flag = UnmountFlag()
        var hostView: ComponentHostView? = ComponentHostView(component: Child(flag: flag))
        hostView = nil

        #expect(flag.didUnmount)
    }

    @Test
    func vStackFlattensForLoopWithStaticSibling() {
        final class Row: Component {
            let title: String
            init(_ title: String) { self.title = title }
            override func build() -> Node {
                let label = UILabel()
                label.text = title
                return label.node
            }
        }

        final class Host: Component {
            let titles = ["A", "B"]
            override func build() -> Node {
                VStack(spacing: 4) {
                    Row("Header")
                    for title in titles {
                        Row(title)
                    }
                }
            }
        }

        let host = Host()
        let root = host.mount()
        let stack = root as! UIStackView
        #expect(stack.arrangedSubviews.count == 3)
        #expect((stack.arrangedSubviews[0] as! UILabel).text == "Header")
        #expect((stack.arrangedSubviews[1] as! UILabel).text == "A")
        #expect((stack.arrangedSubviews[2] as! UILabel).text == "B")
        host.unmount()
    }

    @Test
    func hStackFlattensForLoopWithStaticSibling() {
        final class Row: Component {
            let title: String
            init(_ title: String) { self.title = title }
            override func build() -> Node {
                let label = UILabel()
                label.text = title
                return label.node
            }
        }

        final class Host: Component {
            let titles = ["A", "B"]
            override func build() -> Node {
                HStack(spacing: 4) {
                    Row("Header")
                    for title in titles {
                        Row(title)
                    }
                }
            }
        }

        let host = Host()
        let root = host.mount()
        let stack = root as! UIStackView
        #expect(stack.arrangedSubviews.count == 3)
        #expect((stack.arrangedSubviews[0] as! UILabel).text == "Header")
        #expect((stack.arrangedSubviews[1] as! UILabel).text == "A")
        #expect((stack.arrangedSubviews[2] as! UILabel).text == "B")
        host.unmount()
    }

    @Test
    func slotChildCanUseForLoopInVStack() {
        final class Row: Component {
            let title: String
            init(_ title: String) { self.title = title }
            override func build() -> Node {
                let label = UILabel()
                label.text = title
                return label.node
            }
        }

        final class ListSection: Component {
            let titles: [String]
            init(_ titles: [String]) { self.titles = titles }
            override func build() -> Node {
                VStack(spacing: 4) {
                    Row("Header")
                    for title in titles {
                        Row(title)
                    }
                }
            }
        }

        final class Host: Component {
            let titles = Signal<[String]?>(nil)
            override func build() -> Node {
                Slot(titles) { titles in
                    if let titles {
                        ListSection(titles)
                    } else {
                        EmptyComponent()
                    }
                }
            }
        }

        let host = Host()
        _ = host.mount()

        host.titles.set(["A", "B"])
        let slotContainer = host.rootView!
        let stack = slotContainer.subviews.first as! UIStackView
        #expect(stack.arrangedSubviews.count == 3)

        host.unmount()
    }
}
#endif

#if canImport(AppKit) && !canImport(UIKit)
import AppKit

@Suite(.serialized)
@MainActor
struct MacComponentTests {
    @Test
    func vStackFlattensForLoopWithStaticSibling() {
        final class Row: Component {
            let title: String
            init(_ title: String) { self.title = title }
            override func build() -> Node {
                NSTextField(labelWithString: title).node
            }
        }

        final class Host: Component {
            let titles = ["A", "B"]
            override func build() -> Node {
                VStack(spacing: 4) {
                    Row("Header")
                    for title in titles {
                        Row(title)
                    }
                }
            }
        }

        let host = Host()
        let root = host.mount()
        let stack = root as! NSStackView
        #expect(stack.arrangedSubviews.count == 3)
        #expect((stack.arrangedSubviews[0] as! NSTextField).stringValue == "Header")
        #expect((stack.arrangedSubviews[1] as! NSTextField).stringValue == "A")
        #expect((stack.arrangedSubviews[2] as! NSTextField).stringValue == "B")
        host.unmount()
    }

    @Test
    func hStackFlattensForLoopWithStaticSibling() {
        final class Row: Component {
            let title: String
            init(_ title: String) { self.title = title }
            override func build() -> Node {
                NSTextField(labelWithString: title).node
            }
        }

        final class Host: Component {
            let titles = ["A", "B"]
            override func build() -> Node {
                HStack(spacing: 4) {
                    Row("Header")
                    for title in titles {
                        Row(title)
                    }
                }
            }
        }

        let host = Host()
        let root = host.mount()
        let stack = root as! NSStackView
        #expect(stack.arrangedSubviews.count == 3)
        #expect((stack.arrangedSubviews[0] as! NSTextField).stringValue == "Header")
        #expect((stack.arrangedSubviews[1] as! NSTextField).stringValue == "A")
        #expect((stack.arrangedSubviews[2] as! NSTextField).stringValue == "B")
        host.unmount()
    }

    @Test
    func slotChildCanUseForLoopInVStack() {
        final class Row: Component {
            let title: String
            init(_ title: String) { self.title = title }
            override func build() -> Node {
                NSTextField(labelWithString: title).node
            }
        }

        final class ListSection: Component {
            let titles: [String]
            init(_ titles: [String]) { self.titles = titles }
            override func build() -> Node {
                VStack(spacing: 4) {
                    Row("Header")
                    for title in titles {
                        Row(title)
                    }
                }
            }
        }

        final class Host: Component {
            let titles = Signal<[String]?>(nil)
            override func build() -> Node {
                Slot(titles) { titles in
                    if let titles {
                        ListSection(titles)
                    } else {
                        EmptyComponent()
                    }
                }
            }
        }

        let host = Host()
        _ = host.mount()

        host.titles.set(["A", "B"])
        let slotContainer = host.rootView!
        let stack = slotContainer.subviews.first as! NSStackView
        #expect(stack.arrangedSubviews.count == 3)

        host.unmount()
    }

    @Test
    func mountsVerticalStackOnMacOS() {
        final class Host: Component {
            override func build() -> Node {
                let label = NSTextField(labelWithString: "Hello")
                return VStack(spacing: 8) {
                    label
                }
            }
        }

        let host = Host()
        let root = host.mount()
        #expect(root is NSStackView)
        host.unmount()
    }
}
#endif
