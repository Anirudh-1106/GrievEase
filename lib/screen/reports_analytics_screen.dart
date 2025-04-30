import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'dart:io';

class ReportsAnalyticsScreen extends StatefulWidget {
  const ReportsAnalyticsScreen({super.key});

  @override
  State<ReportsAnalyticsScreen> createState() => _ReportsAnalyticsScreenState();
}

class _ReportsAnalyticsScreenState extends State<ReportsAnalyticsScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
  String _selectedCategory = 'All';
  String _selectedStatus = 'All';
  bool _isLoading = false;
  String? _error;
  List<Map<String, dynamic>> _reportData = [];
  Map<String, dynamic> _analytics = {};

  final List<String> _categories = [
    'All',
    'Infrastructure',
    'Academics',
    'Administration',
    'Hostel',
    'Others'
  ];

  final List<String> _statuses = [
    'All',
    'Pending',
    'In Progress',
    'Resolved',
    'Reopened'
  ];

  Future<void> _generateReport() async {
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select both start and end dates'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_endDate!.isBefore(_startDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('End date must be after start date'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      const String baseUrl = "http://192.168.184.119:3000"; // Updated base URL

      // Adjust dates to include full days
      final startDate =
          DateTime(_startDate!.year, _startDate!.month, _startDate!.day);
      final endDate =
          DateTime(_endDate!.year, _endDate!.month, _endDate!.day, 23, 59, 59);

      final queryParams = {
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'status': _selectedStatus != 'All' ? _selectedStatus : '',
        'category': _selectedCategory != 'All' ? _selectedCategory : '',
      };

      final uri = Uri.parse('$baseUrl/reports/generate').replace(
        queryParameters:
            queryParams.map((key, value) => MapEntry(key, value.toString()))
              ..removeWhere((key, value) => value.isEmpty),
      );

      final response = await http.get(
        uri,
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            _reportData = List<Map<String, dynamic>>.from(
                data['complaints'] as List? ?? []);
            _analytics =
                Map<String, dynamic>.from(data['analytics'] as Map? ?? {});
            _isLoading = false;
          });
        } else {
          throw Exception(data['message'] ?? 'Failed to generate report');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
        _reportData = [];
        _analytics = {};
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _exportToPDF() async {
    if (_reportData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No data to export')),
      );
      return;
    }

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text('Complaints Report',
                style:
                    pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
          ),
          pw.Table.fromTextArray(
            context: context,
            data: <List<String>>[
              // Header row with all columns
              ['ID', 'Title', 'Category', 'Status', 'Date Registered'],
              // Data rows
              ..._reportData.map((complaint) => [
                    complaint['complaintId'],
                    complaint['title'],
                    complaint['category'],
                    complaint['status'],
                    DateFormat('MMM dd, yyyy')
                        .format(DateTime.parse(complaint['createdAt'])),
                  ])
            ],
            // Customize header style
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColors.blue600,
            ),
            // Adjust column widths
            columnWidths: {
              0: const pw.FlexColumnWidth(2), // ID
              1: const pw.FlexColumnWidth(4), // Title
              2: const pw.FlexColumnWidth(2), // Category
              3: const pw.FlexColumnWidth(2), // Status
              4: const pw.FlexColumnWidth(2), // Date
            },
            // Add alternating row colors
            oddRowDecoration: const pw.BoxDecoration(
              color: PdfColors.grey100,
            ),
          ),
        ],
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File('${output.path}/complaints_report.pdf');
    await file.writeAsBytes(await pdf.save());

    OpenFilex.open(file.path);
  }

  Widget _buildAnalyticsCharts() {
    if (_analytics.isEmpty) return const SizedBox();

    return Column(
      children: [
        Card(
          elevation: 8,
          margin: const EdgeInsets.all(16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Status Distribution',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF4A47A3),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Total Complaints: ${_analytics['totalComplaints'] ?? 0}',
                  style: GoogleFonts.roboto(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 300,
                  child: PieChart(
                    PieChartData(
                      sections: _buildStatusPieSections(),
                      sectionsSpace: 4,
                      centerSpaceRadius: 40,
                      centerSpaceColor: Colors.white,
                      borderData: FlBorderData(show: false),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildPieChartLegend(),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Card(
          elevation: 8,
          margin: const EdgeInsets.all(16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Complaints Timeline',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF4A47A3),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 300,
                  child: _buildEnhancedLineChart(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<PieChartSectionData> _buildStatusPieSections() {
    final statusData =
        List<Map<String, dynamic>>.from(_analytics['statusDistribution'] ?? []);
    if (statusData.isEmpty) {
      return [
        PieChartSectionData(
          color: Colors.grey,
          value: 1,
          title: 'No Data',
          radius: 100,
        )
      ];
    }

    final total =
        statusData.fold(0, (sum, item) => sum + (item['count'] as int? ?? 0));

    return statusData.map((status) {
      final count = status['count'] as int;
      final percentage = total > 0 ? (count / total * 100).round() : 0;
      return PieChartSectionData(
        color: _getStatusColor(status['_id']),
        value: count.toDouble(),
        title: '$percentage%',
        radius: 100,
        titleStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      );
    }).toList();
  }

  List<FlSpot> _buildTimelineSpots() {
    final timelineData =
        List<Map<String, dynamic>>.from(_analytics['timelineData'] ?? []);
    if (timelineData.isEmpty || _startDate == null) return [const FlSpot(0, 0)];

    // Create a map to store counts by date
    final Map<DateTime, double> dateCounts = {};

    // Fill in actual counts from timeline data
    for (var point in timelineData) {
      final date = DateTime.parse(point['_id']).toLocal();
      dateCounts[DateTime(date.year, date.month, date.day)] =
          (point['count'] as num).toDouble();
    }

    // Convert to spots based on days since start
    List<FlSpot> spots = [];
    int index = 0;
    for (DateTime date = _startDate!;
        !date.isAfter(_endDate!);
        date = date.add(const Duration(days: 1))) {
      final normalized = DateTime(date.year, date.month, date.day);
      spots.add(FlSpot(
        index.toDouble(),
        dateCounts[normalized] ?? 0,
      ));
      index++;
    }

    return spots;
  }

  Widget _buildPieChartLegend() {
    final statusData =
        List<Map<String, dynamic>>.from(_analytics['statusDistribution'] ?? []);
    if (statusData.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: statusData.map((status) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.circle,
              size: 12,
              color: _getStatusColor(status['_id']),
            ),
            const SizedBox(width: 6),
            Text(
              status['_id'],
              style: GoogleFonts.roboto(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '(${status['count']})',
              style: GoogleFonts.roboto(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildEnhancedLineChart() {
    if (_startDate == null || _endDate == null) return const SizedBox();

    final daysBetween = _endDate!.difference(_startDate!).inDays;

    // Ensure all FlSpot points are sorted and have non-negative Y-values
    final spots = _buildTimelineSpots()..sort((a, b) => a.x.compareTo(b.x));

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width:
            daysBetween * 40.0, // Dynamically adjust width based on data points
        child: LineChart(
          LineChartData(
            minY: 0, // Lock the baseline to Y=0
            gridData: FlGridData(
              show: true,
              drawVerticalLine: true,
              horizontalInterval: 5,
              verticalInterval: 1,
              getDrawingHorizontalLine: (value) => FlLine(
                color: Colors.grey.shade300,
                strokeWidth: 1,
              ),
              getDrawingVerticalLine: (value) => FlLine(
                color: Colors.grey.shade300,
                strokeWidth: 1,
              ),
            ),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 32,
                  interval: 1,
                  getTitlesWidget: (value, meta) {
                    if (value < 0 || value > daysBetween) {
                      return const SizedBox.shrink();
                    }
                    final date = _startDate!.add(Duration(days: value.toInt()));
                    return SideTitleWidget(
                      meta: meta,
                      child: Transform.rotate(
                        angle: -0.5, // Rotate ~30 degrees
                        child: Text(
                          DateFormat('MMM d').format(date),
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    );
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: (value, meta) {
                    if (value % 1 != 0) return const SizedBox.shrink();
                    return Text(
                      value.toInt().toString(),
                      style: const TextStyle(fontSize: 10),
                    );
                  },
                ),
              ),
            ),
            minX: 0,
            maxX: daysBetween.toDouble(),
            borderData: FlBorderData(
              show: true,
              border: Border.all(color: Colors.grey.shade300, width: 1),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                curveSmoothness: 0.05, // Reduce overshooting
                gradient: const LinearGradient(
                  colors: [Color(0xFF4A47A3), Color(0xFF6A61D1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                barWidth: 3,
                belowBarData: BarAreaData(
                  show: true,
                  applyCutOffY:
                      true, // Prevent shaded area from going below Y=0
                  cutOffY: 0,
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF4A47A3).withOpacity(0.1),
                      const Color(0xFF6A61D1).withOpacity(0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) {
                    return FlDotCirclePainter(
                      radius: 4,
                      color: Colors.white,
                      strokeWidth: 2,
                      strokeColor: const Color(0xFF4A47A3),
                    );
                  },
                ),
              ),
            ],
            lineTouchData: LineTouchData(
              enabled: true,
              touchTooltipData: LineTouchTooltipData(
                tooltipPadding: const EdgeInsets.all(8),
                tooltipMargin: 8,
                getTooltipItems: (touchedSpots) {
                  return touchedSpots.map((spot) {
                    final date =
                        _startDate!.add(Duration(days: spot.x.toInt()));
                    return LineTooltipItem(
                      '${DateFormat('MMM d').format(date)}\n${spot.y.toInt()} complaints',
                      const TextStyle(
                        color: Colors.black,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  }).toList();
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.deepPurple,
            ),
            child: Text(
              'Admin Menu',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/admin-dashboard');
            },
          ),
          ListTile(
            leading: const Icon(Icons.manage_accounts),
            title: const Text('Grievance Portal'),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/complaint-management');
            },
          ),
          ListTile(
            leading: const Icon(Icons.analytics),
            title: const Text('Analysis'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Analytics'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
      ),
      drawer: _buildDrawer(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Report Filters',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: _startDate ?? DateTime.now(),
                                firstDate: DateTime.now()
                                    .subtract(const Duration(days: 365)),
                                lastDate: DateTime.now(),
                              );
                              if (date != null) {
                                setState(() => _startDate = date);
                              }
                            },
                            icon: const Icon(Icons.calendar_today),
                            label: Text(_startDate == null
                                ? 'Start Date'
                                : DateFormat('MMM dd, yyyy')
                                    .format(_startDate!)),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: _endDate ?? DateTime.now(),
                                firstDate: DateTime.now()
                                    .subtract(const Duration(days: 365)),
                                lastDate: DateTime.now(),
                              );
                              if (date != null) {
                                setState(() => _endDate = date);
                              }
                            },
                            icon: const Icon(Icons.calendar_today),
                            label: Text(_endDate == null
                                ? 'End Date'
                                : DateFormat('MMM dd, yyyy').format(_endDate!)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedCategory,
                            decoration: const InputDecoration(
                              labelText: 'Category',
                              border: OutlineInputBorder(),
                            ),
                            items: _categories
                                .map((category) => DropdownMenuItem(
                                      value: category,
                                      child: Text(category),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              setState(() => _selectedCategory = value!);
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedStatus,
                            decoration: const InputDecoration(
                              labelText: 'Status',
                              border: OutlineInputBorder(),
                            ),
                            items: _statuses
                                .map((status) => DropdownMenuItem(
                                      value: status,
                                      child: Text(status),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              setState(() => _selectedStatus = value!);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _generateReport,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
                              foregroundColor: Colors.white,
                            ),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Generate Report'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          onPressed: _exportToPDF,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(Icons.picture_as_pdf),
                          label: const Text('Export PDF'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_error != null)
              Center(
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            if (!_isLoading && _reportData.isNotEmpty) _buildAnalyticsCharts(),
            const SizedBox(height: 16),
            // Results Section
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _reportData.isEmpty
                    ? const Center(
                        child: Text('Generate a report to view results'))
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _reportData.length,
                        itemBuilder: (context, index) {
                          final complaint = _reportData[index];
                          return Card(
                            child: ListTile(
                              title: Text(complaint['title']),
                              subtitle: Text(
                                '${complaint['category']} • ${complaint['status']}\n'
                                'ID: ${complaint['complaintId']}',
                              ),
                              trailing: Icon(
                                _getStatusIcon(complaint['status']),
                                color: _getStatusColor(complaint['status']),
                              ),
                            ),
                          );
                        },
                      ),
          ],
        ),
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Pending':
        return Icons.hourglass_empty;
      case 'In Progress':
        return Icons.engineering;
      case 'Resolved':
        return Icons.check_circle;
      case 'Reopened':
        return Icons.refresh;
      default:
        return Icons.info;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.orange;
      case 'In Progress':
        return Colors.blue;
      case 'Resolved':
        return Colors.green;
      case 'Reopened':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
