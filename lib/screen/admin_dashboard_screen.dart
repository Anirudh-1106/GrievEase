import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  Map<String, dynamic> _dashboardData = {
    'overview': {
      'total': 0,
      'pending': 0,
      'inProgress': 0,
      'resolved': 0,
      'reopened': 0
    },
    'recentComplaints': [],
    'categoryDistribution': []
  };
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _filteredData = [];

  final String _selectedStatus = 'All';
  final String _selectedCategory = 'All';
  final String _selectedMonth = 'All';
  final int _selectedYear = DateTime.now().year;

  static const List<String> _statusFilters = [
    'All',
    'Pending',
    'In Progress',
    'Resolved',
    'Reopened'
  ];

  final List<String> _categoryFilters = [
    'All',
    'Infrastructure',
    'Academics',
    'Administration',
    'Hostel',
    'Others'
  ];

  List<int> get _yearFilters {
    final currentYear = DateTime.now().year;
    return List.generate(5, (index) => currentYear - index);
  }

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    try {
      const String baseUrl = "http://192.168.184.119:3000";

      final response = await http.get(
        Uri.parse('$baseUrl/admin/dashboard'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          setState(() {
            _dashboardData = data['data'];
            _isLoading = false;
            _error = null;
            _updateFilteredData();
          });
        } else {
          throw Exception(data['message'] ?? 'Invalid data format');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
      debugPrint('Error fetching dashboard data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Dashboard Error'),
          backgroundColor: Colors.deepPurple,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: $_error'),
              ElevatedButton(
                onPressed: () => _fetchDashboardData(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final overview = _dashboardData['overview'] ?? {};

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overview Cards
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildOverviewCard(
                    'Total Complaints',
                    overview['total'].toString(),
                    Icons.description,
                    Colors.blue,
                  ),
                  _buildOverviewCard(
                    'Pending',
                    overview['pending'].toString(),
                    Icons.pending,
                    Colors.orange,
                  ),
                  _buildOverviewCard(
                    'In Progress',
                    overview['inProgress'].toString(),
                    Icons.engineering,
                    Colors.amber,
                  ),
                  _buildOverviewCard(
                    'Resolved',
                    overview['resolved'].toString(),
                    Icons.check_circle,
                    Colors.green,
                  ),
                  _buildOverviewCard(
                    'Reopened',
                    overview['reopened'].toString(),
                    Icons.refresh,
                    Colors.red,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Charts
            SizedBox(
              height: 300,
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _showExpandedPieChart(),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              const Text(
                                'Complaints by Category',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Expanded(child: _buildSimplePieChart()),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _showExpandedLineChart(),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              const Text(
                                'Complaints Trend',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Expanded(child: _buildSimpleLineChart()),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Recent Complaints List
            const Text(
              'Recent Complaints',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: (_dashboardData['recentComplaints'] ?? []).length,
              itemBuilder: (context, index) {
                final complaint = _dashboardData['recentComplaints'][index];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getStatusColor(complaint['status']),
                      child: const Icon(Icons.description, color: Colors.white),
                    ),
                    title: Text(complaint['title']),
                    subtitle: Text(
                      '${complaint['category']} • ${complaint['status']}',
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () => _showComplaintDetails(complaint),
                  ),
                );
              },
            ),
          ],
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
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.manage_accounts),
            title: const Text('Grievance Portal'),
            onTap: () {
              Navigator.pushNamed(context, '/complaint-management');
            },
          ),
          ListTile(
            leading: const Icon(Icons.analytics),
            title: const Text('Analysis'),
            onTap: () {
              Navigator.pushNamed(context, '/reports-analytics');
            },
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _getPieChartSections() {
    final categoryData = _filteredData.isNotEmpty
        ? _filteredData
        : (_dashboardData['categoryDistribution'] as List? ?? []);
    if (categoryData.isEmpty) {
      return [
        PieChartSectionData(
          color: Colors.grey,
          value: 1,
          title: 'No Data',
          radius: 100,
        )
      ];
    }
    return categoryData.map((category) {
      final color = _getCategoryColor(category['_id']);
      final value = (category['count'] ?? 0).toDouble();
      return PieChartSectionData(
        color: color,
        value: value,
        title: '${category['count']}',
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  void _updateFilteredData() {
    if (!mounted) return;

    final now = DateTime.now();
    final filteredData = _dashboardData['categoryDistribution'] as List? ?? [];

    List<Map<String, dynamic>> tempData =
        List<Map<String, dynamic>>.from(filteredData);
    if (_selectedMonth != 'All') {
      DateTime startDate;
      switch (_selectedMonth) {
        case 'This Month':
          startDate = DateTime(now.year, now.month, 1);
          break;
        case 'Last Month':
          startDate = DateTime(now.year, now.month - 1, 1);
          break;
        case 'Last 3 Months':
          startDate = DateTime(now.year, now.month - 3, 1);
          break;
        case 'Last 6 Months':
          startDate = DateTime(now.year, now.month - 6, 1);
          break;
        default:
          startDate = DateTime(now.year, now.month, 1);
      }

      tempData = tempData.where((item) {
        if (item['date'] == null) return false;
        try {
          final date = DateTime.parse(item['date']);
          return date.isAfter(startDate) &&
              date.isBefore(now.add(const Duration(days: 1)));
        } catch (_) {
          return false;
        }
      }).toList();
    }

    if (_selectedCategory != 'All') {
      tempData = tempData
          .where((item) => item['category'] == _selectedCategory)
          .toList();
    }

    setState(() {
      _filteredData = tempData;
    });
  }

  Widget _buildSimplePieChart() {
    return AspectRatio(
      aspectRatio: 1,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: PieChart(
          PieChartData(
            sections: _getPieChartSections(),
            sectionsSpace: 2,
            centerSpaceRadius: 30,
            startDegreeOffset: -90,
          ),
        ),
      ),
    );
  }

  Widget _buildSimpleLineChart() {
    final now = DateTime.now();
    final isCurrentYear = _selectedYear == now.year;
    final monthsToShow = isCurrentYear ? now.month : 12;

    return LineChart(
      LineChartData(
        clipData: const FlClipData.all(),
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: _getMonthlySpots(),
            isCurved: true,
            color: _getLineColor(),
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: _getLineColor().withOpacity(0.1),
              cutOffY: 0,
              applyCutOffY: true,
            ),
          ),
        ],
        minX: 0,
        maxX: (monthsToShow - 1).toDouble(),
        minY: 0,
      ),
    );
  }

  List<FlSpot> _getMonthlySpots() {
    try {
      final spots = <FlSpot>[];
      final monthlyData = _dashboardData['monthlyComplaints'] as List? ?? [];
      final now = DateTime.now();
      final monthsToShow = _selectedYear == now.year ? now.month : 12;

      for (int i = 0; i < monthsToShow; i++) {
        final monthStr = '$_selectedYear-${(i + 1).toString().padLeft(2, '0')}';
        final monthData = monthlyData.firstWhere(
          (data) => data['_id'] == monthStr,
          orElse: () => {'totalCount': 0, 'statuses': []},
        );

        double count = 0;
        if (_selectedStatus == 'All' && _selectedCategory == 'All') {
          count = (monthData['totalCount'] ?? 0).toDouble();
        } else {
          final statuses = monthData['statuses'] as List? ?? [];
          count = statuses
              .where((status) =>
                  (_selectedStatus == 'All' ||
                      status['status'] == _selectedStatus) &&
                  (_selectedCategory == 'All' ||
                      status['category'] == _selectedCategory))
              .fold<double>(
                0,
                (sum, status) => sum + (status['count'] ?? 0).toDouble(),
              );
        }
        spots.add(FlSpot(i.toDouble(), count));
      }
      return spots;
    } catch (e) {
      debugPrint('Error generating monthly spots: $e');
      return [const FlSpot(0, 0)];
    }
  }

  Color _getLineColor() {
    switch (_selectedStatus) {
      case 'Pending':
        return Colors.orange;
      case 'In Progress':
        return Colors.blue;
      case 'Resolved':
        return Colors.green;
      case 'Reopened':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  Widget _buildOverviewCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showExpandedPieChart() {
    String dialogSelectedMonth = 'All';
    int dialogSelectedYear = DateTime.now().year;

    List<Map<String, dynamic>> getFilteredData() {
      final allData = List<Map<String, dynamic>>.from(
          _dashboardData['categoryDistribution'] ?? []);
      if (dialogSelectedMonth == 'All') return allData;
      return allData.where((item) {
        if (item['complaints'] == null) return false;
        final complaints = item['complaints'] as List;
        return complaints.any((complaint) {
          try {
            final date = DateTime.parse(complaint['createdAt'] ?? '');
            final monthMatch =
                DateFormat('MMMM').format(date) == dialogSelectedMonth;
            final yearMatch = date.year == dialogSelectedYear;
            return monthMatch && yearMatch;
          } catch (_) {
            return false;
          }
        });
      }).toList();
    }

    final monthsList = [
      'All',
      ...List.generate(12, (i) => DateFormat('MMMM').format(DateTime(0, i + 1)))
    ];
    final yearsList = List.generate(5, (i) => DateTime.now().year - i);

    showDialog(
      context: context,
      builder: (BuildContext context) => StatefulBuilder(
        builder: (context, setState) {
          final filteredData = getFilteredData();
          final hasData = filteredData.isNotEmpty &&
              filteredData.any((cat) => (cat['count'] ?? 0) > 0);

          return Dialog(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Complaints Distribution by Category',
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: dialogSelectedMonth,
                            decoration: const InputDecoration(
                              labelText: 'Month',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                            ),
                            items: monthsList.map((month) {
                              return DropdownMenuItem(
                                value: month,
                                child: Text(month),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                dialogSelectedMonth = value!;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: dialogSelectedYear,
                            decoration: const InputDecoration(
                              labelText: 'Year',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                            ),
                            items: yearsList.map((year) {
                              return DropdownMenuItem(
                                value: year,
                                child: Text(year.toString()),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                dialogSelectedYear = value!;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    hasData
                        ? AspectRatio(
                            aspectRatio: 1.3,
                            child: Card(
                              elevation: 8,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: PieChart(
                                  PieChartData(
                                    sections: _getPieChartSectionsCustom(
                                        filteredData),
                                    sectionsSpace: 3,
                                    centerSpaceRadius: 40,
                                    startDegreeOffset: -90,
                                  ),
                                ),
                              ),
                            ),
                          )
                        : const Padding(
                            padding: EdgeInsets.symmetric(vertical: 32.0),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(Icons.info_outline,
                                      color: Colors.grey, size: 48),
                                  SizedBox(height: 8),
                                  Text(
                                    'No Data',
                                    style: TextStyle(
                                        fontSize: 18, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          ),
                    const SizedBox(height: 16),
                    // Color legend
                    _buildPieChartLegend(filteredData),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPieChartLegend(List<Map<String, dynamic>> data) {
    if (data.isEmpty || data.every((cat) => (cat['count'] ?? 0) == 0)) {
      return const SizedBox.shrink();
    }
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: data.where((cat) => (cat['count'] ?? 0) > 0).map((cat) {
          final color = _getCategoryColor(cat['_id']);
          final label = cat['_id'];
          final count = cat['count'] ?? 0;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              children: [
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.black12),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 8),
                Text(
                  '($count)',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  List<PieChartSectionData> _getPieChartSectionsCustom(
      List<Map<String, dynamic>> data) {
    if (data.isEmpty || data.every((cat) => (cat['count'] ?? 0) == 0)) {
      return [
        PieChartSectionData(
          color: Colors.grey,
          value: 1,
          title: 'No Data',
          radius: 100,
        )
      ];
    }
    return data.where((cat) => (cat['count'] ?? 0) > 0).map((category) {
      final color = _getCategoryColor(category['_id']);
      final value = (category['count'] ?? 0).toDouble();
      return PieChartSectionData(
        color: color,
        value: value,
        title: '${category['count']}',
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  void _showExpandedLineChart() {
    String dialogSelectedStatus = _selectedStatus;
    String dialogSelectedCategory = _selectedCategory;
    int dialogSelectedYear = _selectedYear;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    const Text(
                      'Monthly Complaint Analysis',
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    // Fix overflow: stack dropdowns vertically on small screens
                    LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth < 600) {
                          // Stack vertically for small screens
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildDropdownWithLabel(
                                label: 'Status',
                                value: dialogSelectedStatus,
                                items: _statusFilters,
                                onChanged: (value) {
                                  setState(() {
                                    dialogSelectedStatus = value!;
                                  });
                                },
                              ),
                              const SizedBox(height: 12),
                              _buildDropdownWithLabel(
                                label: 'Category',
                                value: dialogSelectedCategory,
                                items: _categoryFilters,
                                onChanged: (value) {
                                  setState(() {
                                    dialogSelectedCategory = value!;
                                  });
                                },
                              ),
                              const SizedBox(height: 12),
                              _buildDropdownWithLabel(
                                label: 'Year',
                                value: dialogSelectedYear,
                                items: _yearFilters,
                                onChanged: (value) {
                                  setState(() {
                                    dialogSelectedYear = value!;
                                  });
                                },
                                isInt: true,
                              ),
                            ],
                          );
                        } else {
                          // Row for larger screens
                          return Row(
                            children: [
                              Expanded(
                                child: _buildDropdownWithLabel(
                                  label: 'Status',
                                  value: dialogSelectedStatus,
                                  items: _statusFilters,
                                  onChanged: (value) {
                                    setState(() {
                                      dialogSelectedStatus = value!;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildDropdownWithLabel(
                                  label: 'Category',
                                  value: dialogSelectedCategory,
                                  items: _categoryFilters,
                                  onChanged: (value) {
                                    setState(() {
                                      dialogSelectedCategory = value!;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildDropdownWithLabel(
                                  label: 'Year',
                                  value: dialogSelectedYear,
                                  items: _yearFilters,
                                  onChanged: (value) {
                                    setState(() {
                                      dialogSelectedYear = value!;
                                    });
                                  },
                                  isInt: true,
                                ),
                              ),
                            ],
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 350,
                      child: _buildExpandedLineChart(
                        dialogSelectedStatus,
                        dialogSelectedCategory,
                        dialogSelectedYear,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Helper for dropdown with label
  Widget _buildDropdownWithLabel<T>({
    required String label,
    required T value,
    required List items,
    required ValueChanged<T?> onChanged,
    bool isInt = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 2),
          child:
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
        DropdownButtonFormField<T>(
          value: value,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: items.map<DropdownMenuItem<T>>((item) {
            return DropdownMenuItem<T>(
              value: item,
              child: Text(item.toString()),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildExpandedLineChart(String status, String category, int year) {
    final now = DateTime.now();
    final isCurrentYear = year == now.year;
    final monthsToShow = isCurrentYear ? now.month : 12;

    List<FlSpot> getSpots() {
      final spots = <FlSpot>[];
      final monthlyData = _dashboardData['monthlyComplaints'] as List? ?? [];
      for (int i = 0; i < monthsToShow; i++) {
        final monthStr = '$year-${(i + 1).toString().padLeft(2, '0')}';
        final monthData = monthlyData.firstWhere(
          (data) => data['_id'] == monthStr,
          orElse: () => {'totalCount': 0, 'statuses': []},
        );
        double count = 0;
        if (status == 'All' && category == 'All') {
          count = (monthData['totalCount'] ?? 0).toDouble();
        } else {
          final statuses = monthData['statuses'] as List? ?? [];
          count = statuses
              .where((s) =>
                  (status == 'All' || s['status'] == status) &&
                  (category == 'All' || s['category'] == category))
              .fold<double>(
                0,
                (sum, s) => sum + (s['count'] ?? 0).toDouble(),
              );
        }
        spots.add(FlSpot(i.toDouble(), count));
      }
      return spots;
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            horizontalInterval: 5,
            verticalInterval: 1,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.grey.shade200,
              strokeWidth: 1,
            ),
            getDrawingVerticalLine: (value) => FlLine(
              color: Colors.grey.shade200,
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: monthsToShow > 6 ? 2 : 1,
                getTitlesWidget: (value, meta) {
                  if (value >= 0 && value < monthsToShow) {
                    const months = [
                      'Jan',
                      'Feb',
                      'Mar',
                      'Apr',
                      'May',
                      'Jun',
                      'Jul',
                      'Aug',
                      'Sep',
                      'Oct',
                      'Nov',
                      'Dec'
                    ];
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        months[value.toInt()],
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                interval: 5,
                getTitlesWidget: (value, meta) {
                  if (value == value.roundToDouble()) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Text(
                        value.toInt().toString(),
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade300, width: 1),
              left: BorderSide(color: Colors.grey.shade300, width: 1),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: getSpots(),
              isCurved: true,
              preventCurveOverShooting: true,
              color: _getLineColor(),
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: Colors.white,
                    strokeWidth: 2,
                    strokeColor: _getLineColor(),
                  );
                },
                checkToShowDot: (spot, barData) => true,
              ),
              belowBarData: BarAreaData(
                show: true,
                color: _getLineColor().withOpacity(0.1),
                cutOffY: 0,
                applyCutOffY: true,
              ),
            ),
          ],
          minX: 0,
          maxX: (monthsToShow - 1).toDouble(),
          minY: 0,
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              tooltipPadding: const EdgeInsets.all(8),
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((touchedSpot) {
                  return LineTooltipItem(
                    '${touchedSpot.y}',
                    const TextStyle(color: Colors.white),
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }

  void _showComplaintDetails(Map<String, dynamic> complaint) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Complaint Details',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildDetailRow('ID', complaint['complaintId']),
              _buildDetailRow('Category', complaint['category']),
              _buildDetailRow('Status', complaint['status']),
              _buildDetailRow('Title', complaint['title']),
              _buildDetailRow('Description', complaint['description']),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
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

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Infrastructure':
        return Colors.blue;
      case 'Academics':
        return Colors.green;
      case 'Administration':
        return Colors.orange;
      case 'Hostel':
        return Colors.purple;
      case 'Others':
        return Colors.grey;
      default:
        return Colors.blueGrey;
    }
  }
}
