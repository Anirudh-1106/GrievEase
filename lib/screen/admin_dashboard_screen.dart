import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

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

  // Add new state variables
  String _selectedStatus = 'All';
  String _selectedCategory = 'All';
  String _selectedMonth = 'All';
  int _selectedYear = DateTime.now().year;

  final List<String> _statusFilters = [
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

  List<String> get _monthFilters {
    final months = ['All'];
    final now = DateTime.now();
    for (int i = 0; i < 12; i++) {
      final month = DateTime(now.year, now.month - i, 1);
      months.add(DateFormat('MMMM yyyy').format(month));
    }
    return months;
  }

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
      final baseUrl = kIsWeb
          ? 'http://localhost:3000'
          : Platform.isAndroid
              ? 'http://10.0.2.2:3000'
              : 'http://localhost:3000';

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
      print('Error fetching dashboard data: $e');
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
          // Wrap the IconButton with Builder
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
    final categoryData = _dashboardData['categoryDistribution'] as List? ?? [];
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
      final value = category['count'].toDouble();
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

  // Modified pie chart method
  Widget _buildPieChartWithLegend() {
    return Column(
      children: [
        // Month filter dropdown
        DropdownButton<String>(
          value: _selectedMonth,
          items: _monthFilters.map((month) {
            return DropdownMenuItem(
              value: month,
              child: Text(month),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedMonth = value!;
            });
          },
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: PieChart(
                  PieChartData(
                    sections: _getFilteredPieChartSections(),
                    sectionsSpace: 2,
                    centerSpaceRadius: 0,
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: _buildFilteredLegend(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<PieChartSectionData> _getFilteredPieChartSections() {
    try {
      final categoryData =
          _dashboardData['categoryDistribution'] as List? ?? [];
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

      final filteredData = _selectedMonth == 'All'
          ? categoryData
          : categoryData.where((category) {
              final complaints = category['complaints'] as List? ?? [];
              return complaints.any((complaint) {
                try {
                  final complaintDate =
                      DateTime.parse(complaint['createdAt'] ?? '');
                  final monthYear =
                      DateFormat('MMMM yyyy').format(complaintDate);
                  return monthYear == _selectedMonth;
                } catch (e) {
                  print('Date parsing error: $e');
                  return false;
                }
              });
            }).toList();

      if (filteredData.isEmpty) {
        return [
          PieChartSectionData(
            color: Colors.grey,
            value: 1,
            title: 'No Data',
            radius: 100,
          )
        ];
      }

      return _generatePieChartSections(filteredData);
    } catch (e) {
      print('Error in _getFilteredPieChartSections: $e');
      return [
        PieChartSectionData(
          color: Colors.grey,
          value: 1,
          title: 'Error',
          radius: 100,
        )
      ];
    }
  }

  List<PieChartSectionData> _generatePieChartSections(List filteredData) {
    return filteredData.map<PieChartSectionData>((category) {
      final color = _getCategoryColor(category['_id']);
      final value = (category['count'] ?? 0).toDouble();
      final total = filteredData.fold(
          0, (sum, item) => sum + (item['count'] as int? ?? 0));
      final percentage = total > 0 ? ((value / total) * 100).round() : 0;

      return PieChartSectionData(
        color: color,
        value: value,
        title: '$percentage%',
        radius: 100,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  Widget _buildFilteredLegend() {
    final categoryData = _dashboardData['categoryDistribution'] as List;
    final total =
        categoryData.fold(0, (sum, item) => sum + (item['count'] as int? ?? 0));

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: categoryData.map((category) {
          final count = category['count'] ?? 0;
          final percentage =
              total > 0 ? ((count / total) * 100).toStringAsFixed(1) : '0.0';
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  color: _getCategoryColor(category['_id']),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category['_id'],
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '$count complaints ($percentage%)',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
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

  // Add helper methods for colors
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
    showDialog(
      context: context,
      builder: (BuildContext context) => StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            child: Container(
              padding: const EdgeInsets.all(24.0),
              width: MediaQuery.of(context).size.width * 0.9,
              height: MediaQuery.of(context).size.height * 0.8,
              child: Column(
                children: [
                  // Month filter dropdown
                  SizedBox(
                    width: 200,
                    child: DropdownButton<String>(
                      value: _selectedMonth,
                      isExpanded: true,
                      hint: const Text('Select Month'),
                      items: _monthFilters.map((month) {
                        return DropdownMenuItem(
                            value: month, child: Text(month));
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedMonth = value!;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Complaints Distribution by Category',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: _buildPieChartWithLegend(),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showExpandedLineChart() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          padding: const EdgeInsets.all(24.0),
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          child: Column(
            children: [
              // Status and Category filters
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: DropdownButton<String>(
                      value: _selectedStatus,
                      isExpanded: true,
                      hint: const Text('Status'),
                      items: _statusFilters.map((status) {
                        return DropdownMenuItem(
                            value: status, child: Text(status));
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedStatus = value!;
                          Navigator.pop(context);
                          _showExpandedLineChart(); // Refresh dialog
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButton<String>(
                      value: _selectedCategory,
                      isExpanded: true,
                      hint: const Text('Category'),
                      items: _categoryFilters.map((category) {
                        return DropdownMenuItem(
                            value: category, child: Text(category));
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value!;
                          Navigator.pop(context);
                          _showExpandedLineChart(); // Refresh dialog
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Title and Legend
              const Text(
                'Monthly Complaint Analysis',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLegendItem('Total', Colors.blue),
                  const SizedBox(width: 20),
                  if (_selectedStatus != 'All')
                    _buildLegendItem(
                        _selectedStatus, _getStatusColor(_selectedStatus)),
                ],
              ),
              const SizedBox(height: 20),
              // Enhanced Line Chart
              Expanded(child: _buildEnhancedLineChart()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(label),
      ],
    );
  }

  Widget _buildEnhancedLineChart() {
    final now = DateTime.now();
    final isCurrentYear = _selectedYear == now.year;
    final monthsToShow = isCurrentYear ? now.month : 12;

    return Column(
      children: [
        // Year filter with instant update
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: DropdownButton<int>(
                  value: _selectedYear,
                  underline: const SizedBox(),
                  onChanged: (value) {
                    setState(() {
                      _selectedYear = value!;
                      _fetchDashboardData(); // Refresh data when year changes
                    });
                  },
                  items: _yearFilters.map((year) {
                    return DropdownMenuItem(
                      value: year,
                      child: Text(
                        year.toString(),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  horizontalInterval: 5, // Set horizontal interval to 5 units
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
                      interval: monthsToShow > 6
                          ? 2
                          : 1, // Adjust interval based on number of months
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
                      interval: 5, // Set vertical interval to 5 units
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
                    spots: _getMonthlySpots(),
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
          ),
        ),
      ],
    );
  }

  List<FlSpot> _getMonthlySpots() {
    final spots = <FlSpot>[];
    final monthlyData = _dashboardData['monthlyComplaints'] as List? ?? [];
    final now = DateTime.now();

    // If it's current year, show only up to current month
    final monthsToShow = _selectedYear == now.year ? now.month : 12;

    for (int i = 0; i < monthsToShow; i++) {
      final monthStr = '$_selectedYear-${(i + 1).toString().padLeft(2, '0')}';
      final monthData = monthlyData.firstWhere(
        (data) => data['_id'] == monthStr,
        orElse: () => {'totalCount': 0},
      );

      int count = 0;
      if (_selectedStatus == 'All' && _selectedCategory == 'All') {
        count = monthData['totalCount'] ?? 0;
      } else {
        final statuses = monthData['statuses'] as List? ?? [];
        count = statuses.where((status) {
          final matchesStatus =
              _selectedStatus == 'All' || status['status'] == _selectedStatus;
          final matchesCategory = _selectedCategory == 'All' ||
              status['category'] == _selectedCategory;
          return matchesStatus && matchesCategory;
        }).fold(
            0, (sum, status) => sum + (status['count'] ?? 0).toInt() as int);
      }

      spots.add(FlSpot(i.toDouble(), count.toDouble()));
    }
    return spots;
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

  // Update the existing build method to use simpler charts in the dashboard
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
            spots:
                _getMonthlySpots(), // Changed from _getFilteredLineChartSpots to _getMonthlySpots
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
}
