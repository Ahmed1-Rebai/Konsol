<div align="center">

<img src="assets/brand/logo.png" alt="Konsol Logo" width="160" />

# Konsol

**Premium SSH client for mobile — connect, control, conquer.**

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.11-0175C2?logo=dart)](https://dart.dev)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-lightgrey)]()

---

Konsol is a beautifully crafted SSH terminal built with Flutter. Manage your servers on the go with a native, responsive UI — password or key-based auth, multi-session tabs, and credentials stored securely in the device keychain.

</div>

---

## Features

- **Host Management** — Add, edit, search, pin, and color-code your servers
- **SSH Terminal** — Full VT100 terminal powered by `xterm` with smooth rendering
- **Multi-Session Tabs** — Run multiple SSH sessions simultaneously
- **Secure Credentials** — Passwords and private keys stored in the device keychain via `flutter_secure_storage`
- **SSH Key Manager** — Generate and manage Ed25519 / RSA keys
- **Smart Path Completion** — Real-time remote path autocompletion
- **Quick Key Bar** — ESC, Tab, Ctrl+C, arrows, and common shell symbols at your fingertips
- **Terminal Themes** — Choose from Konsol, Tokyo Night, or classic Green on Black
- **Dark & Light Mode** — Full theme support with system auto-switch
- **Adjustable Font Size** — Fine-tune your terminal readability
- **Haptic Feedback** — Tactile responses for connections and actions

## Architecture

```
lib/
├── core/               # Design tokens, theme, utilities
├── data/               # Models (Host, SSHKey), repositories, secure storage
├── features/
│   ├── hosts/          # Host list, add/edit screens
│   ├── keys/           # SSH key management
│   ├── settings/       # App settings screen
│   └── terminal/       # Terminal controller, session view, path completer
├── router/             # GoRouter navigation config
└── main.dart           # App entry point
```

**State:** Riverpod · **Navigation:** GoRouter · **Local DB:** Hive · **SSH:** dartssh2 · **Terminal:** xterm

## Getting Started

### Prerequisites

- Flutter SDK `^3.11.4`
- Dart SDK `^3.11.4`
- Android Studio / Xcode

### Setup

```bash
# Clone the repository
git clone https://github.com/your-username/konsol.git
cd konsol

# Install dependencies
flutter pub get

# Run on connected device
flutter run
```

## Tech Stack

| Layer | Technology |
|-------|-----------|
| UI Framework | Flutter |
| State Management | flutter_riverpod |
| Navigation | go_router |
| Local Database | Hive |
| Secure Storage | flutter_secure_storage |
| SSH Protocol | dartssh2 |
| Terminal Emulator | xterm |
| Cryptography | cryptography |
| Icons | lucide_icons |
| Fonts | JetBrains Mono |

## Security

- Passwords are encrypted and stored in the **device keychain** (Keychain on iOS, EncryptedSharedPreferences on Android)
- Private keys never leave the device
- No analytics, no telemetry, no cloud sync — your infrastructure stays yours

## Contributing

Contributions are welcome! Please open an issue first to discuss what you'd like to change.

```bash
# Fork & clone
git clone https://github.com/your-username/konsol.git

# Create a feature branch
git checkout -b feature/amazing-feature

# Commit & push
git commit -m "feat: add amazing feature"
git push origin feature/amazing-feature
```

## License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.

---

<div align="center">

**Built with care for sysadmins, DevOps engineers, and anyone who lives in the terminal.**

</div>
