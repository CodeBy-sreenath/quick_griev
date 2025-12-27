import 'package:flutter/material.dart';
import 'admin_dashboard.dart';

// ✅ IMPORT YOUR API SERVICE
import '../services/admin_api.dart';

class LoginPage extends StatefulWidget {
  final String department;

  const LoginPage({Key? key, required this.department}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;

  // ✅ UPDATED: REAL LOGIN USING BACKEND API
  Future<void> handleLogin() async {
    if (usernameController.text.isEmpty ||
        passwordController.text.isEmpty) {
      _showMsg('Enter username & password', Colors.orange);
      return;
    }

    setState(() => isLoading = true);

    try {
      final response = await ApiService.adminLogin(
        department: widget.department,
        username: usernameController.text.trim(),
        password: passwordController.text.trim(),
      );

      setState(() => isLoading = false);

      if (response['success'] == true) {
        _showMsg('Login successful', Colors.green);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => AdminDashboard(
              adminData: {
                'department': widget.department,
                // optional: pass admin data if backend sends it
                'admin': response['admin'],
              },
            ),
          ),
        );
      } else {
        _showMsg(response['message'] ?? 'Login failed', Colors.red);
      }
    } catch (e) {
      setState(() => isLoading = false);
      _showMsg('Server error. Try again.', Colors.red);
    }
  }

  void _showMsg(String msg, Color c) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(backgroundColor: c, content: Text(msg)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
        child: Center(
          child: Container(
            width: 420,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  blurRadius: 25,
                  spreadRadius: 5,
                  color: Colors.black26,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'QuickGriev',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${widget.department} Department Login',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),

                const SizedBox(height: 30),

                // USERNAME
                TextField(
                  controller: usernameController,
                  decoration: InputDecoration(
                    labelText: 'Username',
                    prefixIcon: const Icon(Icons.person),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // PASSWORD
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // LOGIN BUTTON
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: isLoading
                        ? const CircularProgressIndicator(
                            color: Colors.white,
                          )
                        : const Text(
                            'Login',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
