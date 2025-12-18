import 'package:flutter/material.dart';
import 'package:quick_griev/services/api_service.dart';
//import 'services/api_service.dart';

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: AuthScreen(),
  ));
}

// ---------------- AUTH SCREEN ----------------

class AuthScreen extends StatefulWidget {
  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isLogin = true;

  // Registration controllers
  final _name = TextEditingController();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  // Login controllers
  final _loginUsername = TextEditingController();
  final _loginEmail = TextEditingController();
  final _loginPassword = TextEditingController();

  // Forgot password controllers
  final _forgotEmailController = TextEditingController();
  final _resetOtpController = TextEditingController();
  final _newPasswordController = TextEditingController();

  String? tempUserId; // store backend userId

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
                padding: EdgeInsets.all(30),
                margin: EdgeInsets.symmetric(vertical: 40),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      isLogin ? "User Login" : "User Registration",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[900],
                      ),
                    ),

                    SizedBox(height: 25),

                    if (!isLogin) ...[
                      _inputField(_name, "Full Name"),
                      _inputField(_username, "Username"),
                      _inputField(_email, "Email"),
                      _inputField(_password, "Password", isPassword: true),
                    ],

                    if (isLogin) ...[
                      _inputField(_loginUsername, "Username"),
                      _inputField(_loginEmail, "Email"),
                      _inputField(_loginPassword, "Password", isPassword: true),

                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => _showForgotPasswordDialog(),
                          child: Text("Forgot Password?"),
                        ),
                      ),
                    ],

                    SizedBox(height: 20),

                    ElevatedButton(
                      onPressed: () {
                        isLogin ? _handleLogin() : _handleRegister();
                      },
                      child: Text(
                        isLogin ? "Login" : "Register",
                        style: TextStyle(fontSize: 18),
                      ),
                    ),

                    SizedBox(height: 20),

                    GestureDetector(
                      onTap: () {
                        setState(() {
                          isLogin = !isLogin;
                        });
                      },
                      child: Text(
                        isLogin
                            ? "Don't have an account? Register"
                            : "Already have an account? Login",
                        textAlign: TextAlign.center,
                      ),
                    )
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _inputField(TextEditingController controller, String label,
      {bool isPassword = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
      ),
    );
  }

  // ✅ REGISTER CONNECTED TO BACKEND
  void _handleRegister() async {
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
      _showMessage(res["message"]);
    }
  }

  // ✅ LOGIN CONNECTED TO BACKEND
  void _handleLogin() async {
    final res = await ApiService.login(
      username: _loginUsername.text,
      email: _loginEmail.text,
      password: _loginPassword.text,
    );

    if (res["userId"] != null) {
      tempUserId = res["userId"];
      _goToOTP("login");
    } else {
      _showMessage(res["message"]);
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

  void _showMessage(String? msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg ?? "Something went wrong")),
    );
  }

  // ---------------- Forgot Password UI (Only UI for now) ----------------

  void _showForgotPasswordDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Forgot Password"),
        content: TextField(
          controller: _forgotEmailController,
          decoration: InputDecoration(labelText: "Enter your email"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showResetOtpDialog();
            },
            child: Text("Send OTP"),
          )
        ],
      ),
    );
  }

  void _showResetOtpDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Verify OTP"),
        content: TextField(
          controller: _resetOtpController,
          decoration: InputDecoration(labelText: "Enter OTP"),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showNewPasswordDialog();
            },
            child: Text("Verify"),
          )
        ],
      ),
    );
  }

  void _showNewPasswordDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Reset Password"),
        content: TextField(
          controller: _newPasswordController,
          obscureText: true,
          decoration: InputDecoration(labelText: "New password"),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showMessage("Password reset successful!");
            },
            child: Text("Save Password"),
          )
        ],
      ),
    );
  }
}

// ---------------- OTP SCREEN ----------------

class OTPVerificationScreen extends StatefulWidget {
  final String mode;
  final String userId;

  OTPVerificationScreen({required this.mode, required this.userId});

  @override
  _OTPVerificationScreenState createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  final _otpController = TextEditingController();

  void _verifyOtp() async {
    final res = widget.mode == "register"
        ? await ApiService.verifyEmailOtp(
            userId: widget.userId, otp: _otpController.text)
        : await ApiService.verifyLoginOtp(
            userId: widget.userId, otp: _otpController.text);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(res["message"] ?? "Failed")),
    );

    if (res["message"]?.toString().contains("successful") == true) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Verify OTP")),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Text("Enter OTP sent to your email"),
            SizedBox(height: 20),
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                  labelText: "Enter OTP", border: OutlineInputBorder()),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _verifyOtp,
              child: Text("Verify OTP"),
            )
          ],
        ),
      ),
    );
  }
}
