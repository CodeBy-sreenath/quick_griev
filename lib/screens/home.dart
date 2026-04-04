import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:url_launcher/url_launcher.dart';
import '../services/complaint_api.dart';

class HomePage extends StatefulWidget {
  final Map<String, dynamic>? userData;
  const HomePage({Key? key, this.userData}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  bool isMalayalam = false;
  final TextEditingController complaintController = TextEditingController();
  final TextEditingController locationController = TextEditingController();

  PlatformFile? selectedImage;
  late stt.SpeechToText _speech;
  bool isListening = false;
  bool _speechAvailable = false;

  List<Map<String, dynamic>> complaintHistory = [];
  Map<String, dynamic>? selectedComplaint;

  Timer? refreshTimer;

  bool _sidebarOpen = false;
  late AnimationController _sidebarController;
  late Animation<double> _sidebarAnimation;

  final List<Map<String, String>> _quotes = [
    {
      "en": "Your voice matters — every complaint brings change.",
      "ml": "നിങ്ങളുടെ ശബ്ദം പ്രധാനമാണ് — ഓരോ പരാതിയും മാറ്റം കൊണ്ടുവരുന്നു.",
      "author_en": "QuickGriev",
      "author_ml": "ക്വിക്‌ഗ്രീവ്",
    },
    {
      "en": "Speak up. Your grievance is your right as a citizen.",
      "ml": "ശബ്ദമുയർത്തൂ. പരാതി പറയുക നിങ്ങളുടെ പൗരാവകാശമാണ്.",
      "author_en": "Civic Charter",
      "author_ml": "പൗര അവകാശ രേഖ",
    },
    {
      "en": "A better community starts with one honest complaint.",
      "ml": "ഒരു നല്ല സമൂഹം ആരംഭിക്കുന്നത് ഒരു സത്യസന്ധമായ പരാതിയിൽ നിന്നാണ്.",
      "author_en": "QuickGriev",
      "author_ml": "ക്വിക്‌ഗ്രീവ്",
    },
    {
      "en": "Transparency builds trust. Report. Resolve. Reform.",
      "ml": "സുതാര്യത വിശ്വാസം വളർത്തുന്നു. റിപ്പോർട്ട് ചെയ്യൂ. പരിഹരിക്കൂ. പരിഷ്കരിക്കൂ.",
      "author_en": "Governance Principle",
      "author_ml": "ഭരണ തത്വം",
    },
    {
      "en": "Civic participation is the foundation of democracy.",
      "ml": "പൗര പങ്കാളിത്തം ജനാധിപത്യത്തിന്റെ അടിത്തറയാണ്.",
      "author_en": "Public Policy",
      "author_ml": "പൊതു നയം",
    },
    {
      "en": "We listen, so the system improves — for everyone.",
      "ml": "നാം ശ്രദ്ധിക്കുന്നു, അതിനാൽ വ്യവസ്ഥ എല്ലാവർക്കുമായി മെച്ചപ്പെടുന്നു.",
      "author_en": "QuickGriev",
      "author_ml": "ക്വിക്‌ഗ്രീവ്",
    },
  ];
  int _currentQuoteIndex = 0;
  Timer? _quoteTimer;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _initSpeech();

    _sidebarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _sidebarAnimation = CurvedAnimation(
      parent: _sidebarController,
      curve: Curves.easeInOut,
    );

    locationController.text =
        widget.userData?['location'] ?? 'Pathanamthitta, Kerala';

    fetchComplaintHistory();

    refreshTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => fetchComplaintHistory(),
    );

