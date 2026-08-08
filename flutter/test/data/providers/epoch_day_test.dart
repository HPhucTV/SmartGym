import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/data/providers/data_providers.dart';

/// Hồi quy cho lỗi lệch một ngày ở múi giờ UTC+.
///
/// Bản cũ dựng epoch day bằng `DateTime(y, m, d)` (nửa đêm *giờ địa phương*)
/// rồi chia nguyên `millisecondsSinceEpoch`. Ở UTC+7 thời điểm đó là 17:00 UTC
/// của ngày hôm trước, nên phép chia làm tròn xuống thành epoch day sai, và mọi
/// nơi đọc lại bằng `isUtc: true` đều nhận sai cả ngày lẫn **thứ trong tuần**.
///
/// Các test này không phụ thuộc múi giờ của máy chạy: chúng nạp vào một
/// `DateTime` địa phương dựng sẵn thay vì đọc `DateTime.now()`, nên vẫn bắt
/// được lỗi khi CI chạy ở UTC.
void main() {
  group('epochDayFromLocalDate', () {
    test('giữ đúng ngày dương lịch khi đọc ngược bằng isUtc: true', () {
      // Thứ Năm, 2026-08-06 — ngày phát hiện lỗi.
      final local = DateTime(2026, 8, 6, 22, 30);
      final epochDay = epochDayFromLocalDate(local);
      final roundTripped = dateFromEpochDay(epochDay);

      expect(roundTripped.year, 2026);
      expect(roundTripped.month, 8);
      expect(roundTripped.day, 6);
    });

    test('giữ đúng thứ trong tuần — điều kiện lịch tập dựa vào', () {
      // 2026-08-06 là thứ Năm (weekday == 4).
      final local = DateTime(2026, 8, 6, 22, 30);
      expect(local.weekday, DateTime.thursday);

      final roundTripped = dateFromEpochDay(epochDayFromLocalDate(local));
      expect(roundTripped.weekday, DateTime.thursday);
    });

    test('không đổi giá trị theo giờ trong ngày', () {
      // Bản cũ trả kết quả khác nhau tuỳ giờ so với offset múi giờ; cùng một
      // ngày dương lịch phải luôn cho cùng một epoch day.
      final epochDays = <int>{
        epochDayFromLocalDate(DateTime(2026, 8, 6, 0, 0)),
        epochDayFromLocalDate(DateTime(2026, 8, 6, 12, 0)),
        epochDayFromLocalDate(DateTime(2026, 8, 6, 23, 59, 59)),
      };
      expect(epochDays, hasLength(1));
    });

    test('ngày liên tiếp cho epoch day liên tiếp qua mốc cuối tháng', () {
      final aug31 = epochDayFromLocalDate(DateTime(2026, 8, 31));
      final sep1 = epochDayFromLocalDate(DateTime(2026, 9, 1));
      expect(sep1 - aug31, 1);
    });

    test('bảo toàn thứ trong tuần cho cả bảy ngày của một tuần', () {
      // Bảo vệ trực tiếp cho SchedulePlanner.dueEpochDaysFromWeekdays: nếu thứ
      // bị lệch, buổi tập sẽ được xếp sai ngày.
      for (var day = 5; day <= 11; day++) {
        final local = DateTime(2026, 8, day, 21, 0);
        final roundTripped = dateFromEpochDay(epochDayFromLocalDate(local));
        expect(
          roundTripped.weekday,
          local.weekday,
          reason: 'thứ bị lệch cho ngày 2026-08-$day',
        );
      }
    });

    test('xử lý được ngày trước 1970 mà không lệch do làm tròn về 0', () {
      // Ngày sinh có thể trước epoch; `~/` làm tròn về 0 chứ không phải xuống,
      // nên giá trị âm dễ lệch một ngày.
      final local = DateTime(1960, 6, 15);
      final roundTripped = dateFromEpochDay(epochDayFromLocalDate(local));

      expect(roundTripped.year, 1960);
      expect(roundTripped.month, 6);
      expect(roundTripped.day, 15);
    });
  });

  group('currentLocalEpochDay', () {
    tearDown(() => debugMockEpochDay = null);

    test('khớp với ngày dương lịch địa phương hiện tại', () {
      final now = DateTime.now();
      final roundTripped = dateFromEpochDay(currentLocalEpochDay());

      expect(roundTripped.year, now.year);
      expect(roundTripped.month, now.month);
      expect(roundTripped.day, now.day);
      expect(roundTripped.weekday, now.weekday);
    });

    test('debugMockEpochDay ghi đè được giá trị thật', () {
      debugMockEpochDay = 20671;
      expect(currentLocalEpochDay(), 20671);
    });
  });
}
