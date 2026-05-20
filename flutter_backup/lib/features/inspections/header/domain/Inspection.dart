import 'package:epmsa_mobile/features/inspections/header/domain/employee.dart';
import 'package:epmsa_mobile/features/inspections/header/domain/supervisor.dart';

class Inspection {
  int? id;
  String? name;
  DateTime? date;
  DateTime? startTime;
  DateTime? endTime;
  /*int employeeId;
  String employeeName;*/
  final Employee employee;
  final List<Supervisor> supervisors;
  String? operation; // 'arrival' or 'departure'
  String? type; // 'I' or 'D'
  String state; // 'pending' or 'done'
  String? flightType;
  String? dateStr;
  bool planned;
  bool executed;

  Inspection({
    this.id,
    this.name,
    this.date,
    this.startTime,
    this.endTime,
    /*required this.employeeId,
    required this.employeeName,*/
    required this.employee,
    required this.supervisors,
    required this.operation,
    required this.type,
    this.state = 'pending',
    this.flightType = 'passenger',
    this.dateStr,
    this.planned = false,
    this.executed = false,
  });

  factory Inspection.fromJson(Map<String, dynamic> json) {
    return Inspection(
      id: json['id'],
      name: json['name'],
      date: json['date'] != null ? DateTime.parse(json['date']) : null,
      startTime: json['start_time'] != null
          ? DateTime.parse(json['start_time'])
          : null,
      endTime:
          json['end_time'] != null ? DateTime.parse(json['end_time']) : null,
      /*employeeId: json['employee_id'],
      employeeName: json['employee_name'],*/
      employee: Employee.fromJson(json['employee']),
      supervisors: (json['supervisors'] as List<dynamic>)
          .map((s) => Supervisor.fromJson(s))
          .toList(),
      operation: json['operation'],
      type: json['type'] ?? json['type_'],
      state: json['state'] ?? 'pending',
      flightType: json['flight_type'],
      //dateStr: json['date_str'],
      dateStr: "${json['date_str']} ${json['peak_hour'] ?? ''}".trim(),
      planned: json['planned'] ?? false,
      executed: json['executed'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'date': date?.toIso8601String(),
      'start_time': startTime?.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      /*'employee_id': employeeId,
      'employee_name': employeeName,*/
      'employee': employee.toJson(),
      'supervisors': supervisors.map((s) => s.toJson()).toList(),
      'operation': operation,
      'type': type,
      'state': state,
      'flight_type': flightType,
      'date_str': dateStr,
      'planned': planned,
      'executed': executed,
    };
  }

  Inspection copyWithField(String field, dynamic value) {
    throw UnimplementedError(
        'copyWithField no implementado en Inspection base');
  }
}
