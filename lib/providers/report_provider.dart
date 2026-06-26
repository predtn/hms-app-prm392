import 'package:flutter/material.dart';
import 'package:hms_app/models/dtos/revenue_report.dart';
import 'package:hms_app/services/report_service.dart';

class ReportProvider extends ChangeNotifier {
  ReportProvider({ReportService? service})
    : _service = service ?? ReportService();

  final ReportService _service;

  Future<RevenueReport> getRevenueReport({
    required DateTime fromDate,
    required DateTime toDate,
  }) {
    return _service.getRevenueReport(fromDate: fromDate, toDate: toDate);
  }
}
