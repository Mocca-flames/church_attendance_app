import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:church_attendance_app/core/enums/service_type.dart';

part 'attendance.freezed.dart';
part 'attendance.g.dart';

@freezed
sealed class Attendance with _$Attendance {
  const factory Attendance({
    required int id,
    int? serverId,
    required int contactId,
    required String phone,
    required ServiceType serviceType,
    required DateTime serviceDate,
    required int recordedBy,
    required DateTime recordedAt,
    @Default(false) bool isSynced,
  }) = _Attendance;

  factory Attendance.fromJson(Map<String, dynamic> json) =>
      _$AttendanceFromJson(json);
}

@freezed
class AttendanceRecord with _$AttendanceRecord {
  const factory AttendanceRecord({
    required Attendance attendance,
    String? contactName,
  }) = _AttendanceRecord;
}
