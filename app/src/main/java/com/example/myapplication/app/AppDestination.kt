package com.example.myapplication.app

enum class AppDestination(
    val route: String,
    val navigationLabel: String,
    val heading: String,
) {
    ONBOARDING("onboarding", "", "Tạo mục tiêu"),
    TODAY("today", "Hôm nay", "Bài tập hôm nay"),
    PROGRESS("progress", "Tiến độ", "Tiến độ tập luyện"),
    SETTINGS("settings", "Cài đặt", "Cài đặt ứng dụng"),
}
