import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

import 'package:quick_griev/screens/home.dart';
import 'package:quick_griev/screens/admin_dashboard.dart';
import 'package:quick_griev/services/api_service.dart';

void main() {
  // 🔑 REQUIRED FOR FLUTTER WEB URL ROUTING
  setUrlStrategy(PathUrlStrategy());

  runApp(const MyApp());
}

// ---------------- APP ROOT ----------------

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      initialRoute: '/',

      routes: {
        '/': (context) => AuthScreen(),          // User Login/Register
        '/admin': (context) => AdminDashboard(), // Admin Dashboard
      },
    );
  }
}

// ---------------- AUTH SCREEN ----------------

class AuthScreen extends StatefulWidget {
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isLogin = true;

  final _name = TextEditingController();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  final _loginUsername = TextEditingController();
  final _loginEmail = TextEditingController();
  final _loginPassword = TextEditingController();

  String? tempUserId;

  final String bgUrl =
      "https://t3.ftcdn.net/jpg/03/83/69/12/360_F_383691287_YoZdckIitxXiBpp6qUBqAEfqni77G6Df.jpg";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(bgUrl),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(color: Colors.black.withOpacity(0.4)),
          Center(
            child: SingleChildScrollView(
              child: Container(
                width: 400,
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Text(
                      isLogin ? "User Login" : "User Registration",
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 25),

                    if (!isLogin) ...[
                      _field(_name, "Full Name"),
                      _field(_username, "Username"),
                      _field(_email, "Email"),
                      _field(_password, "Password", true),
                    ],

                    if (isLogin) ...[
                      _field(_loginUsername, "Username"),
                      _field(_loginEmail, "Email"),
                      _field(_loginPassword, "Password", true),
                    ],

                    const SizedBox(height: 20),

                    ElevatedButton(
                      onPressed: isLogin ? _login : _register,
                      child: Text(isLogin ? "Login" : "Register"),
                    ),

                    const SizedBox(height: 15),

                    GestureDetector(
                      onTap: () => setState(() => isLogin = !isLogin),
                      child: Text(
                        isLogin
                            ? "Don't have an account? Register"
                            : "Already have an account? Login",
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(TextEditingController c, String label, [bool pass = false]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: c,
        obscureText: pass,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
        ).copyWith(labelText: label),
      ),
    );
  }

  // ---------------- API LOGIC ----------------

  void _register() async {
    final res = await ApiService.register(
      name: _name.text,
      username: _username.text,
      email: _email.text,
      password: _password.text,
    );

    if (res["userId"] != null) {
      tempUserId = res["userId"];
      _goToOTP("register");
    } else {
      _msg(res["message"]);
    }
  }

  void _login() async {
    final res = await ApiService.login(
      username: _loginUsername.text,
      email: _loginEmail.text,
      password: _loginPassword.text,
    );

    if (res["userId"] != null) {
      tempUserId = res["userId"];
      _goToOTP("login");
    } else {
      _msg(res["message"]);
    }
  }

  void _goToOTP(String mode) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OTPVerificationScreen(
          mode: mode,
          userId: tempUserId!,
        ),
      ),
    );
  }

  void _msg(String? m) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(m ?? "Error")));
  }
}

// ---------------- OTP SCREEN ----------------

class OTPVerificationScreen extends StatefulWidget {
  final String mode;
  final String userId;

  const OTPVerificationScreen({
    super.key,
    required this.mode,
    required this.userId,
  });

  @override
  State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  final _otp = TextEditingController();

  void _verifyOtp() async {
    final res = widget.mode == "register"
        ? await ApiService.verifyEmailOtp(
            userId: widget.userId,
            otp: _otp.text,
          )
        : await ApiService.verifyLoginOtp(
            userId: widget.userId,
            otp: _otp.text,
          );

    if (res["message"]?.contains("successful") == true) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => HomePage(
            userData: {
              "name": res["name"] ?? "User",
              "email": res["email"] ?? "",
              "userId": widget.userId,
            },
          ),
        ),
        (_) => false,
      );
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(res["message"] ?? "Failed")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("OTP Verification")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text("Enter OTP sent to your email"),
            const SizedBox(height: 20),
            TextField(
              controller: _otp,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: "OTP",
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _verifyOtp,
              child: const Text("Verify"),
            ),
          ],
        ),
      ),
    );
  }
}
