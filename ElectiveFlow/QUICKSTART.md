# 🚀 Швидкий старт ElectiveFlow

## Передумови

- macOS 13.0+
- Xcode 15.0+
- Apple Developer Account (для запуску на пристрої)
- Firebase Account

## Крок 1: Клонування проекту

```bash
git clone https://github.com/yourusername/electiveflow.git
cd electiveflow
```

## Крок 2: Налаштування Firebase

### 2.1 Створення проекту
1. Перейдіть на https://console.firebase.google.com/
2. Натисніть "Add project"
3. Введіть ім'я проекту: "ElectiveFlow"
4. Виберіть регіон та погодьтеся з умовами

### 2.2 Додавання iOS застосунку
1. У Firebase Console, натисніть на іконку iOS
2. Bundle ID: `com.yourcompany.electiveflow`
3. Завантажте `GoogleService-Info.plist`
4. Замініть файл у проекті

### 2.3 Налаштування Firestore
1. У Firebase Console → Build → Firestore Database
2. Натисніть "Create database"
3. Виберіть режим "Start in test mode"
4. Виберіть локацію (наприклад, europe-west1)

### 2.4 Налаштування Authentication
1. У Firebase Console → Build → Authentication
2. Натисніть "Get started"
3. Увімкніть "Email/Password" provider
4. (Опційно) Увімкніть Google Sign-In

## Крок 3: Firestore Security Rules

Додайте наступні правила безпеки:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users collection
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == userId;
    }
    
    // Electives collection
    match /electives/{electiveId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null && 
                       get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'teacher';
      allow update, delete: if request.auth != null && 
                               resource.data.teacherId == request.auth.uid;
    }
    
    // Registrations collection
    match /registrations/{registrationId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update: if request.auth != null && 
                       (resource.data.studentId == request.auth.uid || 
                        get(/databases/$(database)/documents/electives/$(resource.data.electiveId)).data.teacherId == request.auth.uid);
    }
    
    // News collection
    match /news/{newsId} {
      allow read: if request.auth != null;
      allow write: if false; // Only admin through Firebase Console
    }
    
    // Analytics collection
    match /analytics/{electiveId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
  }
}
```

## Крок 4: Початкові дані (опційно)

Додайте тестові дані через Firebase Console:

### Користувач викладача
```json
{
  "id": "teacher1",
  "name": "Dr. John Smith",
  "email": "teacher@university.edu",
  "role": "teacher",
  "interests": []
}
```

### Користувач студента
```json
{
  "id": "student1",
  "name": "Jane Doe",
  "email": "student@university.edu",
  "role": "student",
  "interests": ["AI", "Programming", "Data Science"]
}
```

### Тестова дисципліна
```json
{
  "id": "elective1",
  "name": "Introduction to Artificial Intelligence",
  "description": "Learn the fundamentals of AI, machine learning, and neural networks",
  "period": "Fall 2025",
  "teacherId": "teacher1",
  "teacherName": "Dr. John Smith",
  "maxStudents": 50,
  "currentStudents": 12,
  "categories": ["AI", "STEM", "Programming"],
  "distributionModel": "uniform",
  "registrationStartDate": "2025-09-01T00:00:00Z",
  "registrationEndDate": "2025-09-30T23:59:59Z",
  "createdAt": "2025-08-15T10:00:00Z",
  "numberOfGroups": 2
}
```

### Тестова новина
```json
{
  "id": "news1",
  "title": "New AI Research Lab Opens",
  "description": "The university announces the opening of a state-of-the-art artificial intelligence research laboratory",
  "articleURL": "https://university.edu/news/ai-lab",
  "publishedDate": "2025-12-01T10:00:00Z"
}
```

## Крок 5: Відкриття проекту в Xcode

```bash
open ElectiveFlow.xcodeproj
```

Або перетягніть папку проекту на іконку Xcode.

## Крок 6: Налаштування проекту в Xcode

1. Виберіть проект у Project Navigator
2. У розділі "Signing & Capabilities":
   - Виберіть ваш Team
   - Змініть Bundle Identifier (якщо потрібно)
3. Виберіть симулятор або пристрій
4. Натисніть ▶️ Run (⌘R)

## Крок 7: Перший запуск

1. Застосунок запуститься з онбордінгом
2. Натисніть "Get Started"
3. Зареєструйтеся або увійдіть:
   - Email: `teacher@test.com`
   - Password: `password123`
   - Role: Teacher
4. Explore the app! 🎉

## Тестові облікові записи

### Викладач
- Email: `teacher@test.com`
- Password: `password123`
- Role: Teacher

### Студент
- Email: `student@test.com`
- Password: `password123`
- Role: Student

## Розв'язання проблем

### Firebase не підключається
1. Перевірте, чи файл `GoogleService-Info.plist` додано до проекту
2. Перевірте Bundle ID в Xcode та Firebase Console
3. Переконайтеся, що Firebase SDK правильно імпортовано

### Помилки компіляції
1. Очистіть build folder: Product → Clean Build Folder (⇧⌘K)
2. Закрийте та відкрийте Xcode
3. Видаліть DerivedData: `rm -rf ~/Library/Developer/Xcode/DerivedData`

### Проблеми з Firebase SDK
```bash
# Оновіть залежності
swift package update
```

## Корисні команди

```bash
# Очистка проекту
xcodebuild clean -project ElectiveFlow.xcodeproj -scheme ElectiveFlow

# Білд проекту
xcodebuild build -project ElectiveFlow.xcodeproj -scheme ElectiveFlow

# Запуск тестів
xcodebuild test -project ElectiveFlow.xcodeproj -scheme ElectiveFlow -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
```

## Наступні кроки

1. 📚 Прочитайте повний [README.md](README.md)
2. 🎨 Налаштуйте дизайн під ваш університет
3. 🔧 Додайте власні функції
4. 🚀 Розгорніть на App Store

## Потрібна допомога?

- 📖 Документація: https://electiveflow.app/docs
- 💬 Discord: https://discord.gg/electiveflow
- 📧 Email: support@electiveflow.app

---

**Happy coding! 🚀**
