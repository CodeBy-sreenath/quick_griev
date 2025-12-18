import 'package:flutter/material.dart';

class AdminDashboard extends StatefulWidget {
  final Map<String, dynamic>? adminData;
  const AdminDashboard({Key? key, this.adminData}) : super(key: key);

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  String selectedDepartment = 'All';
  List<Map<String, dynamic>> complaints = [];
  bool isLoading = false;
  String? selectedComplaintId;
  final TextEditingController messageController = TextEditingController();

  final List<String> departments = [
    'All',
    'Police',
    'Health',
    'Electricity',
    'Water',
    'Municipality',
    'Transport',
  ];

  // Dummy complaint data
  final List<Map<String, dynamic>> dummyComplaints = [
    {
      '_id': '1',
      'complaintText': 'Road accident on Main Street, immediate assistance needed',
      'priority': 'high',
      'department': 'Police',
      'userId': 'user_123',
      'status': 'Received',
    },
    {
      '_id': '2',
      'complaintText': 'Fire emergency in building A, block 5',
      'priority': 'high',
      'department': 'Health',
      'userId': 'user_456',
      'status': 'Received',
    },
    {
      '_id': '3',
      'complaintText': 'Power outage in residential area for 3 hours',
      'priority': 'medium',
      'department': 'Electricity',
      'userId': 'user_789',
      'status': 'In Progress',
    },
    {
      '_id': '4',
      'complaintText': 'Water supply disruption since morning',
      'priority': 'medium',
      'department': 'Water',
      'userId': 'user_101',
      'status': 'Received',
    },
    {
      '_id': '5',
      'complaintText': 'Garbage collection not done for 2 days',
      'priority': 'low',
      'department': 'Municipality',
      'userId': 'user_102',
      'status': 'Received',
    },
    {
      '_id': '6',
      'complaintText': 'Large pothole on highway causing traffic issues',
      'priority': 'medium',
      'department': 'Transport',
      'userId': 'user_103',
      'status': 'Received',
    },
    {
      '_id': '7',
      'complaintText': 'Street light not working in park area',
      'priority': 'low',
      'department': 'Municipality',
      'userId': 'user_104',
      'status': 'Resolved',
    },
    {
      '_id': '8',
      'complaintText': 'Violent incident reported near market area',
      'priority': 'high',
      'department': 'Police',
      'userId': 'user_105',
      'status': 'In Progress',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadComplaints();
  }

  Future<void> _loadComplaints() async {
    setState(() => isLoading = true);
    
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));
    
    try {
      List<Map<String, dynamic>> filteredComplaints = dummyComplaints;
      
      // Filter by department if not 'All'
      if (selectedDepartment != 'All') {
        filteredComplaints = dummyComplaints
            .where((complaint) => complaint['department'] == selectedDepartment)
            .toList();
      }
      
      setState(() {
        complaints = filteredComplaints;
        // Sort by priority: high > medium > low
        complaints.sort((a, b) {
          const priority = {'high': 3, 'medium': 2, 'low': 1};
          return (priority[b['priority']] ?? 0)
              .compareTo(priority[a['priority']] ?? 0);
        });
      });
      
      _showSnackBar('Complaints loaded successfully', Colors.green);
    } catch (e) {
      _showSnackBar('Error loading complaints: $e', Colors.red);
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _sendAcknowledgement(String complaintId, String message) async {
    // Simulate sending message
    await Future.delayed(const Duration(milliseconds: 500));
    
    setState(() {
      final index = complaints.indexWhere((c) => c['_id'] == complaintId);
      if (index != -1) {
        complaints[index]['status'] = 'In Progress';
      }
    });
    
    _showSnackBar('Acknowledgement sent successfully', Colors.green);
    messageController.clear();
    setState(() => selectedComplaintId = null);
  }

  Future<void> _updateStatus(String complaintId, String status) async {
    // Simulate updating status
    await Future.delayed(const Duration(milliseconds: 500));
    
    setState(() {
      final index = complaints.indexWhere((c) => c['_id'] == complaintId);
      if (index != -1) {
        complaints[index]['status'] = status;
      }
    });
    
    _showSnackBar('Status updated to $status', Colors.green);
    setState(() => selectedComplaintId = null);
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return Colors.redAccent;
      case 'medium':
        return Colors.orangeAccent;
      case 'low':
        return Colors.greenAccent;
      default:
        return Colors.grey;
    }
  }

