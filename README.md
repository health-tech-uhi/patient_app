# patient_app

Patient Flutter app for the health platform (API via `flutter_dotenv`).

## Environment

1. Copy the example env file and edit values as needed:
   ```bash
   cp .env.example .env
   ```
2. The app loads `.env` at startup (`lib/main.dart`). Keep your real `.env` local; it is gitignored.

| Variable        | Description                                      |
|-----------------|--------------------------------------------------|
| `API_BASE_URL`  | Health platform / BFF base URL (default `http://localhost:3111`). |

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
