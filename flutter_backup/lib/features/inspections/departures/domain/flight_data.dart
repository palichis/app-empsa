import 'dart:convert';

import 'package:epmsa_mobile/features/inspections/departures/domain/flight_option.dart';
import 'package:flutter/foundation.dart';

class FlightData {
  final int? flightCount;
  final int? flightPaxNumber;
  //final List<FlightOption>? flightNumbers;
  //final List<dynamic>? flightCheckCounterNumber;
  //final List<dynamic>? flightPreboardingRoom;
  final String? flightScheduledTime;
  final String? flightActualDepartureTime;

  FlightData({
    this.flightCount,
    this.flightPaxNumber,
    //this.flightNumbers,
    //this.flightCheckCounterNumber,
    //this.flightPreboardingRoom,
    this.flightScheduledTime,
    this.flightActualDepartureTime,
  });

  factory FlightData.fromJson(Map<String, dynamic> json) {
    return FlightData(
      flightCount: int.tryParse('${json['flight_count']}') ?? 0,
      flightPaxNumber: int.tryParse('${json['flight_pax_number']}') ?? 0,
      flightScheduledTime: json['flight_scheduled_time'],
      flightActualDepartureTime: json['flight_actual_departure_time'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'flight_count': flightCount,
      'flight_pax_number': flightPaxNumber,
      //'flight_number': flightNumbers!.map((e) => e.toJson()).toList(),
      //'flight_check_counter_number': flightCheckCounterNumber,
      //'flight_preboarding_room': flightPreboardingRoom,
      'flight_scheduled_time': flightScheduledTime,
      'flight_actual_departure_time': flightActualDepartureTime,
    };
  }
}
