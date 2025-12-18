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

  PlatformFile? selectedImage;
  late stt.SpeechToText _speech;
  bool isListening = false;

  List<Map<String, String>> complaintHistory = [];

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    fetchComplaintHistory();
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

  // ---------------- SUBMIT (BACKEND CONNECTED) ----------------
  void submitComplaint() async {
    if (complaintController.text.trim().isEmpty) return;

    final userId = widget.userData?['userId'] ?? 'user123';

    try {
      await ApiService.submitComplaint(
        userId: userId,
        complaintText: complaintController.text,
        language: isMalayalam ? 'ml' : 'en',
        imageUrl: selectedImage?.name,
        voiceText: isListening ? complaintController.text : null,
        location: "Kochi",
      );

      setState(() {
        complaintHistory.insert(0, {
          "title": complaintController.text.length > 20
              ? complaintController.text.substring(0, 20)
              : complaintController.text,
          "status": "Received",
        });
      });

      complaintController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Complaint submitted successfully"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Submission failed"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ---------------- HISTORY FROM BACKEND ----------------
 Future<void> fetchComplaintHistory() async {
  final userId = widget.userData?['userId'] ?? 'user123';

  final complaints = await ApiService.getComplaintHistory(userId);

  setState(() {
    complaintHistory = complaints.map<Map<String, String>>((c) {
      return {
        "title": c["complaintText"]?.toString() ?? "",
        "status": c["status"]?.toString() ?? "Received",
      };
    }).toList();
  });
}

  void logout() {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Logged out")));
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
          Text(t("history"),
              style: const TextStyle(color: Colors.white70)),
          const Divider(color: Colors.white24),
          Expanded(
            child: complaintHistory.isEmpty
                ? const Text("No complaints yet",
                    style: TextStyle(color: Colors.white54))
                : ListView.builder(
                    itemCount: complaintHistory.length,
                    itemBuilder: (_, index) {
                      return ListTile(
                        title: Text(complaintHistory[index]["title"]!,
                            style:
                                const TextStyle(color: Colors.white)),
                        subtitle: Text(
                          "Status: ${complaintHistory[index]["status"]}",
                          style: const TextStyle(
                              color: Colors.greenAccent),
                        ),
                      );
                    },
                  ),
          ),
          const Divider(color: Colors.white24),
          TextButton.icon(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            label: Text(t("logout"),
                style:
                    const TextStyle(color: Colors.redAccent)),
            onPressed: logout,
          ),
        ],
      ),
    );
  }

  // ---------------- MAIN UI (UNCHANGED) ----------------
  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      drawer: isDesktop ? null : Drawer(child: buildSidebar()),
      appBar: isDesktop
          ? null
          : AppBar(
              backgroundColor: const Color(0xFF0F172A),
              title: Text(t("title")),
              actions: [
                IconButton(
                    icon: const Icon(Icons.logout),
                    onPressed: logout)
              ],
            ),
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
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(t("subtitle"),
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                      const SizedBox(height: 6),
                      Text(t("desc"),
                          style: const TextStyle(
                              color: Colors.white70)),
                      const SizedBox(height: 18),
                      TextField(
                        controller: complaintController,
                        maxLines: 5,
                        style:
                            const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: t("hint"),
                          hintStyle: const TextStyle(
                              color: Colors.white54),
                          filled: true,
                          fillColor:
                              const Color(0xFF020617),
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.send),
                          label: Text(t("submit")),
                          onPressed: submitComplaint,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.image),
                          label: Text(t("image")),
                          onPressed: pickImage,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          icon: Icon(isListening
                              ? Icons.mic
                              : Icons.mic_none),
                          label: Text(t("voice")),
                          onPressed: isListening
                              ? stopListening
                              : startListening,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          icon:
                              const Icon(Icons.language),
                          label: Text(t("lang")),
                          onPressed: () {
                            setState(() {
                              isMalayalam = !isMalayalam;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
