# Example: Async Data Loading

Fetch data on a background task, update signals on the main actor, and show loading/error/content states with `Slot`.

**Concepts:** `Slot`, loading states, `MainActor`, `observe`, threading

## Models

```swift
struct Article: Equatable {
    let id: String
    let title: String
    let body: String
}

enum LoadState<T: Equatable>: Equatable {
    case idle
    case loading
    case loaded(T)
    case failed(String)
}
```

## API (stand-in)

```swift
enum ArticleAPI {
    static func fetch(id: String) async throws -> Article {
        try await Task.sleep(nanoseconds: 1_000_000_000)
        return Article(
            id: id,
            title: "SignalKit Overview",
            body: "UIKit construction, declarative mount composition..."
        )
    }
}
```

## Article detail component

```swift
final class ArticleDetail: Component {
    let article: Article

    init(article: Article) {
        self.article = article
        super.init()
    }

    override func build() -> Node {
        let titleLabel = UILabel()
        titleLabel.font = .preferredFont(forTextStyle: .title1)
        titleLabel.numberOfLines = 0
        titleLabel.text = article.title

        let bodyLabel = UILabel()
        bodyLabel.font = .preferredFont(forTextStyle: .body)
        bodyLabel.numberOfLines = 0
        bodyLabel.text = article.body

        return VStack(spacing: 16) {
            titleLabel
            bodyLabel
        }
    }
}
```

## Loading and error components

```swift
final class LoadingIndicator: Component {
    override func build() -> Node {
        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.startAnimating()
        return spinner.node
    }
}

final class ErrorView: Component {
    let message: String
    let onRetry: () -> Void

    init(message: String, onRetry: @escaping () -> Void) {
        self.message = message
        self.onRetry = onRetry
        super.init()
    }

    override func build() -> Node {
        let label = UILabel()
        label.text = message
        label.textColor = .systemRed
        label.textAlignment = .center
        label.numberOfLines = 0

        let button = UIButton(type: .system)
        button.setTitle("Retry", for: .normal)

        track(button.onTap { [onRetry] in onRetry() })

        return VStack(spacing: 12) {
            label
            button
        }
    }
}
```

## Article screen with async load

```swift
final class ArticleScreen: Component {
    let articleId: String
    let state = Signal<LoadState<Article>>(.idle)

    init(articleId: String) {
        self.articleId = articleId
        super.init()
    }

    override func build() -> Node {
        return Slot(state) { [weak self] loadState in
            switch loadState {
            case .idle, .loading:
                return LoadingIndicator()

            case .loaded(let article):
                return ArticleDetail(article: article)

            case .failed(let message):
                return ErrorView(message: message) { [weak self] in
                    self?.load()
                }
            }
        }
    }

    override func didMount() {
        load()
    }

    private func load() {
        state.set(.loading)

        Task {
            do {
                let article = try await ArticleAPI.fetch(id: articleId)
                await MainActor.run {
                    state.set(.loaded(article))
                }
            } catch {
                await MainActor.run {
                    state.set(.failed(error.localizedDescription))
                }
            }
        }
    }
}
```

## Simpler pattern without Slot

If you prefer a single component with `observe` instead of swapping children:

```swift
final class ArticleScreenSimple: Component {
    let articleId: String
    let state = Signal<LoadState<Article>>(.idle)

    override func build() -> Node {
        let spinner = UIActivityIndicatorView(style: .medium)
        let titleLabel = UILabel()
        titleLabel.font = .preferredFont(forTextStyle: .title1)
        titleLabel.numberOfLines = 0

        let bodyLabel = UILabel()
        bodyLabel.font = .preferredFont(forTextStyle: .body)
        bodyLabel.numberOfLines = 0

        let errorLabel = UILabel()
        errorLabel.textColor = .systemRed
        errorLabel.numberOfLines = 0

        let retryButton = UIButton(type: .system)
        retryButton.setTitle("Retry", for: .normal)

        observe(state) { loadState in
            switch loadState {
            case .idle, .loading:
                spinner.startAnimating()
                spinner.isHidden = false
                titleLabel.isHidden = true
                bodyLabel.isHidden = true
                errorLabel.isHidden = true
                retryButton.isHidden = true

            case .loaded(let article):
                spinner.stopAnimating()
                spinner.isHidden = true
                titleLabel.text = article.title
                bodyLabel.text = article.body
                titleLabel.isHidden = false
                bodyLabel.isHidden = false
                errorLabel.isHidden = true
                retryButton.isHidden = true

            case .failed(let message):
                spinner.stopAnimating()
                spinner.isHidden = true
                titleLabel.isHidden = true
                bodyLabel.isHidden = true
                errorLabel.text = message
                errorLabel.isHidden = false
                retryButton.isHidden = false
            }
        }

        track(retryButton.onTap { [weak self] in
            self?.load()
        })

        return VStack(spacing: 16) {
            spinner
            titleLabel
            bodyLabel
            errorLabel
            retryButton
        }
    }

    override func didMount() {
        load()
    }

    private func load() {
        state.set(.loading)
        Task {
            do {
                let article = try await ArticleAPI.fetch(id: articleId)
                await MainActor.run { state.set(.loaded(article)) }
            } catch {
                await MainActor.run { state.set(.failed(error.localizedDescription)) }
            }
        }
    }
}
```

## Threading rules

```swift
Task {
    let data = try await fetch()          // background OK
    await MainActor.run {
        state.set(.loaded(data))          // signal write MUST be on main actor
    }
}
```

Never call `signal.set` from a background thread. SignalKit types are `@MainActor` isolated.

## Cancel in-flight work

For production code, store the `Task` and cancel on unmount:

```swift
final class ArticleScreen: Component {
    private var loadTask: Task<Void, Never>?

    override func willUnmount() {
        loadTask?.cancel()
        loadTask = nil
        super.willUnmount()
    }

    private func load() {
        loadTask?.cancel()
        loadTask = Task {
            // check Task.isCancelled before setting state
            guard !Task.isCancelled else { return }
            // ...
        }
    }
}
```

## Slot vs observe for loading states

| Approach | Pros | Cons |
| --- | --- | --- |
| `Slot` | Clean separation per state; unmounts unused UI | More components to define |
| `observe` | Single component; all views in one `build()` | More visibility toggling logic |

## Related

- [Signals](../signals.md) — threading
- [Structural Hosts](../structural-hosts.md) — Slot
- [Lifecycle](../lifecycle.md) — cancel on unmount