    _quoteTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      setState(() {
        _currentQuoteIndex = (_currentQuoteIndex + 1) % _quotes.length;
      });
    });
  }

  @override
  void dispose() {
    refreshTimer?.cancel();
    _quoteTimer?.cancel();
    _sidebarController.dispose();
    complaintController.dispose();
    locationController.dispose();
    super.dispose();
  }

  void _openSidebar() {
    setState(() => _sidebarOpen = true);
    _sidebarController.forward();
  }

  void _closeSidebar() {
    _sidebarController.reverse().then((_) {
      setState(() => _sidebarOpen = false);
    });
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
    "location": {"en": "Your Location", "ml": "നിങ്ങളുടെ സ്ഥലം"},
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
    "shareTitle": {
      "en": "Share This Complaint",
      "ml": "ഈ പരാതി പങ്കിടൂ"
    },
    "shareSubtitle": {
      "en": "Spread awareness — share on social media to demand accountability.",
      "ml": "ബോധവൽക്കരണം പ്രചരിപ്പിക്കൂ — ഉത്തരവാദിത്തം ആവശ്യപ്പെടാൻ സോഷ്യൽ മീഡിയയിൽ പങ്കിടൂ."
    },
    "copyText": {"en": "Copy Text", "ml": "ടെക്സ്റ്റ് പകർത്തുക"},
    "copied": {"en": "Copied to clipboard!", "ml": "ക്ലിപ്പ്ബോർഡിൽ പകർത്തി!"},
    "moreOptions": {"en": "More Share Options", "ml": "കൂടുതൽ ഓപ്ഷനുകൾ"},
  };

  String t(String key) => isMalayalam ? text[key]!["ml"]! : text[key]!["en"]!;

  // ---------------- SPEECH INIT ----------------
  Future<void> _initSpeech() async {
    _speechAvailable = await _speech.initialize(
      onError: (error) {
        setState(() => isListening = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Voice error: ${error.errorMsg}"),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      },
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          setState(() => isListening = false);
        }
      },
    );
    setState(() {});
  }

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
    if (!_speechAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Speech recognition is not available on this device."),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }
    setState(() => isListening = true);
    await _speech.listen(
      localeId: isMalayalam ? 'ml_IN' : 'en_US',
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 4),
      cancelOnError: true,
      onResult: (result) {
        setState(() {
          complaintController.text = result.recognizedWords;
        });
        if (result.finalResult) {
          setState(() => isListening = false);
        }
      },
    );
  }

  Future<void> stopListening() async {
    await _speech.stop();
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
      location: locationController.text.trim(),
    );

    ScaffoldMessenger.of(context).clearSnackBars();

    if (result['success'] == true) {
      complaintController.clear();
      setState(() => selectedImage = null);
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

  // ════════════════════════════════════════════════
  //  SOCIAL SHARE HELPERS
  // ════════════════════════════════════════════════

  String _buildShareMessage(Map<String, dynamic> complaint) {
    final dept = complaint['department'] ?? 'Government Department';
    final status = complaint['status'] ?? 'Unknown';
    final location = complaint['location'] ?? '';
    final body = complaint['complaintText'] ?? '';

    return isMalayalam
        ? '📢 ഒരു പൊതു പരാതി!\n\n'
            '📋 വകുപ്പ്: $dept\n'
            '📍 സ്ഥലം: $location\n'
            '⚠️ നിലവിലെ സ്ഥിതി: $status\n\n'
            '💬 "$body"\n\n'
            '#QuickGriev #പൊതുപരാതി #Kerala #Accountability'
        : '📢 Public Grievance Alert!\n\n'
            '📋 Department: $dept\n'
            '📍 Location: $location\n'
            '⚠️ Status: $status\n\n'
            '💬 "$body"\n\n'
            '#QuickGriev #PublicGrievance #Kerala #Accountability #GovtMustAct';
  }

  Future<void> _shareOnTwitter(Map<String, dynamic> c) async {
    final msg = Uri.encodeComponent(_buildShareMessage(c));
    final uri = Uri.parse('https://twitter.com/intent/tweet?text=$msg');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _showLaunchError();
    }
  }

  Future<void> _shareOnWhatsApp(Map<String, dynamic> c) async {
    final msg = Uri.encodeComponent(_buildShareMessage(c));
    final uri = Uri.parse('https://wa.me/?text=$msg');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _showLaunchError();
    }
  }

  Future<void> _shareOnFacebook(Map<String, dynamic> c) async {
    final msg = Uri.encodeComponent(_buildShareMessage(c));
    final uri = Uri.parse(
        'https://www.facebook.com/sharer/sharer.php?quote=$msg&u=https://quickgriev.app');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _showLaunchError();
    }
  }

  Future<void> _shareOnTelegram(Map<String, dynamic> c) async {
    final msg = Uri.encodeComponent(_buildShareMessage(c));
    final uri = Uri.parse(
        'https://t.me/share/url?url=https://quickgriev.app&text=$msg');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _showLaunchError();
    }
  }

  Future<void> _copyShareText(Map<String, dynamic> c) async {
    await Clipboard.setData(ClipboardData(text: _buildShareMessage(c)));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t("copied")),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showLaunchError() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Could not open app. Please try another platform."),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showShareBottomSheet(Map<String, dynamic> complaint) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ShareBottomSheet(
        complaint: complaint,
        isMalayalam: isMalayalam,
        titleText: t("shareTitle"),
        subtitleText: t("shareSubtitle"),
        copyLabelText: t("copyText"),
        onTwitter: () => _shareOnTwitter(complaint),
        onWhatsApp: () => _shareOnWhatsApp(complaint),
        onFacebook: () => _shareOnFacebook(complaint),
        onTelegram: () => _shareOnTelegram(complaint),
        onCopy: () => _copyShareText(complaint),
      ),
    );
  }

  // ---------------- SIDEBAR ----------------
  Widget buildSidebar({bool isMobile = false}) {
    return Container(
      width: 260,
      color: const Color(0xFF0F172A),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isMobile)
            SizedBox(height: MediaQuery.of(context).padding.top + 4),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                t("title"),
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              if (isMobile)
                GestureDetector(
                  onTap: _closeSidebar,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Colors.white12,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.close,
                        color: Colors.white70, size: 20),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 20),
          Text(t("history"),
              style: const TextStyle(color: Colors.white70, fontSize: 13)),
          const Divider(color: Colors.white24),

          Expanded(
            child: complaintHistory.isEmpty
                ? const Center(
                    child: Text(
                      "No complaints yet.\nSubmit your first one!",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                  )
                : ListView.builder(
                    itemCount: complaintHistory.length,
                    itemBuilder: (_, index) {
                      final c = complaintHistory[index];
                      final isSelected =
                          selectedComplaint?['_id'] == c['_id'];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.blueAccent.withOpacity(0.15)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListTile(
                          dense: true,
                          title: Text(
                            c['complaintText'],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 13),
                          ),
                          subtitle: Text(
                            "${c['department']} • ${c['status']}",
                            style: const TextStyle(
                                color: Colors.greenAccent, fontSize: 11),
                          ),
                          onTap: () {
                            setState(() => selectedComplaint = c);
                            if (isMobile) _closeSidebar();
                          },
                        ),
                      );
                    },
                  ),
          ),

          const Divider(color: Colors.white24),
          TextButton.icon(
            icon: const Icon(Icons.logout, color: Colors.redAccent, size: 18),
            label: Text(t("logout"),
                style:
                    const TextStyle(color: Colors.redAccent, fontSize: 13)),
            onPressed: logout,
          ),
        ],
      ),
    );
  }

  // ---------------- QUOTE SECTION ----------------
  Widget _buildQuoteBanner() {
    final q = _quotes[_currentQuoteIndex];
    final quoteText = isMalayalam ? q["ml"]! : q["en"]!;
    final authorText = isMalayalam ? q["author_ml"]! : q["author_en"]!;
    final labelText =
        isMalayalam ? "ദിവസത്തിന്റെ വചനം" : "Thought of the Day";

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: Text(
              labelText,
              key: ValueKey('label_$isMalayalam'),
              style: const TextStyle(
                color: Color(0xFF475569),
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 2.0,
              ),
            ),
          ),
          const SizedBox(height: 14),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 700),
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.06),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                      parent: animation, curve: Curves.easeOut)),
                  child: child,
                ),
              );
            },
            child: Text(
              quoteText,
              key: ValueKey('q_${_currentQuoteIndex}_$isMalayalam'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFFCBD5E1),
                fontSize: 14.5,
                fontWeight: FontWeight.w400,
                height: 1.75,
                letterSpacing: 0.15,
              ),
            ),
          ),
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            child: Text(
              '— $authorText',
              key: ValueKey('a_${_currentQuoteIndex}_$isMalayalam'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF3B82F6),
                fontSize: 11,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.6,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _quotes.length,
              (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeInOut,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == _currentQuoteIndex ? 16 : 4,
                height: 4,
                decoration: BoxDecoration(
                  color: i == _currentQuoteIndex
                      ? const Color(0xFF3B82F6)
                      : const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            height: 1,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Color(0xFF1E293B),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- MAIN UI ----------------
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 900;

    return Scaffold(
      body: Stack(
        children: [
          Row(
            children: [
              if (isDesktop) buildSidebar(isMobile: false),
              Expanded(
                child: Container(
                  color: const Color(0xFF020617),
                  child: Column(
                    children: [
                      if (!isDesktop)
                        Container(
                          color: const Color(0xFF0F172A),
                          padding: EdgeInsets.only(
                            top: MediaQuery.of(context).padding.top + 6,
                            bottom: 10,
                            left: 4,
                            right: 16,
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.menu,
                                    color: Colors.white, size: 26),
                                onPressed: _openSidebar,
                              ),
                              Text(
                                t("title"),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 24),
                          child: Center(
                            child: ConstrainedBox(
                              constraints:
                                  const BoxConstraints(maxWidth: 540),
                              child: Column(
                                children: [
                                  _buildQuoteBanner(),
                                  const SizedBox(height: 20),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0F172A),
                                      borderRadius:
                                          BorderRadius.circular(14),
                                    ),
                                    child: selectedComplaint == null
                                        ? _complaintForm()
                                        : _complaintDetails(),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          if (!isDesktop && _sidebarOpen)
            FadeTransition(
              opacity: _sidebarAnimation,
              child: GestureDetector(
                onTap: _closeSidebar,
                child: Container(
                  color: Colors.black.withOpacity(0.55),
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
            ),

          if (!isDesktop && _sidebarOpen)
            SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(-1, 0),
                end: Offset.zero,
              ).animate(_sidebarAnimation),
              child: Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () {},
                  child: buildSidebar(isMobile: true),
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
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
        const SizedBox(height: 6),
        Text(t("desc"), style: const TextStyle(color: Colors.white70)),
        const SizedBox(height: 18),

        Text(t("location"),
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white70)),
        const SizedBox(height: 8),
        TextField(
          controller: locationController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: t("locationHint"),
            hintStyle: const TextStyle(color: Colors.white54),
            prefixIcon:
                const Icon(Icons.location_on, color: Colors.blueAccent),
            filled: true,
            fillColor: const Color(0xFF020617),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        ),
        const SizedBox(height: 16),

        TextField(
          controller: complaintController,
          maxLines: 5,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: t("hint"),
            hintStyle: const TextStyle(color: Colors.white54),
            filled: true,
            fillColor: const Color(0xFF020617),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        ),
        const SizedBox(height: 20),

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
                  onPressed: () => setState(() => selectedImage = null),
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
          label: Text(
            isListening
                ? (isMalayalam ? "നിർത്തുക" : "Stop Listening")
                : t("voice"),
          ),
          onPressed: !_speechAvailable
              ? null
              : isListening
                  ? stopListening
                  : startListening,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
            backgroundColor:
                isListening ? Colors.red.withOpacity(0.2) : null,
          ),
        ),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            icon: const Icon(Icons.language),
            label: Text(t("lang")),
            onPressed: () => setState(() => isMalayalam = !isMalayalam),
          ),
        ),
      ],
    );
  }

  // ---------------- DETAILS ----------------
  // ✅ Share section is ALWAYS shown for every complaint — no status check
  Widget _complaintDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header row with inline share icon button ──
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Complaint Details",
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            // Quick share icon always visible in header
            IconButton(
              onPressed: () => _showShareBottomSheet(selectedComplaint!),
              icon: const Icon(Icons.share_rounded, color: Colors.blueAccent),
              tooltip: 'Share',
            ),
          ],
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

        if (selectedComplaint!['location'] != null) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.location_on,
                  color: Colors.orangeAccent, size: 18),
              const SizedBox(width: 4),
              Text(
                selectedComplaint!['location'],
                style: const TextStyle(color: Colors.orangeAccent),
              ),
            ],
          ),
        ],

        if (selectedComplaint!['imageUrl'] != null) ...[
          const SizedBox(height: 16),
          const Text("Attached Image:",
              style: TextStyle(color: Colors.white70)),
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

        // ════════════════════════════════════════════════
        // 🔵 SOCIAL SHARE SECTION — ALWAYS VISIBLE
        //    No status check. Every complaint can be shared.
        // ════════════════════════════════════════════════
        const SizedBox(height: 24),
        _buildShareSection(selectedComplaint!),

        const SizedBox(height: 20),
        TextButton(
          onPressed: () => setState(() => selectedComplaint = null),
          child: const Text("← Back"),
        ),
      ],
    );
  }

  // ════════════════════════════════════════════════
  //  SHARE SECTION WIDGET — always rendered
  // ════════════════════════════════════════════════
  Widget _buildShareSection(Map<String, dynamic> complaint) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1E3A5F).withOpacity(0.5),
            const Color(0xFF0F2040).withOpacity(0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.blueAccent.withOpacity(0.35)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.share_rounded,
                    color: Colors.blueAccent, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t("shareTitle"),
                      style: const TextStyle(
                        color: Colors.blueAccent,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      t("shareSubtitle"),
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Platform buttons row 1: Twitter + WhatsApp ──
          Row(
            children: [
              Expanded(
                child: _socialButton(
                  label: "Twitter / X",
                  icon: Icons.tag,
                  color: const Color(0xFF1DA1F2),
                  onTap: () => _shareOnTwitter(complaint),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _socialButton(
                  label: "WhatsApp",
                  icon: Icons.chat_bubble_rounded,
                  color: const Color(0xFF25D366),
                  onTap: () => _shareOnWhatsApp(complaint),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // ── Platform buttons row 2: Facebook + Telegram ──
          Row(
            children: [
              Expanded(
                child: _socialButton(
                  label: "Facebook",
                  icon: Icons.thumb_up_alt_rounded,
                  color: const Color(0xFF1877F2),
                  onTap: () => _shareOnFacebook(complaint),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _socialButton(
                  label: "Telegram",
                  icon: Icons.send_rounded,
                  color: const Color(0xFF229ED9),
                  onTap: () => _shareOnTelegram(complaint),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Copy text button ──
          GestureDetector(
            onTap: () => _copyShareText(complaint),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 11),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                border: Border.all(color: Colors.white24),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.copy_rounded,
                      color: Colors.white54, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    t("copyText"),
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // ── More options (bottom sheet) ──
          GestureDetector(
            onTap: () => _showShareBottomSheet(complaint),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 11),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2563EB), Color(0xFF1E40AF)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.open_in_new_rounded,
                      color: Colors.white, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    t("moreOptions"),
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _socialButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          border: Border.all(color: color.withOpacity(0.4)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════
//  SHARE BOTTOM SHEET (expanded view)
// ════════════════════════════════════════════════
class _ShareBottomSheet extends StatelessWidget {
  final Map<String, dynamic> complaint;
  final bool isMalayalam;
  final String titleText;
  final String subtitleText;
  final String copyLabelText;
  final VoidCallback onTwitter;
  final VoidCallback onWhatsApp;
  final VoidCallback onFacebook;
  final VoidCallback onTelegram;
  final VoidCallback onCopy;

  const _ShareBottomSheet({
    required this.complaint,
    required this.isMalayalam,
    required this.titleText,
    required this.subtitleText,
    required this.copyLabelText,
    required this.onTwitter,
    required this.onWhatsApp,
    required this.onFacebook,
    required this.onTelegram,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final platforms = [
      _PlatformEntry(
          label: "Twitter / X",
          icon: Icons.tag,
          color: const Color(0xFF1DA1F2),
          onTap: onTwitter),
      _PlatformEntry(
          label: "WhatsApp",
          icon: Icons.chat_bubble_rounded,
          color: const Color(0xFF25D366),
          onTap: onWhatsApp),
      _PlatformEntry(
          label: "Facebook",
          icon: Icons.thumb_up_alt_rounded,
          color: const Color(0xFF1877F2),
          onTap: onFacebook),
      _PlatformEntry(
          label: "Telegram",
          icon: Icons.send_rounded,
          color: const Color(0xFF229ED9),
          onTap: onTelegram),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          const Icon(Icons.share_rounded, color: Colors.blueAccent, size: 32),
          const SizedBox(height: 10),
          Text(
            titleText,
            style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Colors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            subtitleText,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Platform grid (1 row × 4)
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: platforms
                .map(
                  (p) => GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      p.onTap();
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: p.color.withOpacity(0.15),
                            border: Border.all(
                                color: p.color.withOpacity(0.4)),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(p.icon, color: p.color, size: 24),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          p.label,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 10),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),

          const SizedBox(height: 16),

          // Copy button
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
              onCopy();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                border: Border.all(color: Colors.white24),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.copy_rounded,
                      color: Colors.white54, size: 16),
                  const SizedBox(width: 8),
                  Text(copyLabelText,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 14)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlatformEntry {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  _PlatformEntry({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}