  Widget _buildSidebar() {
    return Container(
      width: 260,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF0F172A),
            const Color(0xFF1E293B),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.blue.shade700,
                  Colors.purple.shade700,
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.admin_panel_settings,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'QuickGriev',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Admin Panel',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (widget.adminData != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        widget.adminData!['department'] ?? 'All Departments',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(color: Colors.white24, height: 1),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 20, 16, 10),
                  child: Text(
                    'DEPARTMENTS',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                ...departments.map((dept) => Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: selectedDepartment == dept
                            ? Colors.blueAccent.withOpacity(0.2)
                            : Colors.transparent,
                      ),
                      child: ListTile(
                        leading: Icon(
                          _getDepartmentIcon(dept),
                          color: selectedDepartment == dept
                              ? Colors.blueAccent
                              : Colors.white70,
                          size: 22,
                        ),
                        title: Text(
                          dept,
                          style: TextStyle(
                            color: selectedDepartment == dept
                                ? Colors.white
                                : Colors.white70,
                            fontWeight: selectedDepartment == dept
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 14,
                          ),
                        ),
                        selected: selectedDepartment == dept,
                        onTap: () {
                          setState(() => selectedDepartment = dept);
                          _loadComplaints();
                        },
                      ),
                    )),
              ],
            ),
          ),
          const Divider(color: Colors.white24, height: 1),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text(
              'Logout',
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.w500,
              ),
            ),
            onTap: () {
              // Navigate back to login
              Navigator.of(context).pop();
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  IconData _getDepartmentIcon(String dept) {
    switch (dept) {
      case 'Police':
        return Icons.local_police;
      case 'Health':
        return Icons.local_hospital;
      case 'Electricity':
        return Icons.electric_bolt;
      case 'Water':
        return Icons.water_drop;
      case 'Municipality':
        return Icons.location_city;
      case 'Transport':
        return Icons.directions_bus;
      default:
        return Icons.dashboard;
    }
  }

  Widget _buildComplaintCard(Map<String, dynamic> complaint) {
    final priority = complaint['priority']?.toString().toLowerCase() ?? 'low';
    final isExpanded = selectedComplaintId == complaint['_id'];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: const Color(0xFF1E293B),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.all(20),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getPriorityColor(priority).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _getPriorityColor(priority),
                      width: 2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        priority == 'high'
                            ? Icons.warning_rounded
                            : priority == 'medium'
                                ? Icons.info_outline
                                : Icons.check_circle_outline,
                        color: _getPriorityColor(priority),
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        priority.toUpperCase(),
                        style: TextStyle(
                          color: _getPriorityColor(priority),
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    complaint['complaintText'] ?? '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getDepartmentIcon(complaint['department'] ?? ''),
                              size: 12,
                              color: Colors.blueAccent,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              complaint['department'] ?? 'N/A',
                              style: const TextStyle(
                                color: Colors.blueAccent,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.person,
                        size: 12,
                        color: Colors.white54,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        complaint['userId'] ?? 'Unknown',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: complaint['status'] == 'Resolved'
                          ? Colors.green.withOpacity(0.2)
                          : complaint['status'] == 'In Progress'
                              ? Colors.orange.withOpacity(0.2)
                              : Colors.grey.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Status: ${complaint['status'] ?? 'Received'}',
                      style: TextStyle(
                        color: complaint['status'] == 'Resolved'
                            ? Colors.greenAccent
                            : complaint['status'] == 'In Progress'
                                ? Colors.orangeAccent
                                : Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            trailing: IconButton(
              icon: Icon(
                isExpanded ? Icons.expand_less : Icons.expand_more,
                color: Colors.white70,
                size: 28,
              ),
              onPressed: () {
                setState(() {
                  selectedComplaintId = isExpanded ? null : complaint['_id'];
                });
              },
            ),
          ),
          if (isExpanded)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                border: Border(
                  top: BorderSide(color: Colors.white24, width: 1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.message, color: Colors.blueAccent, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Send Acknowledgement/Update',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: messageController,
                    maxLines: 3,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Type your message to the user...',
                      hintStyle: const TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: const Color(0xFF1E293B),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Colors.blueAccent,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: const Icon(Icons.send, size: 18),
                        label: const Text('Send Message'),
                        onPressed: () {
                          if (messageController.text.trim().isNotEmpty) {
                            _sendAcknowledgement(
                              complaint['_id'],
                              messageController.text,
                            );
                          } else {
                            _showSnackBar(
                              'Please enter a message',
                              Colors.orange,
                            );
                          }
                        },
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orangeAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: const Icon(Icons.update, size: 18),
                        label: const Text('In Progress'),
                        onPressed: () {
                          _updateStatus(complaint['_id'], 'In Progress');
                        },
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.greenAccent,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: const Icon(Icons.check_circle, size: 18),
                        label: const Text('Resolved'),
                        onPressed: () {
                          _updateStatus(complaint['_id'], 'Resolved');
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      drawer: isDesktop ? null : Drawer(child: _buildSidebar()),
      appBar: isDesktop
          ? null
          : AppBar(
              backgroundColor: const Color(0xFF0F172A),
              title: const Text('QuickGriev Admin'),
              elevation: 0,
            ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF020617),
              Color(0xFF0F172A),
            ],
          ),
        ),
        child: Row(
          children: [
            if (isDesktop) _buildSidebar(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              selectedDepartment == 'All'
                                  ? 'All Complaints'
                                  : '$selectedDepartment Department',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Total: ${complaints.length} complaints',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.blueAccent.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.refresh, color: Colors.blueAccent),
                            onPressed: _loadComplaints,
                            tooltip: 'Refresh',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Expanded(
                      child: isLoading
                          ? const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircularProgressIndicator(
                                    color: Colors.blueAccent,
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'Loading complaints...',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : complaints.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.inbox_outlined,
                                        size: 80,
                                        color: Colors.white.withOpacity(0.3),
                                      ),
                                      const SizedBox(height: 16),
                                      const Text(
                                        'No complaints found',
                                        style: TextStyle(
                                          color: Colors.white54,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: complaints.length,
                                  itemBuilder: (context, index) {
                                    return _buildComplaintCard(complaints[index]);
                                  },
                                ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    messageController.dispose();
    super.dispose();
  }
}