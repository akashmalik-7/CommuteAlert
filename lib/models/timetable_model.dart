class TimetableModel {
  const TimetableModel({
    required this.timetableId,
    required this.routeId,
    required this.departureTime,
    required this.arrivalTime,
    required this.operatingDays,
  });

  final String timetableId;
  final String routeId;
  final String departureTime;
  final String arrivalTime;
  final List<String> operatingDays;
}
