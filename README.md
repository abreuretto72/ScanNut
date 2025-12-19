# 🌟 Scannut - AI Visual Assistant

<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-3.0+-02569B?style=for-the-badge&logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.0+-0175C2?style=for-the-badge&logo=dart)
![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)

**AI-Powered Visual Analysis for Nutrition, Botany & Pet Care**

[Features](#-features) • [Screenshots](#-screenshots) • [Installation](#-installation) • [Architecture](#-architecture) • [Contributing](#-contributing)

</div>

---

## 📱 About

**Scannut** is a revolutionary mobile application that uses **AI Vision** to analyze:
- 🍎 **Food** - Nutritional analysis with calories, macros, benefits & risks
- 🌿 **Plants** - Disease diagnosis with organic treatment plans
- 🐾 **Pets** - Health screening with urgency levels & emergency guidance

Powered by **Groq's LLaVA Vision Model** for lightning-fast analysis (< 2 seconds).

---

## ✨ Features

### 🍎 Food Analysis
- **Nutritional Breakdown**: Calories, proteins, carbs, fats
- **Health Insights**: Benefits and potential risks
- **Vitality Score**: AI-calculated health rating (1-10)
- **Personalized Advice**: Tailored nutritional recommendations

### 🌿 Plant Diagnosis
- **Disease Detection**: Identifies plant health issues
- **Treatment Timeline**: Step-by-step organic recovery plan
- **Urgency Meter**: Visual risk level indicator
- **Shopping Integration**: Direct link to recommended treatments

### 🐾 Pet Health Screening
- **Visual Triage**: Identifies species and symptoms
- **Urgency Levels**: Green (observation) / Yellow (attention) / Red (emergency)
- **Emergency Mode**: Direct access to 24h veterinary clinics
- **First Aid Guidance**: Immediate care instructions

---

## 🎨 Design Highlights

- **Glassmorphism UI**: Frosted glass effects with backdrop blur
- **Dark Mode**: Optimized for OLED displays
- **Haptic Feedback**: Multi-sensorial experience
- **Staggered Animations**: Smooth, cascading element reveals
- **Dynamic Colors**: Context-aware theming (health-based)

---

## 🏗️ Architecture

### Clean Architecture + Riverpod

```
lib/
├── core/
│   ├── enums/          # ScannutMode
│   ├── models/         # AnalysisState
│   ├── providers/      # Riverpod StateNotifiers
│   ├── services/       # GroqService (API)
│   └── utils/          # PromptFactory, ColorHelper
├── features/
│   ├── food/
│   │   ├── models/
│   │   └── presentation/widgets/
│   ├── plant/
│   │   ├── models/
│   │   └── presentation/widgets/
│   ├── pet/
│   │   ├── models/
│   │   └── presentation/widgets/
│   ├── home/
│   │   └── presentation/
│   └── splash/
└── l10n/               # i18n (PT, EN, ES)
```

### State Management
- **Riverpod** for reactive state
- **StateNotifier** for analysis lifecycle
- **Consumer** widgets for UI reactivity

---

## 🚀 Installation

### Prerequisites
- Flutter SDK 3.0+
- Dart 3.0+
- Android Studio / VS Code
- Groq API Key ([Get one here](https://console.groq.com))

### Setup

1. **Clone the repository**
```bash
git clone https://github.com/abreuretto72/ScanNut.git
cd ScanNut
```

2. **Install dependencies**
```bash
flutter pub get
```

3. **Configure environment variables**

Create a `.env` file in the project root:
```env
GROQ_API_KEY=your_groq_api_key_here
BASE_URL=https://api.groq.com/openai/v1
```

4. **Run the app**
```bash
flutter run
```

---

## 📦 Dependencies

### Core
- `flutter_riverpod` - State management
- `dio` - HTTP client
- `camera` - Camera access
- `flutter_dotenv` - Environment variables

### UI/UX
- `google_fonts` - Typography
- `lottie` - Animations
- `percent_indicator` - Progress visualizations
- `flutter_staggered_animations` - Cascading animations
- `font_awesome_flutter` - Icon library

### Utilities
- `url_launcher` - External links
- `permission_handler` - Device permissions
- `shared_preferences` - Local storage
- `path_provider` - File system access

---

## 🌍 Internationalization

Scannut supports:
- 🇧🇷 **Portuguese** (default)
- 🇺🇸 **English**
- 🇪🇸 **Spanish**

AI responses are always in **Portuguese** for consistency.

---

## 🤖 AI Integration

### Groq LLaVA Vision Model
- **Model**: `llava-v1.5-7b-4096-preview`
- **Response Time**: < 2 seconds
- **Temperature**: 0.3 (consistent results)
- **Format**: Strict JSON output

### Prompt Engineering
- Prompts in **English** for maximum accuracy
- Explicit instruction: "Answer in Portuguese (pt-BR)"
- Structured JSON schemas for each mode
- Error handling with fallback responses

---

## 📸 Screenshots

> Coming soon! Run the app to see the magic ✨

---

## 🛠️ Development

### Run in debug mode
```bash
flutter run
```

### Build for release
```bash
# Android
flutter build apk --release

# iOS
flutter build ios --release
```

### Run tests
```bash
flutter test
```

### Analyze code
```bash
flutter analyze
```

---

## 🗺️ Roadmap

- [x] AI Vision integration (Groq LLaVA)
- [x] Food nutritional analysis
- [x] Plant disease diagnosis
- [x] Pet health screening
- [x] Glassmorphism UI
- [x] Haptic feedback
- [x] i18n (PT/EN/ES)
- [ ] Lottie scan animations
- [ ] History persistence (Hive)
- [ ] User profiles
- [ ] Share results
- [ ] Export to PDF
- [ ] Offline mode

---

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 👨‍💻 Author

**Abreu Retto**

- GitHub: [@abreuretto72](https://github.com/abreuretto72)
- Project Link: [https://github.com/abreuretto72/ScanNut](https://github.com/abreuretto72/ScanNut)

---

## 🙏 Acknowledgments

- [Groq](https://groq.com) - Lightning-fast AI inference
- [Flutter](https://flutter.dev) - Beautiful native apps
- [Riverpod](https://riverpod.dev) - Reactive state management
- Community contributors and testers

---

<div align="center">

**Made with ❤️ and AI**

⭐ Star this repo if you find it useful!

</div>
