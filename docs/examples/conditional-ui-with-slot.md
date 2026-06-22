# Example: Conditional UI with Slot

Swap entire child components based on a signal — login vs profile, tabs, onboarding flows.

**Concepts:** `Slot`, child component lifetimes, structural replacement

## Models

```swift
struct User: Equatable {
    let name: String
    let email: String
}
```

## Child components

```swift
final class LoginComponent: Component {
    let onLogin: (User) -> Void

    init(onLogin: @escaping (User) -> Void) {
        self.onLogin = onLogin
        super.init()
    }

    override func build() -> Node {
        let label = UILabel()
        label.text = "Please sign in"
        label.textAlignment = .center

        let button = UIButton(type: .system)
        button.setTitle("Sign In", for: .normal)

        track(button.onTap { [onLogin] in
            onLogin(User(name: "Ada", email: "ada@example.com"))
        })

        return VStack(spacing: 16) {
            label
            button
        }
    }
}

final class ProfileComponent: Component {
    let user: User

    init(user: User) {
        self.user = user
        super.init()
    }

    override func build() -> Node {
        let nameLabel = UILabel()
        nameLabel.font = .preferredFont(forTextStyle: .title2)
        nameLabel.text = user.name

        let emailLabel = UILabel()
        emailLabel.font = .preferredFont(forTextStyle: .subheadline)
        emailLabel.textColor = .secondaryLabel
        emailLabel.text = user.email

        return VStack(spacing: 8) {
            nameLabel
            emailLabel
        }
    }
}
```

## Host with Slot

```swift
final class AuthScreen: Component {
    let currentUser = Signal<User?>(nil)

    override func build() -> Node {
        Slot(currentUser) { [currentUser] user in
            if let user {
                ProfileComponent(user: user)
            } else {
                LoginComponent { loggedInUser in
                    currentUser.set(loggedInUser)
                }
            }
        }
    }
}
```

## Usage

```swift
let auth = AuthScreen()
let root = auth.mount()
view.addSubview(root)

// Initially shows LoginComponent
// Tap "Sign In" → currentUser.set(...) → Slot replaces with ProfileComponent
// Old LoginComponent is unmounted automatically
```

## What happens on login

```text
User taps "Sign In"
  → onLogin(User(...)) called
  → currentUser.set(user)
  → Slot observes change
  → releaseChild(LoginComponent) — unmounts login UI
  → mountChild(ProfileComponent) — mounts profile UI
  → profile root view replaces login in slot container
```

The slot container view itself never changes — only its child subtree.

## Enum-driven tabs

```swift
enum Tab: Equatable { case home, settings }

final class TabScreen: Component {
    let selectedTab = Signal(Tab.home)

    override func build() -> Node {
        VStack(spacing: 0) {
            // Tab bar
            HStack(spacing: 0) {
                tabButton("Home", tab: .home)
                tabButton("Settings", tab: .settings)
            }

            // Content area
            Slot(selectedTab) { tab in
                switch tab {
                case .home: HomeComponent()
                case .settings: SettingsComponent()
                }
            }
        }
    }

    private func tabButton(_ title: String, tab: Tab) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        track(button.onTap { [selectedTab] in
            selectedTab.set(tab)
        })
        return button
    }
}
```

## Logout

```swift
track(logoutButton.onTap { [currentUser] in
    currentUser.set(nil)
})
// Slot unmounts ProfileComponent, remounts LoginComponent
```

## Related

- [Structural Hosts](../structural-hosts.md)
- [Lifecycle](../lifecycle.md)
