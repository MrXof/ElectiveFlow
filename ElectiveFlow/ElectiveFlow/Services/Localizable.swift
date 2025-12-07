//import Foundation
//import SwiftUI
//
//class Localizable {
//    static let shared = Localizable()
//    
//    private init() {}
//    
//    // MARK: - Common
//    func text(_ key: String, language: String) -> String {
//        return translations[language]?[key] ?? translations["EN"]?[key] ?? key
//    }
//    
//    private let translations: [String: [String: String]] = [
//        "EN": [
//            // TabBar
//            "tab.home": "Home",
//            "tab.electives": "Electives",
//            "tab.catalog": "Catalog",
//            "tab.news": "News",
//            "tab.settings": "Settings",
//            
//            // Home
//            "home.hello": "Hello",
//            "home.teacher_dashboard": "Teacher Dashboard",
//            "home.student_dashboard": "Student Dashboard",
//            "home.latest_news": "Latest University News",
//            
//            // Settings
//            "settings.title": "Settings",
//            "settings.preferences": "Preferences",
//            "settings.dark_mode": "Dark Mode",
//            "settings.notifications": "Notifications",
//            "settings.language": "Language",
//            "settings.data": "Data",
//            "settings.clear_cache": "Clear Cache",
//            "settings.sync_data": "Sync Data",
//            "settings.about": "About",
//            "settings.version": "Version",
//            "settings.privacy_policy": "Privacy Policy",
//            "settings.terms": "Terms of Service",
//            "settings.support": "Support",
//            "settings.logout": "Logout",
//            "settings.logout_message": "Are you sure you want to logout?",
//            "settings.cancel": "Cancel",
//            
//            // Login
//            "login.title": "ElectiveFlow",
//            "login.name": "Name",
//            "login.email": "Email",
//            "login.password": "Password",
//            "login.i_am": "I am a",
//            "login.teacher": "Teacher",
//            "login.student": "Student",
//            "login.login": "Login",
//            "login.sign_up": "Sign Up",
//            "login.have_account": "Already have an account?",
//            "login.no_account": "Don't have an account?",
//            "login.error": "Error",
//            "login.ok": "OK",
//            "login.fill_fields": "Please fill in all fields",
//            "login.enter_name": "Please enter your name",
//            
//            // Onboarding
//            "onboarding.welcome.title": "Welcome to ElectiveFlow",
//            "onboarding.welcome.description": "Manage electives with ease.",
//            "onboarding.teachers.title": "For Teachers",
//            "onboarding.teachers.description": "Create and manage your elective courses.\nTrack student registrations in real time.",
//            "onboarding.analytics.title": "Smart Analytics",
//            "onboarding.analytics.description": "See trends, predict demand, optimize groups.",
//            "onboarding.students.title": "For Students",
//            "onboarding.students.description": "Choose your electives effortlessly.\nGet personalized recommendations.",
//            "onboarding.next": "Next",
//            "onboarding.get_started": "Get Started",
//            
//            // Language
//            "language.ukrainian": "Ukrainian",
//            "language.english": "English",
//        ],
//        
//        "UA": [
//            // TabBar
//            "tab.home": "Головна",
//            "tab.electives": "Вибіркові",
//            "tab.catalog": "Каталог",
//            "tab.news": "Новини",
//            "tab.settings": "Налаштування",
//            
//            // Home
//            "home.hello": "Привіт",
//            "home.teacher_dashboard": "Панель викладача",
//            "home.student_dashboard": "Панель студента",
//            "home.latest_news": "Останні новини університету",
//            
//            // Settings
//            "settings.title": "Налаштування",
//            "settings.preferences": "Налаштування",
//            "settings.dark_mode": "Темний режим",
//            "settings.notifications": "Сповіщення",
//            "settings.language": "Мова",
//            "settings.data": "Дані",
//            "settings.clear_cache": "Очистити кеш",
//            "settings.sync_data": "Синхронізувати дані",
//            "settings.about": "Про додаток",
//            "settings.version": "Версія",
//            "settings.privacy_policy": "Політика конфіденційності",
//            "settings.terms": "Умови використання",
//            "settings.support": "Підтримка",
//            "settings.logout": "Вийти",
//            "settings.logout_message": "Ви впевнені, що хочете вийти?",
//            "settings.cancel": "Скасувати",
//            
//            // Login
//            "login.title": "ElectiveFlow",
//            "login.name": "Ім'я",
//            "login.email": "Email",
//            "login.password": "Пароль",
//            "login.i_am": "Я",
//            "login.teacher": "Викладач",
//            "login.student": "Студент",
//            "login.login": "Увійти",
//            "login.sign_up": "Зареєструватись",
//            "login.have_account": "Вже маєте акаунт?",
//            "login.no_account": "Немає акаунту?",
//            "login.error": "Помилка",
//            "login.ok": "OK",
//            "login.fill_fields": "Будь ласка, заповніть всі поля",
//            "login.enter_name": "Будь ласка, введіть ваше ім'я",
//            
//            // Onboarding
//            "onboarding.welcome.title": "Ласкаво просимо до ElectiveFlow",
//            "onboarding.welcome.description": "Керуйте вибірковими дисциплінами легко.",
//            "onboarding.teachers.title": "Для викладачів",
//            "onboarding.teachers.description": "Створюйте та керуйте вибірковими курсами.\nВідстежуйте реєстрації студентів у реальному часі.",
//            "onboarding.analytics.title": "Розумна аналітика",
//            "onboarding.analytics.description": "Переглядайте тренди, прогнозуйте попит, оптимізуйте групи.",
//            "onboarding.students.title": "Для студентів",
//            "onboarding.students.description": "Обирайте вибіркові дисципліни без зусиль.\nОтримуйте персоналізовані рекомендації.",
//            "onboarding.next": "Далі",
//            "onboarding.get_started": "Почати",
//            
//            // Language
//            "language.ukrainian": "Українська",
//            "language.english": "Англійська",
//        ]
//    ]
//}
//
//// MARK: - View Extension для легкого доступу
//extension View {
//    func localized(_ key: String, language: String) -> String {
//        return L10n.shared.text(key, language: language)
//    }
//}
