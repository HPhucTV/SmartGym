package com.example.myapplication.app

enum class AppDestination(
    val route: String,
    val navigationLabel: String,
    val heading: String,
    val iconText: String,
) {
    ONBOARDING("onboarding", "", "Tạo mục tiêu", "🎯"),
    HOME("home", "Trang chủ", "SmartGym Dashboard", "🏠"),
    WORKOUTS("workouts", "Bài tập", "Bài tập hôm nay", "🏋️"),
    PROGRESS("progress", "Tiến độ", "Tiến độ tập luyện", "📊"),
    SEARCH("search", "Tra cứu", "Tra cứu bài tập", "🔍"),
    PROFILE("profile", "Cá nhân", "Thông tin cá nhân", "👤"),
}
