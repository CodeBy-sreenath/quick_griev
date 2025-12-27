import 'package:flutter/material.dart';
import 'package:quick_griev/screens/admin_auth.dart';
import 'package:quick_griev/services/admin_complaint_api.dart';
import 'package:quick_griev/services/admin_status_api.dart';
import 'dart:math';

class AdminDashboard extends StatefulWidget {
  final Map<String, dynamic>? adminData;
  const AdminDashboard({Key? key, this.adminData}) : super(key: key);

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  String? loggedInDepartment;
  String selectedDepartment = '';

  final TextEditingController chatController = TextEditingController();
  String? lastSentMessage;

  bool isLoading = false;
  List<dynamic> complaints = [];

  final List<String> departments = [
    'Police',
    'Health',
    'Electricity',
    'Water',
    'Municipality',
    'Transport',
  ];

  // Inspirational quotes about public service
  final List<Map<String, String>> quotes = [
    {
      'quote': 'The first duty of government is to protect the powerless from the powerful.',
      'author': 'Hammurabi'
    },
    {
      'quote': 'In a democracy, the individual enjoys not only the ultimate power but carries the ultimate responsibility.',
      'author': 'Norman Cousins'
    },
    {
      'quote': 'The purpose of government is to enable the people of a nation to live in safety and happiness.',
      'author': 'Thomas Jefferson'
    },
    {
      'quote': 'Service to others is the rent you pay for your room here on Earth.',
      'author': 'Muhammad Ali'
    },
    {
      'quote': 'The best way to find yourself is to lose yourself in the service of others.',
      'author': 'Mahatma Gandhi'
    },
    {
      'quote': 'Government\'s first duty is to protect the people, not run their lives.',
      'author': 'Ronald Reagan'
    },
  ];

  late Map<String, String> currentQuote;

  @override
  void initState() {
    super.initState();
    currentQuote = quotes[Random().nextInt(quotes.length)];
    
    if (widget.adminData != null) {
      loggedInDepartment = widget.adminData!['department'];
      selectedDepartment = loggedInDepartment!;
      fetchComplaints();
    }
  }

