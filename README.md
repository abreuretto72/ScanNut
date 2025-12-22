# ScanNut

**ScanNut** is a Flutter application that helps users manage pet health, nutrition, and support partners. It includes powerful features such as:

- **Partner Hub** – Register and view support partners, generate PDF reports with mandatory sorting (category → name) following the FinAgeVoz standard.
- **Radar Explorer** – Discover nearby partners based on a configurable search radius.
- **PDF Export** – Export detailed or summary reports using `PdfPreviewScreen` with native preview, printing and sharing.
- **Settings** – Customize user profile, daily calorie goals, and toggle visibility of AI analysis buttons.
- **AI Food Analysis** – Analyze food images and get nutritional insights.

## Features Highlighted in This Release

1. **PDF Hub Report**
   - Mandatory sorting of partners by **category** and then **name**.
   - Two report types: **Resumo** (summary) and **Detalhamento** (detailed).
   - Uses `ExportService.generatePartnersHubReport` and displays the result with `PdfPreviewScreen`.
   - The dialog for export is scroll‑able, ensuring the **GERAR RELATÓRIO** button is always accessible.
2. **Improved UI**
   - Anti‑overflow design with `SingleChildScrollView`.
   - Premium visual style: dark background, glass‑morphism‑like cards, custom icons, and smooth micro‑animations.
3. **Settings Integration**
   - Radar radius can be changed from the Settings screen, and the Hub refreshes automatically.

## Getting Started

### Prerequisites
- Flutter SDK **≥ 3.19**
- Android SDK (API 33 recommended) or iOS simulator
- A device or emulator with Google Play services for location permissions

### Installation
```bash
# Clone the repository
git clone https://github.com/yourusername/ScanNut.git
cd ScanNut

# Install dependencies
flutter pub get

# Run the app
flutter run
```

### Building for Release
```bash
flutter build apk   # Android APK
flutter build ios   # iOS bundle (requires macOS)
```

## Usage

1. Open the **Meu Hub de Apoio** screen.
2. Tap the **Exportar PDF** button.
3. Choose the partner category filter and the report type (Resumo/Detalhamento).
4. Press **GERAR RELATÓRIO** – the PDF preview appears with options to print or share.
5. Adjust the Radar search radius in **Configurações**; the Hub will reload automatically.

## Contributing
Feel free to open issues or submit pull requests. Please follow these steps:
1. Fork the repository.
2. Create a feature branch (`git checkout -b feature/your-feature`).
3. Commit your changes with clear messages.
4. Open a pull request targeting the `main` branch.

## License
This project is licensed under the **MIT License** – see the `LICENSE` file for details.

---

*Generated with Antigravity AI assistant.*
