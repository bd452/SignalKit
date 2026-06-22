# Example: Form with Validation

A sign-up form with multiple fields, derived validation state, and a submit button that reacts to validity.

**Concepts:** multiple signals, `observe`, `bind`, `onEvent`, derived UI state

## Form component

```swift
import SignalKit
import UIKit

final class SignUpForm: Component {
    let email = Signal("")
    let password = Signal("")
    let confirmPassword = Signal("")

    // Derived state — updated by observe, not a separate computation in build()
    let isValid = Signal(false)
    let errorMessage = Signal<String?>(nil)

    override func build() -> Node {
        let emailField = makeField(placeholder: "Email")
        let passwordField = makeField(placeholder: "Password", secure: true)
        let confirmField = makeField(placeholder: "Confirm password", secure: true)

        let errorLabel = UILabel()
        errorLabel.textColor = .systemRed
        errorLabel.font = .preferredFont(forTextStyle: .footnote)
        errorLabel.numberOfLines = 0

        let submitButton = UIButton(type: .system)
        submitButton.setTitle("Create Account", for: .normal)
        var config = UIButton.Configuration.filled()
        config.cornerStyle = .medium
        submitButton.configuration = config

        // Wire text fields → signals
        track(emailField.onEvent(.editingChanged) { [emailField, email] in
            email.set(emailField.text ?? "")
        })
        track(passwordField.onEvent(.editingChanged) { [passwordField, password] in
            password.set(passwordField.text ?? "")
        })
        track(confirmField.onEvent(.editingChanged) { [confirmField, confirmPassword] in
            confirmPassword.set(confirmField.text ?? "")
        })

        // Recompute validation whenever any field changes
        observe(email) { [self] _ in revalidate() }
        observe(password) { [self] _ in revalidate() }
        observe(confirmPassword) { [self] _ in revalidate() }

        // Bind derived state → UI
        bind(submitButton, \.isEnabled, isValid)
        bind(errorLabel, \.text, errorMessage) { $0 ?? "" }
        bind(errorLabel, \.isHidden, errorMessage) { $0 == nil }

        track(submitButton.onTap { [self] in
            submit()
        })

        return VStack(spacing: 16) {
            emailField
            passwordField
            confirmField
            errorLabel
            submitButton
        }
    }

    private func makeField(placeholder: String, secure: Bool = false) -> UITextField {
        let field = UITextField()
        field.placeholder = placeholder
        field.borderStyle = .roundedRect
        field.isSecureTextEntry = secure
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        return field
    }

    private func revalidate() {
        let emailValue = email.current
        let passwordValue = password.current
        let confirmValue = confirmPassword.current

        if emailValue.isEmpty || passwordValue.isEmpty || confirmValue.isEmpty {
            isValid.set(false)
            errorMessage.set(nil)
            return
        }

        if !emailValue.contains("@") {
            isValid.set(false)
            errorMessage.set("Enter a valid email address.")
            return
        }

        if passwordValue.count < 8 {
            isValid.set(false)
            errorMessage.set("Password must be at least 8 characters.")
            return
        }

        if passwordValue != confirmValue {
            isValid.set(false)
            errorMessage.set("Passwords do not match.")
            return
        }

        isValid.set(true)
        errorMessage.set(nil)
    }

    private func submit() {
        guard isValid.current else { return }
        print("Submitting: \(email.current)")
        // Navigate away, call API, etc.
    }
}
```

## Usage

```swift
let form = SignUpForm()
view.addSubview(form.mount())
```

## Flow

```text
User types in email field
  → editingChanged event
  → email.set("user@")
  → observe(email) fires → revalidate()
  → isValid.set(false), errorMessage.set("Enter a valid email...")
  → bind updates submitButton.isEnabled and errorLabel
```

## Design notes

### Validation lives outside build()

`revalidate()` runs in response to signal changes, not during `build()`. The form UI is built once; validation reacts to input.

### Use observe for multi-signal effects

When one handler depends on several signals, observe each and call a shared validation function:

```swift
observe(email) { [self] _ in revalidate() }
observe(password) { [self] _ in revalidate() }
```

Alternatively, a single `observe` on a tuple signal if you introduce a combined model — but separate field signals are simpler for forms.

### bind vs observe for error display

`errorMessage` is `String?`. The binding transforms it for display:

```swift
bind(errorLabel, \.text, errorMessage) { $0 ?? "" }
bind(errorLabel, \.isHidden, errorMessage) { $0 == nil }
```

### setIfChanged for validation signals

Reduce redundant UI updates:

```swift
isValid.setIfChanged(true)
errorMessage.setIfChanged(nil)
```

## Related

- [Binding & Observation](../binding-and-observation.md)
- [Events](../events.md)
