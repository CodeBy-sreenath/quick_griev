import 'dart:async';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../services/complaint_api.dart';

class HomePage extends StatefulWidget {
  final Map<String, dynamic>? userData;
  const HomePage({Key? key, this.userData}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool isMalayalam = false;
  final TextEditingController complaintController = TextEditingController();
  final TextEditingController locationController = TextEditingController();

  PlatformFile? selectedImage;
  late stt.SpeechToText _speech;
  bool isListening = false;

  /// 🔹 FULL complaint list
  List<Map<String, dynamic>> complaintHistory = [];

  /// 🔹 Selected complaint
  Map<String, dynamic>? selectedComplaint;

  Timer? refreshTimer;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    
    // Set initial location from userData if available
    locationController.text = widget.userData?['location'] ?? 'Pathanamthitta, Kerala';
    
    fetchComplaintHistory();

    /// 🔄 auto refresh admin updates
    refreshTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => fetchComplaintHistory(),
    );
  }

  @override
  void dispose() {
    refreshTimer?.cancel();
    complaintController.dispose();
    locationController.dispose();
    super.dispose();
  }

  // ---------------- LANGUAGE ----------------
  Map<String, Map<String, String>> text = {
    "title": {"en": "QuickGriev", "ml": "ക്വിക്‌ഗ്രീവ്"},
    "subtitle": {
      "en": "Public Grievance Redressal System",
      "ml": "പൊതുപരാതി പരിഹാര സംവിധാനം"
    },
    "desc": {
      "en": "Submit grievances using text, image or voice.",
      "ml": "വാചകം, ചിത്രം അല്ലെങ്കിൽ ശബ്ദം ഉപയോഗിച്ച് പരാതികൾ സമർപ്പിക്കുക."
    },
    "hint": {
      "en": "Describe your complaint clearly...",
      "ml": "നിങ്ങളുടെ പരാതി വ്യക്തമായി രേഖപ്പെടുത്തുക..."
    },
    "location": {
      "en": "Your Location",
      "ml": "നിങ്ങളുടെ സ്ഥലം"
    },
    "locationHint": {
      "en": "Enter your location...",
      "ml": "നിങ്ങളുടെ സ്ഥലം നൽകുക..."
    },
    "submit": {"en": "Submit Complaint", "ml": "പരാതി സമർപ്പിക്കുക"},
    "image": {"en": "Attach Image", "ml": "ചിത്രം ചേർക്കുക"},
    "voice": {"en": "Voice Input", "ml": "വോയിസ് ഇൻപുട്ട്"},
    "history": {"en": "Complaint History", "ml": "പരാതി ചരിത്രം"},
    "lang": {"en": "Switch to Malayalam", "ml": "Switch to English"},
    "logout": {"en": "Logout", "ml": "ലോഗ്ഔട്ട്"},
  };

  String t(String key) => isMalayalam ? text[key]!["ml"]! : text[key]!["en"]!;

  // ---------------- IMAGE PICK ----------------
  Future<void> pickImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null) {
      setState(() => selectedImage = result.files.first);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Image selected: ${result.files.first.name}"),
          backgroundColor: Colors.blue,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // ---------------- VOICE INPUT ----------------
  Future<void> startListening() async {
    bool available = await _speech.initialize();
    if (available) {
      setState(() => isListening = true);
      _speech.listen(
        localeId: isMalayalam ? 'ml_IN' : 'en_US',
        onResult: (result) {
          setState(() {
            complaintController.text = result.recognizedWords;
          });
        },
      );
    }
  }

  void stopListening() {
    _speech.stop();
    setState(() => isListening = false);
  }

  // ---------------- SUBMIT ----------------
  void submitComplaint() async {
    if (complaintController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter a complaint description"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (locationController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter your location"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final userId = widget.userData?['userId'] ?? 'user123';

    // Show loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(width: 16),
            Text("Submitting complaint..."),
          ],
        ),
        duration: Duration(seconds: 30),
      ),
    );

    final result = await ApiService.submitComplaint(
      userId: userId,
      complaintText: complaintController.text,
      language: isMalayalam ? 'ml' : 'en',
      imageFile: selectedImage,
      voiceText: isListening ? complaintController.text : null,
      location: locationController.text.trim(), // Use user-entered location
    );

    ScaffoldMessenger.of(context).clearSnackBars();

    if (result['success'] == true) {
      complaintController.clear();
      selectedImage = null;
      fetchComplaintHistory();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Complaint submitted successfully"),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: ${result['message'] ?? 'Failed to submit'}"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ---------------- HISTORY ----------------
  Future<void> fetchComplaintHistory() async {
    final userId = widget.userData?['userId'] ?? 'user123';
    final complaints = await ApiService.getComplaintHistory(userId);

    setState(() {
      complaintHistory = complaints;
      if (selectedComplaint != null) {
        selectedComplaint = complaints.firstWhere(
          (c) => c['_id'] == selectedComplaint!['_id'],
          orElse: () => selectedComplaint!,
        );
      }
    });
  }

  void logout() {
    Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
  }

  // ---------------- SIDEBAR ----------------
  Widget buildSidebar() {
    return Container(
      width: 260,
      color: const Color(0xFF0F172A),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t("title"),
              style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          const SizedBox(height: 20),
          Text(t("history"), style: const TextStyle(color: Colors.white70)),
          const Divider(color: Colors.white24),
          Expanded(
            child: ListView.builder(
              itemCount: complaintHistory.length,
              itemBuilder: (_, index) {
                final c = complaintHistory[index];
                return ListTile(
                  title: Text(
                    c['complaintText'],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    "${c['department']} • ${c['status']}",
                    style: const TextStyle(color: Colors.greenAccent),
                  ),
                  onTap: () {
                    setState(() => selectedComplaint = c);
                  },
                );
              },
            ),
          ),
          const Divider(color: Colors.white24),
          TextButton.icon(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            label:
                Text(t("logout"), style: const TextStyle(color: Colors.redAccent)),
            onPressed: logout,
          ),
        ],
      ),
    );
  }

  // ---------------- MAIN UI ----------------
  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      drawer: isDesktop ? null : Drawer(child: buildSidebar()),
      body: Row(
        children: [
          if (isDesktop) buildSidebar(),
          Expanded(
            child: Container(
              color: const Color(0xFF020617),
              child: Center(
                child: Container(
                  width: 540,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: selectedComplaint == null
                      ? _complaintForm()
                      : _complaintDetails(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- FORM ----------------
  Widget _complaintForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(t("subtitle"),
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 6),
        Text(t("desc"), style: const TextStyle(color: Colors.white70)),
        const SizedBox(height: 18),
        
        // Location Input Field
        Text(t("location"),
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white70)),
        const SizedBox(height: 8),
        TextField(
          controller: locationController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: t("locationHint"),
            hintStyle: const TextStyle(color: Colors.white54),
            prefixIcon: const Icon(Icons.location_on, color: Colors.blueAccent),
            filled: true,
            fillColor: const Color(0xFF020617),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        const SizedBox(height: 16),
        
        // Complaint Text Field
        TextField(
          controller: complaintController,
          maxLines: 5,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: t("hint"),
            hintStyle: const TextStyle(color: Colors.white54),
            filled: true,
            fillColor: const Color(0xFF020617),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        const SizedBox(height: 20),
        
        // Show selected image preview
        if (selectedImage != null)
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF020617),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.image, color: Colors.green),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    selectedImage!.name,
                    style: const TextStyle(color: Colors.white70),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.red),
                  onPressed: () {
                    setState(() => selectedImage = null);
                  },
                ),
              ],
            ),
          ),
        if (selectedImage != null) const SizedBox(height: 16),
        
        ElevatedButton.icon(
          icon: const Icon(Icons.send),
          label: Text(t("submit")),
          onPressed: submitComplaint,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
          ),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          icon: const Icon(Icons.image),
          label: Text(t("image")),
          onPressed: pickImage,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
          ),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          icon: Icon(isListening ? Icons.mic : Icons.mic_none),
          label: Text(t("voice")),
          onPressed: isListening ? stopListening : startListening,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
            backgroundColor: isListening ? Colors.red.withOpacity(0.2) : null,
          ),
        ),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            icon: const Icon(Icons.language),
            label: Text(t("lang")),
            onPressed: () {
              setState(() => isMalayalam = !isMalayalam);
            },
          ),
        ),
      ],
    );
  }

  // ---------------- DETAILS ----------------
  Widget _complaintDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Complaint Details",
          style: TextStyle(
              fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 12),
        Text(
          selectedComplaint!['complaintText'],
          style: const TextStyle(color: Colors.white70, fontSize: 16),
        ),
        const SizedBox(height: 12),
        Text(
          "Department: ${selectedComplaint!['department']}",
          style: const TextStyle(color: Colors.blueAccent),
        ),
        const SizedBox(height: 6),
        Text(
          "Status: ${selectedComplaint!['status']}",
          style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.greenAccent),
        ),
        
        // Display Location
        if (selectedComplaint!['location'] != null) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.location_on, color: Colors.orangeAccent, size: 18),
              const SizedBox(width: 4),
              Text(
                selectedComplaint!['location'],
                style: const TextStyle(color: Colors.orangeAccent),
              ),
            ],
          ),
        ],
        
        // Show image if exists
        if (selectedComplaint!['imageUrl'] != null) ...[
          const SizedBox(height: 16),
          const Text(
            "Attached Image:",
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              selectedComplaint!['imageUrl'],
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 200,
                  color: const Color(0xFF020617),
                  child: const Center(
                    child: Icon(Icons.broken_image, color: Colors.white54),
                  ),
                );
              },
            ),
          ),
        ],
        
        const SizedBox(height: 20),
        TextButton(
          onPressed: () => setState(() => selectedComplaint = null),
          child: const Text("← Back"),
        )
      ],
    );
  }
}