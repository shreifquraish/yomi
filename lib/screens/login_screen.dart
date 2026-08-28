import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'notes_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isSigningIn = false;

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isSigningIn = true;
    });
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        if (mounted) {
          setState(() {
            _isSigningIn = false;
          });
        }
        return; // User aborted sign-in
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);
      
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const NotesScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'فشل تسجيل الدخول: $e',
              style: GoogleFonts.cairo(color: Colors.white),
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
    if (mounted) {
      setState(() {
        _isSigningIn = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient decoration
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFE8ECF8),
                  Color(0xFFF7F8FC),
                  Colors.white,
                ],
              ),
            ),
          ),
          // Subtle background decorative circles
          Positioned(
            top: -size.width * 0.4,
            right: -size.width * 0.4,
            child: CircleAvatar(
              radius: size.width * 0.4,
              backgroundColor: const Color(0xFF4F6DCE).withOpacity(0.05),
            ),
          ),
          Positioned(
            bottom: -size.width * 0.2,
            left: -size.width * 0.2,
            child: CircleAvatar(
              radius: size.width * 0.3,
              backgroundColor: const Color(0xFF4F6DCE).withOpacity(0.03),
            ),
          ),
          // Main Body
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Main Container Card
                    Container(
                      padding: const EdgeInsets.all(32.0),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF202535).withOpacity(0.06),
                            blurRadius: 24,
                            offset: const Offset(0, 12),
                          ),
                        ],
                        border: Border.all(
                          color: Colors.white,
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // App Logo
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF4F6DCE).withOpacity(0.2),
                                  blurRadius: 16,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(60),
                              child: Image.asset(
                                'assets/logo.jpeg',
                                height: 110,
                                width: 110,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    height: 110,
                                    width: 110,
                                    color: const Color(0xFF4F6DCE),
                                    child: const Icon(
                                      Icons.note_alt_rounded,
                                      size: 55,
                                      color: Colors.white,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),
                          // App Name
                          Text(
                            'يومي',
                            style: GoogleFonts.cairo(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF202535),
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Slogan / Description
                          Text(
                            'مساحتك الخاصة لحفظ ملاحظاتك وقوائم مهامك اليومية بذكاء وبساطة',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.cairo(
                              fontSize: 14,
                              height: 1.6,
                              color: const Color(0xFF202535).withOpacity(0.6),
                            ),
                          ),
                          const SizedBox(height: 36),
                          // Sign in Button or Loader
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: _isSigningIn
                                ? const SizedBox(
                                    height: 50,
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        color: Color(0xFF4F6DCE),
                                        strokeWidth: 3,
                                      ),
                                    ),
                                  )
                                : Material(
                                    color: const Color(0xFF4F6DCE),
                                    borderRadius: BorderRadius.circular(16),
                                    shadowColor: const Color(0xFF4F6DCE).withOpacity(0.4),
                                    elevation: 6,
                                    child: InkWell(
                                      onTap: _signInWithGoogle,
                                      borderRadius: BorderRadius.circular(16),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 14,
                                        ),
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              const Icon(
                                                Icons.login_rounded,
                                                color: Colors.white,
                                                size: 20,
                                              ),
                                              const SizedBox(width: 12),
                                              Text(
                                                'تسجيل الدخول عبر Google',
                                                style: GoogleFonts.cairo(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // App Footer Text
                    Text(
                      'صُنع بكل حب لتنظيم يومك',
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        color: const Color(0xFF202535).withOpacity(0.4),
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
}