  // ---------------- BUILD IMAGE URL ----------------
  String _buildImageUrl(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) return '';
    
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return imageUrl;
    }
    
    final cleanPath = imageUrl.startsWith('/') ? imageUrl : '/$imageUrl';
    return 'http://localhost:3000$cleanPath';
  }

  // ---------------- FETCH COMPLAINTS ----------------
  Future<void> fetchComplaints() async {
    setState(() => isLoading = true);
    try {
      complaints = await AdminApi.getDepartmentComplaints(selectedDepartment);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to load complaints'),
          backgroundColor: Colors.red,
        ),
      );
    }
    setState(() => isLoading = false);
  }

  // ---------------- LOGOUT ----------------
  void _handleLogout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const AdminDashboard()),
      (route) => false,
    );
  }

  // ---------------- GET PRIORITY COLOR ----------------
  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return Colors.redAccent;
      case 'medium':
        return Colors.orangeAccent;
      case 'low':
        return Colors.greenAccent;
      default:
        return Colors.white70;
    }
  }

  // ---------------- FULL SCREEN IMAGE VIEWER ----------------
  void _showFullScreenImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.broken_image, color: Colors.white54, size: 64),
                          SizedBox(height: 16),
                          Text('Failed to load image', style: TextStyle(color: Colors.white54)),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- COMPLAINT DETAIL DIALOG WITH IMAGE ----------------
  void _openComplaintChat(dynamic complaint) {
    final TextEditingController localChatController = TextEditingController();
    final String? imageUrl = complaint['imageUrl'];
    final bool hasImage = imageUrl != null && imageUrl.isNotEmpty;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) {
        return Dialog(
          backgroundColor: const Color(0xFF0F172A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: 500,
            constraints: const BoxConstraints(maxHeight: 700),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Text(
                            'Complaint Details',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white70),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const Divider(color: Colors.white24),
                    const SizedBox(height: 10),

                    // Complaint Text
                    const Text(
                      'Description:',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      complaint['complaintText'],
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    const SizedBox(height: 16),

                    // Complaint Metadata
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDetailRow('Priority', complaint['priority'], 
                            _getPriorityColor(complaint['priority'])),
                          const SizedBox(height: 8),
                          _buildDetailRow('Status', complaint['status'], Colors.greenAccent),
                          const SizedBox(height: 8),
                          _buildDetailRow('Department', complaint['department'], Colors.blueAccent),
                          if (complaint['location'] != null) ...[
                            const SizedBox(height: 8),
                            _buildDetailRow('Location', complaint['location'], Colors.orangeAccent),
                          ],
                        ],
                      ),
                    ),

                    // Display Image
                    if (hasImage) ...[
                      const SizedBox(height: 20),
                      const Text(
                        'Attached Image:',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => _showFullScreenImage(context, _buildImageUrl(imageUrl)),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            constraints: const BoxConstraints(maxHeight: 300),
                            child: Image.network(
                              _buildImageUrl(imageUrl),
                              width: double.infinity,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  height: 200,
                                  color: const Color(0xFF1E293B),
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      value: loadingProgress.expectedTotalBytes != null
                                          ? loadingProgress.cumulativeBytesLoaded /
                                              loadingProgress.expectedTotalBytes!
                                          : null,
                                    ),
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: 200,
                                  color: const Color(0xFF1E293B),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.broken_image, color: Colors.white54, size: 48),
                                      const SizedBox(height: 8),
                                      const Text('Failed to load image',
                                        style: TextStyle(color: Colors.white54)),
                                      const SizedBox(height: 4),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 20),
                                        child: Text(
                                          _buildImageUrl(imageUrl),
                                          style: const TextStyle(color: Colors.white38, fontSize: 10),
                                          textAlign: TextAlign.center,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '👆 Tap image to view full size',
                        style: TextStyle(color: Colors.white38, fontSize: 12, fontStyle: FontStyle.italic),
                      ),
                    ],

                    const SizedBox(height: 20),
                    const Divider(color: Colors.white24),
                    const SizedBox(height: 10),

                    // Status Update Section
                    const Text(
                      'Send Status Update:',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: localChatController,
                      maxLines: 3,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Type update for this complaint...',
                        hintStyle: const TextStyle(color: Colors.white54),
                        filled: true,
                        fillColor: const Color(0xFF1E293B),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.send),
                          label: const Text('Send Update'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                          onPressed: () async {
                            if (localChatController.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please enter an update message'),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                              return;
                            }

                            try {
                              await AdminStatusApi.updateComplaintStatus(
                                complaintId: complaint['_id'],
                                message: localChatController.text.trim(),
                                status: "In Progress",
                                department: selectedDepartment,
                              );

                              Navigator.pop(context);

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Complaint update sent successfully"),
                                  backgroundColor: Colors.green,
                                ),
                              );

                              fetchComplaints();
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(e.toString()),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ---------------- HELPER: BUILD DETAIL ROW ----------------
  Widget _buildDetailRow(String label, String value, Color valueColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            '$label:',
            style: const TextStyle(color: Colors.white54, fontSize: 14),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF020617), Color(0xFF0F172A)],
          ),
        ),
        child: Row(
          children: [
            // ---------------- SIDEBAR ----------------
            Container(
              width: 260,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'QuickGriev',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  
                  ...departments.map(
                    (dept) => ListTile(
                      leading: Icon(
                        _getDepartmentIcon(dept),
                        color: dept == selectedDepartment ? Colors.blueAccent : Colors.white54,
                      ),
                      title: Text(
                        dept,
                        style: TextStyle(
                          color: dept == selectedDepartment ? Colors.white : Colors.white70,
                          fontWeight: dept == selectedDepartment ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      selected: dept == selectedDepartment,
                      selectedTileColor: Colors.blueAccent.withOpacity(0.2),
                      onTap: () {
                        if (dept == loggedInDepartment) {
                          setState(() {
                            selectedDepartment = dept;
                          });
                          fetchComplaints();
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => LoginPage(department: dept),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),

            // ---------------- MAIN CONTENT ----------------
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$selectedDepartment Department',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _handleLogout,
                          icon: const Icon(Icons.logout),
                          label: const Text('Logout'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Complaints List
                    Expanded(
                      child: isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : complaints.isEmpty
                              ? Center(
                                  child: Container(
                                    padding: const EdgeInsets.all(40),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          '"${currentQuote['quote']}"',
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 24,
                                            fontStyle: FontStyle.italic,
                                            height: 1.6,
                                          ),
                                        ),
                                        const SizedBox(height: 20),
                                        Text(
                                          '— ${currentQuote['author']}',
                                          style: const TextStyle(
                                            color: Colors.blueAccent,
                                            fontSize: 18,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: complaints.length,
                                  itemBuilder: (context, index) {
                                    final c = complaints[index];
                                    final hasImage = c['imageUrl'] != null && 
                                                     c['imageUrl'].toString().isNotEmpty;
                                    
                                    return Card(
                                      color: const Color(0xFF1E293B),
                                      margin: const EdgeInsets.only(bottom: 16),
                                      child: ListTile(
                                        onTap: () => _openComplaintChat(c),
                                        leading: hasImage
                                            ? ClipRRect(
                                                borderRadius: BorderRadius.circular(8),
                                                child: Image.network(
                                                  _buildImageUrl(c['imageUrl']),
                                                  width: 60,
                                                  height: 60,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error, stackTrace) {
                                                    return Container(
                                                      width: 60,
                                                      height: 60,
                                                      color: const Color(0xFF0F172A),
                                                      child: const Icon(
                                                        Icons.image_not_supported,
                                                        color: Colors.white38,
                                                      ),
                                                    );
                                                  },
                                                ),
                                              )
                                            : Container(
                                                width: 60,
                                                height: 60,
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF0F172A),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: const Icon(
                                                  Icons.description,
                                                  color: Colors.blueAccent,
                                                ),
                                              ),
                                        title: Text(
                                          c['complaintText'],
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        subtitle: Padding(
                                          padding: const EdgeInsets.only(top: 8),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 2,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: _getPriorityColor(c['priority'])
                                                          .withOpacity(0.2),
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                    child: Text(
                                                      c['priority'].toString().toUpperCase(),
                                                      style: TextStyle(
                                                        color: _getPriorityColor(c['priority']),
                                                        fontSize: 11,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    c['status'],
                                                    style: const TextStyle(
                                                      color: Colors.greenAccent,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                DateTime.parse(c['createdAt'])
                                                    .toLocal()
                                                    .toString()
                                                    .substring(0, 16),
                                                style: const TextStyle(
                                                  color: Colors.white54,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        trailing: const Icon(
                                          Icons.arrow_forward_ios,
                                          color: Colors.blueAccent,
                                          size: 18,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                    ),

                    // GLOBAL CHAT
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: chatController,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                hintText: 'Send status update to user...',
                                hintStyle: TextStyle(color: Colors.white54),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.send, color: Colors.blueAccent),
                            onPressed: () {},
                          ),
                        ],
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
}