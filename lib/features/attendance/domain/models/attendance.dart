import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:church_attendance_app/core/enums/service_type.dart';

part 'attendance.freezed.dart';
part 'attendance.g.dart';

@freezed
sealed class Attendance with _$Attendance {
  const factory Attendance({
    required int id,
    @JsonKey(name: 'contact_id') required int contactId,
    required String phone,
    @JsonKey(name: 'service_type') required ServiceType serviceType,
    @JsonKey(name: 'service_date') required DateTime serviceDate,
    @JsonKey(name: 'recorded_by') required int recordedBy,
    @JsonKey(name: 'recorded_at') required DateTime recordedAt,
    @Default(false) bool isSynced,
    int? serverId,
  }) = _Attendance;

  factory Attendance.fromJson(Map<String, dynamic> json) =>
      _$AttendanceFromJson(json);
}

@freezed
sealed class AttendanceRecord with _$AttendanceRecord {
  const factory AttendanceRecord({
    required Attendance attendance,
    String? contactName,
  }) = _AttendanceRecord;
}
