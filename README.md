# SMRITI

SMRITI is a Flutter-based healthcare application designed to help patients better understand their doctor's instructions and manage their healthcare information.

## Features

- **Patient Profile:** Store and manage patient health information.
- **Medical Report Analysis:** Help patients understand medical reports using AI.
- **Doctor's Instructions:** Simplify and organize instructions given by healthcare professionals.
- **Reminders:** Support medication and healthcare reminders.
- **Understanding Verification:** Help patients check their understanding of medical instructions through questions.
- **Demo Mode:** Explore the app with sample data.

## Built With

- Flutter
- Dart
- Google Gemini API

## Getting Started

### Prerequisites

- Flutter SDK
- Dart SDK
- Android Studio or Visual Studio Code

### Run the App

1. Clone this repository:

   ```bash
   git clone https://github.com/geetanunakani/smriti-project.git
   ```

2. Navigate to the project directory:

   ```bash
   cd smriti-project
   ```

3. Install dependencies:

   ```bash
   flutter pub get
   ```

4. Run the application:

   ```bash
   flutter run
   ```

### Gemini API Configuration

The app reads the Gemini API key through the `GEMINI_API_KEY` environment define.

To run with your own API key:

```bash
flutter run --dart-define=GEMINI_API_KEY=YOUR_API_KEY
```

**Security:** Never commit your actual API key to GitHub. For a publicly distributed app, use a secure backend to protect the key.

Without an API key, the app may run in demo mode with sample data.

## Demo Video

[Watch the SMRITI Demo on YouTube](https://youtu.be/-hM3J7WaTj4)

## Disclaimer

SMRITI is intended to support understanding of healthcare information. It does not replace professional medical advice, diagnosis, or treatment.

## License

No license has been specified yet.