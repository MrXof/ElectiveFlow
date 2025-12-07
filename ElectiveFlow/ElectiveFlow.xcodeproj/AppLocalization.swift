import Foundation

class AppLocalization {
    static let shared = AppLocalization()
    
    private init() {}
    
    // MARK: - Common
    func text(_ key: String, language: String) -> String {
        return translations[language]?[key] ?? translations["EN"]?[key] ?? key
    }
    
    private let translations: [String: [String: String]] = [
        "EN": [
            // TabBar
            "tab.home": "Home",
            "tab.electives": "Electives",
            "tab.catalog": "Catalog",
            "tab.news": "News",
            "tab.settings": "Settings",
            
            // Home
            "home.hello": "Hello",
            "home.teacher_dashboard": "Teacher Dashboard",
            "home.student_dashboard": "Student Dashboard",
            "home.latest_news": "Latest University News",
            
            // Home - Teacher Dashboard
            "home.analytics_snapshot": "Analytics Snapshot",
            "home.total_students": "Total Students",
            "home.your_electives": "Your Electives",
            "home.see_all": "See All",
            "home.no_electives": "No electives yet",
            "home.create_first": "Create First Elective",
            
            // Home - Student Dashboard
            "home.recommended": "Recommended for You",
            "home.complete_profile": "Complete your profile to get recommendations",
            "home.my_electives": "My Electives",
            "home.no_registrations": "No registrations yet",
            "home.browse_catalog": "Browse Catalog",
            
            // Electives
            "electives.title": "Electives",
            "electives.my_electives": "My Electives",
            "electives.search": "Search electives",
            "electives.all": "All",
            "electives.students": "students",
            "electives.registration": "Registration",
            
            // News
            "news.title": "News",
            "news.university_news": "University News",
            "news.loading": "Loading news...",
            
            // Settings
            "settings.title": "Settings",
            "settings.preferences": "Preferences",
            "settings.dark_mode": "Dark Mode",
            "settings.notifications": "Notifications",
            "settings.language": "Language",
            "settings.data": "Data",
            "settings.clear_cache": "Clear Cache",
            "settings.sync_data": "Sync Data",
            "settings.about": "About",
            "settings.version": "Version",
            "settings.privacy_policy": "Privacy Policy",
            "settings.terms": "Terms of Service",
            "settings.support": "Support",
            "settings.logout": "Logout",
            "settings.logout_message": "Are you sure you want to logout?",
            "settings.cancel": "Cancel",
            
            // Login
            "login.title": "ElectiveFlow",
            "login.name": "Name",
            "login.email": "Email",
            "login.password": "Password",
            "login.i_am": "I am a",
            "login.teacher": "Teacher",
            "login.student": "Student",
            "login.login": "Login",
            "login.sign_up": "Sign Up",
            "login.have_account": "Already have an account?",
            "login.no_account": "Don't have an account?",
            "login.error": "Error",
            "login.ok": "OK",
            "login.fill_fields": "Please fill in all fields",
            "login.enter_name": "Please enter your name",
            
            // Onboarding
            "onboarding.welcome.title": "Welcome to ElectiveFlow",
            "onboarding.welcome.description": "Manage electives with ease.",
            "onboarding.teachers.title": "For Teachers",
            "onboarding.teachers.description": "Create and manage your elective courses.\nTrack student registrations in real time.",
            "onboarding.analytics.title": "Smart Analytics",
            "onboarding.analytics.description": "See trends, predict demand, optimize groups.",
            "onboarding.students.title": "For Students",
            "onboarding.students.description": "Choose your electives effortlessly.\nGet personalized recommendations.",
            "onboarding.next": "Next",
            "onboarding.get_started": "Get Started",
            
            // Registration Status
            "status.confirmed": "Confirmed",
            "status.pending": "Pending",
            "status.waitlist": "Waitlist",
            
            // Months
            "month.january": "January",
            "month.february": "February",
            "month.march": "March",
            "month.april": "April",
            "month.may": "May",
            "month.june": "June",
            "month.july": "July",
            "month.august": "August",
            "month.september": "September",
            "month.october": "October",
            "month.november": "November",
            "month.december": "December",
            
            // Periods
            "period.fall": "Fall",
            "period.spring": "Spring",
            "period.summer": "Summer",
            
            // Language
            "language.ukrainian": "Ukrainian",
            "language.english": "English",
        ],
        
        "UA": [
            // TabBar
            "tab.home": "Головна",
            "tab.electives": "Вибіркові",
            "tab.catalog": "Каталог",
            "tab.news": "Новини",
            "tab.settings": "Налаштування",
            
            // Home
            "home.hello": "Привіт",
            "home.teacher_dashboard": "Панель викладача",
            "home.student_dashboard": "Панель студента",
            "home.latest_news": "Останні новини університету",
            
            // Home - Teacher Dashboard
            "home.analytics_snapshot": "Аналітика",
            "home.total_students": "Всього студентів",
            "home.your_electives": "Ваші вибіркові",
            "home.see_all": "Всі",
            "home.no_electives": "Ще немає вибіркових",
            "home.create_first": "Створити першу вибіркову",
            
            // Home - Student Dashboard
            "home.recommended": "Рекомендовані для вас",
            "home.complete_profile": "Заповніть профіль для отримання рекомендацій",
            "home.my_electives": "Мої вибіркові",
            "home.no_registrations": "Ще немає реєстрацій",
            "home.browse_catalog": "Переглянути каталог",
            
            // Electives
            "electives.title": "Вибіркові",
            "electives.my_electives": "Мої вибіркові",
            "electives.search": "Пошук вибіркових",
            "electives.all": "Всі",
            "electives.students": "студентів",
            "electives.registration": "Реєстрація",
            
            // News
            "news.title": "Новини",
            "news.university_news": "Новини університету",
            "news.loading": "Завантаження новин...",
            
            // Settings
            "settings.title": "Налаштування",
            "settings.preferences": "Налаштування",
            "settings.dark_mode": "Темний режим",
            "settings.notifications": "Сповіщення",
            "settings.language": "Мова",
            "settings.data": "Дані",
            "settings.clear_cache": "Очистити кеш",
            "settings.sync_data": "Синхронізувати дані",
            "settings.about": "Про додаток",
            "settings.version": "Версія",
            "settings.privacy_policy": "Політика конфіденційності",
            "settings.terms": "Умови використання",
            "settings.support": "Підтримка",
            "settings.logout": "Вийти",
            "settings.logout_message": "Ви впевнені, що хочете вийти?",
            "settings.cancel": "Скасувати",
            
            // Login
            "login.title": "ElectiveFlow",
            "login.name": "Ім'я",
            "login.email": "Email",
            "login.password": "Пароль",
            "login.i_am": "Я",
            "login.teacher": "Викладач",
            "login.student": "Студент",
            "login.login": "Увійти",
            "login.sign_up": "Зареєструватись",
            "login.have_account": "Вже маєте акаунт?",
            "login.no_account": "Немає акаунту?",
            "login.error": "Помилка",
            "login.ok": "OK",
            "login.fill_fields": "Будь ласка, заповніть всі поля",
            "login.enter_name": "Будь ласка, введіть ваше ім'я",
            
            // Onboarding
            "onboarding.welcome.title": "Ласкаво просимо до ElectiveFlow",
            "onboarding.welcome.description": "Керуйте вибірковими дисциплінами легко.",
            "onboarding.teachers.title": "Для викладачів",
            "onboarding.teachers.description": "Створюйте та керуйте вибірковими курсами.\nВідстежуйте реєстрації студентів у реальному часі.",
            "onboarding.analytics.title": "Розумна аналітика",
            "onboarding.analytics.description": "Переглядайте тренди, прогнозуйте попит, оптимізуйте групи.",
            "onboarding.students.title": "Для студентів",
            "onboarding.students.description": "Обирайте вибіркові дисципліни без зусиль.\nОтримуйте персоналізовані рекомендації.",
            "onboarding.next": "Далі",
            "onboarding.get_started": "Почати",
            
            // Registration Status
            "status.confirmed": "Підтверджено",
            "status.pending": "Очікується",
            "status.waitlist": "Лист очікування",
            
            // Months
            "month.january": "Січень",
            "month.february": "Лютий",
            "month.march": "Березень",
            "month.april": "Квітень",
            "month.may": "Травень",
            "month.june": "Червень",
            "month.july": "Липень",
            "month.august": "Серпень",
            "month.september": "Вересень",
            "month.october": "Жовтень",
            "month.november": "Листопад",
            "month.december": "Грудень",
            
            // Periods
            "period.fall": "Осінь",
            "period.spring": "Весна",
            "period.summer": "Літо",
            
            // Language
            "language.ukrainian": "Українська",
            "language.english": "Англійська",
        ]
    ]
}
