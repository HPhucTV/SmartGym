package com.example.myapplication.app

enum class AppDestination(
    val route: String,
    val navigationLabel: String,
    val heading: String,
    val iconText: String,
) {
    ONBOARDING("onboarding", "", "Tạo mục tiêu", "🎯"),
    HOME("home", "Hôm nay", "SmartGym Dashboard", "🏠"),
    WORKOUTS("workouts", "", "Bài tập hôm nay", "🏋️"),
    PROGRESS("progress", "Tiến độ", "Tiến độ tập luyện", "📊"),
    SETTINGS("settings", "Cài đặt", "Cài đặt ứng dụng", "⚙️"),
    SEARCH("search", "", "Tra cứu bài tập", "🔍"),
    PROFILE("profile", "", "Thông tin cá nhân", "👤"),
}
