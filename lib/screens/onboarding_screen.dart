import 'package:flutter/material.dart';
import 'package:mapping/screens/dashboard_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mapping/component/component.dart';

class OnboardingScreen extends StatefulWidget {
  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  List<Map<String, String>> onboardingData = [
    {
      "image": "assets/Frame 2.png",
      "text": "Know your Stakeholders",
    },
    {
      "image": "assets/splash screen 6.png",
      "text": "Easy Access to Stakeholders"
    },
    {
      "image": "assets/splash screen 7.png",
      "text": "Seamlessly manage Stakeholders"
    },
  ];

  void _completeOnboarding() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seenOnboarding', true);

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const DashboardScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (value) {
              setState(() {
                _currentPage = value;
              });
            },
            itemCount: onboardingData.length,
            itemBuilder: (context, index) => OnboardingContent(
              image: onboardingData[index]["image"]!,
              text: onboardingData[index]["text"]!,
            ),
          ),
          // Dots Indicator
          Positioned(
            bottom: 50,
            left: 20,
            child: Row(
              children: List.generate(
                onboardingData.length,
                (index) => _buildDot(index),
              ),
            ),
          ),
          // Previous and Next/Done buttons
          Positioned(
            bottom: 50,
            right: 20,
            child: Row(
              children: [
                if (_currentPage != 0)
                  TextButton(
                    onPressed: () {
                      _pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.ease,
                      );
                    },
                    child: const Text(
                      "Previous",
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                const SizedBox(width: 10),
                TextButton(
                  onPressed: () {
                    if (_currentPage == onboardingData.length - 1) {
                      _completeOnboarding();
                    } else {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.ease,
                      );
                    }
                  },
                  child: Text(
                    _currentPage == onboardingData.length - 1
                        ? "Get Started"
                        : "Next",
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Dots Indicator
  AnimatedContainer _buildDot(int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(right: 5),
      height: 8,
      width: _currentPage == index ? 24 : 8,
      decoration: BoxDecoration(
        color: _currentPage == index ? Colors.white : Colors.grey,
        borderRadius: BorderRadius.circular(5),
      ),
    );
  }
}
