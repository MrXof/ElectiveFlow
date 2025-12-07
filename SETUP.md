# 📋 Інструкція з налаштування ElectiveFlow

## ⚠️ ВАЖЛИВО: Перед запуском

Цей проект потребує налаштування Firebase. Будь ласка, виконайте наступні кроки:

## 🔥 Налаштування Firebase (обов'язково)

### Крок 1: Створіть Firebase проект
1. Перейдіть на https://console.firebase.google.com/
2. Клікніть "Додати проект" / "Add project"
3. Введіть назву: `ElectiveFlow`
4. Виберіть опції (можна відключити Google Analytics для тесту)
5. Натисніть "Створити проект"

### Крок 2: Додайте iOS застосунок
1. На головній сторінці проекту натисніть іконку iOS
2. Bundle ID: `com.electiveflow.app` (або ваш власний)
3. Введіть назву застосунку (опційно)
4. Натисніть "Зареєструвати застосунок"

### Крок 3: Завантажте GoogleService-Info.plist
1. Натисніть "Завантажити GoogleService-Info.plist"
2. **ВАЖЛИВО**: Замініть файл `GoogleService-Info.plist` у папці проекту
3. Перетягніть файл у Xcode (переконайтеся що "Copy items if needed" відмічено)

### Крок 4: Налаштуйте Firestore Database
1. У меню ліворуч виберіть "Build" → "Firestore Database"
2. Натисніть "Створити базу даних" / "Create database"
3. Виберіть режим: "Start in test mode" (для розробки)
4. Виберіть локацію: `europe-west1` (або найближчу до вас)
5. Натисніть "Увімкнути" / "Enable"

### Крок 5: Налаштуйте Authentication
1. У меню виберіть "Build" → "Authentication"
2. Натисніть "Get started"
3. Увімкніть провайдера "Email/Password":
   - Клікніть на "Email/Password"
   - Увімкніть перемикач
   - Натисніть "Зберегти"

### Крок 6: Додайте Security Rules для Firestore

Перейдіть у розділ "Firestore Database" → "Rules" та вставте:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == userId;
    }
    
    match /electives/{electiveId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update, delete: if request.auth != null;
    }
    
    match /registrations/{registrationId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update: if request.auth != null;
    }
    
    match /news/{newsId} {
      allow read: if request.auth != null;
      allow write: if false;
    }
    
    match /analytics/{electiveId} {
      allow read, write: if request.auth != null;
    }
  }
}
```

Натисніть "Опублікувати" / "Publish"

## 📱 Запуск проекту

### Крок 1: Відкрийте проект у Xcode
```bash
cd ElectiveFlow
open ElectiveFlow.xcodeproj
```

### Крок 2: Налаштуйте Signing
1. Виберіть проект у Project Navigator
2. Виберіть target "ElectiveFlow"
3. Перейдіть на вкладку "Signing & Capabilities"
4. Виберіть ваш Apple Developer Team
5. Якщо Bundle ID зайнятий, змініть його (наприклад: `com.yourname.electiveflow`)

### Крок 3: Виберіть пристрій
- Для симулятора: виберіть "iPhone 15 Pro" або будь-який інший
- Для фізичного пристрою: підключіть через USB та виберіть його

### Крок 4: Запустіть проект
Натисніть кнопку ▶️ Run або `⌘R`

## 🎉 Перший запуск

1. Ви побачите онбордінг екрани - пройдіть їх
2. На екрані логіну створіть обліковий запис:
   - Name: Ваше ім'я
   - Email: test@example.com
   - Password: test123456
   - Role: Teacher або Student
3. Натисніть "Sign Up"

## 🧪 Тестові дані

Для швидкого тестування, додайте тестові дані через Firebase Console:

### Додати тестову дисципліну:
1. Firestore Database → Почати колекцію
2. ID колекції: `electives`
3. ID документу: `elective1`
4. Додайте поля:

```
name: "Introduction to AI"
description: "Learn AI fundamentals"
period: "Fall 2025"
teacherId: "ваш-user-id"
teacherName: "Ваше ім'я"
maxStudents: 50
currentStudents: 0
categories: ["AI", "STEM"]
distributionModel: "uniform"
registrationStartDate: [сьогодні]
registrationEndDate: [через місяць]
createdAt: [сьогодні]
numberOfGroups: 2
```

### Додати новину:
1. Firestore Database → Почати колекцію
2. ID колекції: `news`
3. ID документу: `news1`
4. Додайте поля:

```
title: "Welcome to ElectiveFlow!"
description: "Start managing your electives today"
articleURL: "https://example.com"
publishedDate: [сьогодні]
```

## ❓ Часті проблеми

### Firebase не підключається
**Проблема**: Помилка "Firebase app has not been configured"

**Рішення**:
1. Перевірте, чи файл `GoogleService-Info.plist` в корені проекту
2. Перевірте Bundle ID у Xcode та Firebase Console - мають співпадати
3. Очистіть Build: Product → Clean Build Folder (`⇧⌘K`)
4. Перезапустіть Xcode

### Помилки компіляції Swift
**Проблема**: "Cannot find type X in scope"

**Рішення**:
1. File → Packages → Reset Package Caches
2. Product → Clean Build Folder
3. Закрийте та знову відкрийте Xcode

### Не можу зареєструватися
**Проблема**: Помилка при реєстрації

**Рішення**:
1. Перевірте, чи увімкнено Email/Password в Authentication
2. Перевірте Security Rules у Firestore
3. Перевірте консоль Firebase на помилки

### Пустий екран після логіну
**Проблема**: Застосунок відкривається але нічого не показує

**Рішення**:
1. Додайте тестові дані через Firebase Console
2. Перевірте інтернет з'єднання
3. Перевірте Firestore Rules

## 🔧 Додаткові команди

### Очистити всі дані симулятора:
```bash
xcrun simctl erase all
```

### Переглянути логи:
У Xcode: View → Debug Area → Activate Console

### Перевірити Firebase з'єднання:
Додайте у `ElectiveFlowApp.swift`:
```swift
print("Firebase configured successfully!")
```

## 📚 Додаткові ресурси

- [Firebase Documentation](https://firebase.google.com/docs)
- [SwiftUI Tutorials](https://developer.apple.com/tutorials/swiftui)
- [Xcode Help](https://developer.apple.com/xcode/)

## 💬 Потрібна допомога?

Якщо виникли проблеми:
1. Перевірте консоль Xcode на помилки
2. Перевірте консоль Firebase на проблеми
3. Створіть Issue на GitHub з детальним описом проблеми

---

**Приємної роботи з ElectiveFlow! 🚀**
