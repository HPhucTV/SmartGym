package com.example.myapplication.core.achievement

/**
 * All unlockable achievements in SmartGym.
 * Each entry defines the achievement's ID, icon, Vietnamese title/description,
 * and the condition it requires.
 */
enum class AchievementType(
    val icon: String,
    val titleVi: String,
    val descriptionVi: String,
) {
    FIRST_WORKOUT("🔥", "Ngọn Lửa Đầu Tiên", "Hoàn thành buổi tập đầu tiên"),
    STREAK_7("⚡", "Chuỗi 7 Ngày", "Tập luyện 7 ngày liên tiếp"),
    STREAK_14("💎", "Chiến Binh 2 Tuần", "Tập luyện 14 ngày liên tiếp"),
    STREAK_30("👑", "Huyền Thoại 30 Ngày", "Tập luyện 30 ngày liên tiếp"),
    PERFECT_WEEK("🌟", "Tuần Hoàn Hảo", "Đủ số buổi tập mục tiêu trong tuần"),
    HALF_PROGRAM("💪", "Chinh Phục 50%", "Hoàn thành 50% chương trình"),
    FULL_PROGRAM("🎯", "Mục Tiêu Hoàn Thành", "Hoàn thành toàn bộ chương trình"),
    SCAN_10("📸", "Dinh Dưỡng Thông Minh", "Quét 10 món ăn bằng AI"),
    CHECKIN_4("🗓️", "Check-in Đều Đặn", "4 tuần check-in liên tiếp"),
    ALL_MUSCLES("🦾", "Toàn Diện", "Tập đủ tất cả nhóm cơ trong 1 tuần"),
    EARLY_BIRD("🌅", "Chim Sớm", "Tập trước 7 giờ sáng"),
    NIGHT_OWL("🌙", "Cú Đêm", "Tập sau 9 giờ tối"),
    WORKOUTS_10("🏅", "10 Buổi Tập", "Hoàn thành 10 buổi tập"),
    WORKOUTS_50("🏆", "50 Buổi Tập", "Hoàn thành 50 buổi tập"),
    WORKOUTS_100("💯", "100 Buổi Tập", "Hoàn thành 100 buổi tập"),
}
