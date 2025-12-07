# 📱 ElectiveFlow

Мобільний застосунок для управління вибірковими дисциплінами у ВНЗ.

## 🎯 Особливості

### Для викладачів
- ✅ Створення та управління дисциплінами
- 📊 Детальна аналітика та статистика
- 📈 Прогнозування фінального набору (лінійна регресія)
- 🎲 Оптимальний розподіл студентів по групах
- 📥 Експорт списків студентів
- 🔔 Push-сповіщення про реєстрації

### Для студентів
- 📚 Перегляд каталогу дисциплін
- 🧭 Персоналізовані рекомендації (cosine similarity)
- ✨ Швидка реєстрація на дисципліни
- ❤️ Функція обраних дисциплін
- 📊 Відстеження статусу реєстрації

### Спільні функції
- 🌓 Темна та світла теми
- 📰 Університетські новини
- 🌐 Підтримка декількох мов (UA/EN)
- 🔒 Безпечна автентифікація
- 💾 Автоматичне збереження даних

## 🧠 Математичні алгоритми

### 1. Оптимальний розподіл по групах
```swift
// Жадібний алгоритм з мінімізацією розкиду
D = max(groupCount) - min(groupCount)
```

### 2. Прогнозування набору
```swift
// Лінійна регресія
y = ax + b
```

### 3. Рекомендації дисциплін
```swift
// Cosine similarity між інтересами студента та категоріями дисципліни
similarity = dot(vectorA, vectorB) / (||vectorA|| * ||vectorB||)
```

## 🏗️ Архітектура

### MVVM Pattern
```
Views/
├── Onboarding/
├── Auth/
├── Home/
├── Electives/
├── Student/
├── News/
└── Settings/

Models/
├── User
├── Elective
├── StudentRegistration
└── RegistrationAnalytics

Services/
├── DatabaseService (Protocol)
├── FirebaseDatabaseService
└── GroupDistributionAlgorithm

State/
└── AppState
```

### Database Abstraction Layer
```swift
protocol DatabaseService {
    func fetchElectives() async throws -> [Elective]
    func createElective(_ elective: Elective) async throws
    // ... інші методи
}
```

**Зміна бази даних за 5 хвилин:**
```swift
// Firebase
let db: DatabaseService = FirebaseDatabaseService()

// Supabase
let db: DatabaseService = SupabaseDatabaseService()

// Mock для тестування
let db: DatabaseService = MockDatabaseService()
```

## 📦 Залежності

- **Firebase iOS SDK** (10.20.0+)
  - FirebaseAuth
  - FirebaseFirestore
  - FirebaseStorage
- **SwiftUI Charts** (вбудовано в iOS 16+)

## 🚀 Встановлення

### 1. Клонуйте репозиторій
```bash
git clone https://github.com/yourusername/electiveflow.git
cd electiveflow
```

### 2. Налаштування Firebase

1. Створіть проект у [Firebase Console](https://console.firebase.google.com/)
2. Додайте iOS застосунок до проекту
3. Завантажте `GoogleService-Info.plist`
4. Замініть шаблон `GoogleService-Info.plist` у проекті

### 3. Налаштування Firestore

Створіть наступні колекції:

**users**
```json
{
  "id": "string",
  "name": "string",
  "email": "string",
  "role": "teacher | student",
  "interests": ["string"]
}
```

**electives**
```json
{
  "id": "string",
  "name": "string",
  "description": "string",
  "period": "string",
  "teacherId": "string",
  "teacherName": "string",
  "maxStudents": number,
  "currentStudents": number,
  "categories": ["string"],
  "distributionModel": "uniform | priority | manual",
  "registrationStartDate": timestamp,
  "registrationEndDate": timestamp,
  "numberOfGroups": number
}
```

**registrations**
```json
{
  "id": "string",
  "studentId": "string",
  "studentName": "string",
  "electiveId": "string",
  "registrationDate": timestamp,
  "priority": number,
  "groupNumber": number,
  "status": "pending | confirmed | waitlist"
}
```

**news**
```json
{
  "id": "string",
  "title": "string",
  "description": "string",
  "articleURL": "string",
  "publishedDate": timestamp
}
```

### 4. Запуск проекту

```bash
# Відкрийте у Xcode
open ElectiveFlow.xcodeproj

# Або через командний рядок
xcodebuild -scheme ElectiveFlow -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
```

## 🎨 Дизайн

### Кольорова палітра
- **Primary**: `#3A7AFE` (systemBlue)
- **Success**: `#34C759` (systemGreen)
- **Warning**: `#FF9500` (systemOrange)
- **Error**: `#FF3B30` (systemRed)

### Типографія
- **Headers**: SF Pro Display (Bold)
- **Body**: SF Pro Text (Regular)
- **Captions**: SF Pro Text (Medium)

### Відступи
- Small: 8pt
- Medium: 16pt
- Large: 24pt
- XLarge: 40pt

### Corner Radius
- Buttons: 12pt
- Cards: 16pt
- Large Cards: 20pt

## 📱 Вимоги

- iOS 16.0+
- Xcode 15.0+
- Swift 5.9+

## 🔐 Безпека

- ✅ Firebase Authentication
- ✅ Secure data storage
- ✅ Role-based access control
- ✅ Input validation
- ✅ HTTPS only communication

## 🧪 Тестування

```bash
# Unit Tests
xcodebuild test -scheme ElectiveFlow -destination 'platform=iOS Simulator,name=iPhone 15 Pro'

# UI Tests
xcodebuild test -scheme ElectiveFlowUITests -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
```

## 📈 Roadmap

### Version 1.0 (Current)
- [x] Onboarding
- [x] Authentication
- [x] Teacher dashboard
- [x] Elective management
- [x] Analytics & statistics
- [x] Group distribution algorithm

### Version 2.0 (Planned)
- [ ] Student features
- [ ] Push notifications
- [ ] Calendar integration
- [ ] Offline mode
- [ ] Course materials
- [ ] Chat functionality

### Version 3.0 (Future)
- [ ] Video lectures
- [ ] Assignment submissions
- [ ] Grades tracking
- [ ] Student forums
- [ ] Mobile app for Android

## 🤝 Внесок

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📝 Ліцензія

MIT License - see [LICENSE](LICENSE) file for details

## 👨‍💻 Автор

ElectiveFlow Team

## 📧 Контакти

- Email: support@electiveflow.app
- Website: https://electiveflow.app
- Twitter: @electiveflow

## 🙏 Подяки

- Firebase team за чудову backend платформу
- Apple за SwiftUI та інші інструменти
- Всім контриб'юторам проекту

---

**Зроблено з ❤️ для освітніх закладів України**
