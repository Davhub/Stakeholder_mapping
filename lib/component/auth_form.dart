import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:impact_konnect/screens/screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _email;
  String? _password;
  String? _confirmPassword;
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLogin = true; // Toggle between login and registration

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // List of states for dropdown
  List<String> _states = [
    'Lagos',
    'Oyo',
    'Ogun',
    'Osun',
    'Ekiti',
    'Ondo',
  ]; // Example states
  String? _selectedState;

  // Submit form logic
  Future<void> _submitForm() async {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();

      setState(() {
        _isLoading = true;
      });

      try {
        if (_isLogin) {
          // Login logic
          UserCredential userCredential =
              await _auth.signInWithEmailAndPassword(
            email: _email!,
            password: _password!,
          );
          // Ensure a profile document exists before routing. This must be
          // awaited: routing reads the role straight back, so an
          // unawaited write here would race and look like a failed login.
          final uid = userCredential.user!.uid;
          final doc = await _firestore.collection('users').doc(uid).get();
          if (!doc.exists) {
            debugPrint('No profile document for $uid; creating a default one.');
            await _firestore.collection('users').doc(uid).set({
              'email': _email!,
              'state': 'Oyo',
              'role': 'User',
              'createdAt': FieldValue.serverTimestamp(),
            });
          }
          await _checkUserRole(uid);
        } else {
          // Registration logic
          if (_password != _confirmPassword) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Passwords do not match')),
            );
            return;
          }
          if (_selectedState == null || _selectedState!.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please select a state')),
            );
            return;
          }
          UserCredential userCredential =
              await _auth.createUserWithEmailAndPassword(
            email: _email!,
            password: _password!,
          );
          await _firestore
              .collection('users')
              .doc(userCredential.user!.uid)
              .set({
            'email': _email!,
            // Never persist the password: Firebase Auth already stores it
            // securely hashed. Keeping a plaintext copy here would expose
            // every account to anyone who can read the users collection.
            'state': _selectedState!, // Save the selected state
            'role': 'User', // Default role is 'User'
            'createdAt': FieldValue.serverTimestamp(),
          });
          debugPrint('User registered: $_email with state: $_selectedState');
          await _checkUserRole(userCredential.user!.uid);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('${_isLogin ? 'Login' : 'Registration'} successful!')),
        );
      } on FirebaseAuthException catch (e) {
        String errorMessage = 'Authentication failed';
        if (e.code == 'user-not-found') {
          errorMessage = 'No user found for this email.';
        } else if (e.code == 'wrong-password') {
          errorMessage = 'Incorrect password.';
        } else if (e.code == 'email-already-in-use') {
          errorMessage = 'Email is already in use.';
        } else if (e.code == 'weak-password') {
          errorMessage = 'Password is too weak.';
        } else {
          debugPrint('Firebase Auth Error Code: ${e.code}');
          debugPrint('Firebase Auth Error Message: ${e.message}');
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Check user role after login or registration
  Future<void> _checkUserRole(String? userId) async {
    if (userId == null) {
      debugPrint('User ID is null; cannot route after sign-in.');
      return;
    }

    User? user = _auth.currentUser;

    // Force a token refresh to get updated claims
    await user
        ?.getIdToken(true); // Refresh the token to include the latest claims

    // Read the role defensively. A missing document or missing/!String
    // 'role' field used to throw here, and because that isn't a
    // FirebaseAuthException it escaped the caller's catch block and
    // surfaced as a silent, unexplained login failure.
    String role = 'User';
    bool isActive = true;
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final data = userDoc.data();
      final rawRole = data == null ? null : data['role'];
      if (rawRole is String && rawRole.trim().isNotEmpty) {
        role = rawRole.trim();
      } else {
        debugPrint('No usable role for $userId; defaulting to "User".');
      }
      // Absent means active, so existing accounts aren't locked out by
      // the introduction of this field.
      final rawActive = data == null ? null : data['active'];
      if (rawActive is bool) isActive = rawActive;
    } catch (e) {
      debugPrint('Could not read role for $userId ($e); defaulting to "User".');
    }

    // A Super Admin can revoke access by disabling the account. The client
    // SDK can't disable the underlying auth record, so the block is
    // enforced here at sign-in.
    if (!isActive) {
      await _auth.signOut();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'This account has been disabled. Contact your administrator.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    debugPrint('User Role: $role');

    if (!mounted) return;

    // 'Super Admin' is a superset of 'Admin', so it gets the admin
    // dashboard too rather than falling through to the plain user home.
    if (role == 'Admin' || role == 'Super Admin') {
      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (context) => const AdminDashboardScreen(),
      ));
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const HomeScreenWithNavbar(),
        ),
      );
    }
  }

  // Forgot password logic
  Future<void> _forgotPassword() async {
    if (_email == null || _email!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email')),
      );
      return;
    }
    try {
      await _auth.sendPasswordResetEmail(email: _email!);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset email sent!')),
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password reset failed: ${e.message}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo Section
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade600, Colors.blue.shade400],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.people_alt_rounded,
                      size: 50,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Title
                  Text(
                    _isLogin ? 'Welcome Back!' : 'Create Account',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isLogin
                        ? 'Sign in to continue'
                        : 'Register to get started',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Auth Card
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          // Email field
                          TextFormField(
                            decoration: InputDecoration(
                              labelText: 'Email Address',
                              prefixIcon:
                                  const Icon(Icons.email_outlined, size: 20),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                    color: Colors.blue, width: 2),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                            ),
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your email';
                              } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
                                  .hasMatch(value)) {
                                return 'Please enter a valid email';
                              }
                              return null;
                            },
                            onSaved: (value) => _email = value,
                          ),
                          const SizedBox(height: 16),

                          // Password field
                          TextFormField(
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon:
                                  const Icon(Icons.lock_outline, size: 20),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                    color: Colors.blue, width: 2),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isPasswordVisible
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  size: 20,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isPasswordVisible = !_isPasswordVisible;
                                  });
                                },
                              ),
                            ),
                            obscureText: !_isPasswordVisible,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
                              } else if (value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                            onChanged: (value) => _password = value,
                          ),
                          const SizedBox(height: 16),

                          // Confirm password field (only for registration)
                          if (!_isLogin) ...[
                            TextFormField(
                              decoration: InputDecoration(
                                labelText: 'Confirm Password',
                                prefixIcon:
                                    const Icon(Icons.lock_outline, size: 20),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                      BorderSide(color: Colors.grey.shade300),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                      color: Colors.blue, width: 2),
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isConfirmPasswordVisible
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _isConfirmPasswordVisible =
                                          !_isConfirmPasswordVisible;
                                    });
                                  },
                                ),
                              ),
                              obscureText: !_isConfirmPasswordVisible,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please confirm your password';
                                } else if (value != _password) {
                                  return 'Passwords do not match';
                                }
                                return null;
                              },
                              onChanged: (value) => _confirmPassword = value,
                            ),
                            const SizedBox(height: 16),
                          ],

                          // State dropdown (only for registration)
                          if (!_isLogin) ...[
                            DropdownButtonFormField<String>(
                              value: _selectedState,
                              onChanged: (String? newValue) {
                                setState(() {
                                  _selectedState = newValue;
                                });
                              },
                              decoration: InputDecoration(
                                labelText: 'Select State',
                                prefixIcon:
                                    const Icon(Icons.map_outlined, size: 20),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                      BorderSide(color: Colors.grey.shade300),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                      color: Colors.blue, width: 2),
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please select a state';
                                }
                                return null;
                              },
                              items: _states.map((state) {
                                return DropdownMenuItem<String>(
                                  value: state,
                                  child: Text(state),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 24),
                          ],

                          // Forgot Password (only for login)
                          if (_isLogin)
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: _forgotPassword,
                                child: const Text(
                                  'Forgot Password?',
                                  style: TextStyle(
                                    color: Colors.blue,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),

                          const SizedBox(height: 8),

                          // Submit Button
                          if (_isLoading)
                            const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: CircularProgressIndicator(),
                            )
                          else
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _submitForm,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                child: Text(
                                  _isLogin ? 'Sign In' : 'Create Account',
                                  style: const TextStyle(
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
                  const SizedBox(height: 24),

                  // Toggle between Login and Register
                  // Row(
                  //   mainAxisAlignment: MainAxisAlignment.center,
                  //   children: [
                  //     Text(
                  //       _isLogin
                  //           ? "Don't have an account? "
                  //           : 'Already have an account? ',
                  //       style: TextStyle(
                  //         color: Colors.grey[600],
                  //         fontSize: 14,
                  //       ),
                  //     ),
                  //     TextButton(
                  //       onPressed: () {
                  //         setState(() {
                  //           _isLogin = !_isLogin;
                  //         });
                  //       },
                  //       child: Text(
                  //         _isLogin ? 'Sign Up' : 'Sign In',
                  //         style: const TextStyle(
                  //           color: Colors.blue,
                  //           fontSize: 14,
                  //           fontWeight: FontWeight.bold,
                  //         ),
                  //       ),
                  //     ),
                  //   ],
                  // ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
