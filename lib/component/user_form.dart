import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mapping/screens/screen.dart';

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
  String? _state;
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
          _checkUserRole(userCredential.user?.uid);
        } else {
          // Registration logic
          if (_password != _confirmPassword) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Passwords do not match')),
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
              .doc(userCredential.user?.uid)
              .set({
            'email': _email!,
            'password': _password!,
            'state': _selectedState!, // Save the selected state
            'role': 'User', // Default role is 'User'
          });
          _checkUserRole(userCredential.user?.uid);
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
    if (userId != null) {
      User? user = _auth.currentUser;

      // Force a token refresh to get updated claims
      await user
          ?.getIdToken(true); // Refresh the token to include the latest claims

      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(userId).get();
      String role = userDoc.get('role') as String;

      print("User Role: $role"); // Debug line

      if (role == 'Admin') {
        Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (context) => const AdminDashboardScreen(),
        ));
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const DashboardScreen(),
          ),
        );
      }
    } else {
      print("User ID is null"); // Debug line
    }
  }

  //update user role
  Future<void> updateUserRole(String userId, String newRole) async {
    try {
      // Assuming the user is already authenticated as an Admin
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'role': newRole,
      });
      print('User role updated to $newRole');
    } catch (e) {
      print('Error updating user role: $e');
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
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _isLogin ? 'Login' : 'Register',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),
                const SizedBox(height: 20),
                // Email field
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
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
                const SizedBox(height: 20),
                // Password field with reveal icon
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
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
                      return 'Password must be at least 6 characters long';
                    }
                    return null;
                  },
                  onChanged: (value) => _password = value,
                ),
                const SizedBox(height: 20),
                if (!_isLogin) ...[
                  // Confirm password field for registration
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isConfirmPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
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
                  const SizedBox(height: 20),
                ],
                // State dropdown for registration
                if (!_isLogin) ...[
                  DropdownButtonFormField<String>(
                    value: _selectedState,
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedState = newValue;
                      });
                    },
                    decoration: InputDecoration(
                      labelText: 'State',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
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
                ],
                // State dropdown ends here

                if (_isLoading)
                  const CircularProgressIndicator()
                else ...[
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _submitForm,
                    child: Text(
                      _isLogin ? 'Login' : 'Register',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      backgroundColor: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (_isLogin)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _isLogin = false;
                        });
                      },
                      child: const Text(
                        'Don\'t have an account? Register here.',
                        style: TextStyle(fontSize: 16, color: Colors.black),
                      ),
                    )
                  else ...[
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _isLogin = true;
                        });
                      },
                      child: const Text(
                        'Already have an account? Login here.',
                        style: TextStyle(fontSize: 16, color: Colors.black),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  if (_isLogin)
                    TextButton(
                      onPressed: _forgotPassword,
                      child: const Text(
                        'Forgot Password?',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
