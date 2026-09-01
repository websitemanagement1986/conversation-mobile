# Voice Language Tutor — Android App

Standalone Android app for interactive voice language practice with an AI tutor.

## Features

- Choose language, CEFR level (A1–C2), and situation
- Speak with the AI tutor — it listens and replies by voice
- Live captions, corrections, vocabulary cards
- Session recap at the end
- Open mic or push-to-talk

## How it works

1. You enter your **free Gemini API key** (stored on your phone only)
2. Pick language, level, and situation
3. Tap **Start talking** — the AI greets you and starts the roleplay
4. Speak into the mic — the AI responds by voice
5. End session to see your recap

Uses **Gemini 2.0 Flash** for conversation + Android **speech-to-text** and **text-to-speech** for voice.

## Build APK in the cloud (no Node.js, no Android Studio)

### 1. Push to GitHub

```powershell
cd C:\Repositiries\conversation-mobile
git init
git add .
git commit -m "Voice Language Tutor Android app"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/conversation-mobile.git
git push -u origin main
```

### 2. Download the APK

1. Open your repo on GitHub → **Actions** tab
2. Click the latest **Build Android APK** workflow run
3. Download **language-tutor-apk** artifact
4. Unzip and install `app-release.apk` on your Android phone

You can also trigger a build manually: **Actions → Build Android APK → Run workflow**

### 3. Install on your phone

1. Transfer the APK to your phone (email, Drive, or direct download)
2. Allow **Install unknown apps** when prompted
3. Open **Language Tutor**
4. Paste your Gemini API key from [Google AI Studio](https://aistudio.google.com/apikey)
5. Allow microphone permission
6. Start practicing!

## Get a free API key

1. Go to [https://aistudio.google.com/apikey](https://aistudio.google.com/apikey)
2. Sign in with Google
3. Click **Create API key**
4. Paste it in the app Settings screen

## Project structure

```
lib/
  main.dart              App entry + API key gate
  config/app_config.dart Languages, levels, situations, prompts
  models/models.dart     Data types
  services/              Gemini, speech, session logic
  screens/               Settings, setup, conversation, recap
.github/workflows/       Cloud APK build
```

## Requirements

- Android 7.0+ (API 24)
- Internet connection
- Microphone
- Gemini API key (free tier)

## iPhone (later)

Same Flutter codebase can target iOS when you have access to a Mac or macOS cloud builder.

## License

MIT
