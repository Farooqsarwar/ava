import 'package:ai_voice_agent/profile_screen.dart';
import 'package:flutter/material.dart';

import 'advisor_screen.dart';
import 'history screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  static final List<Widget> _widgetOptions = <Widget>[
    HomeContent(),
    HistoryScreen(),
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color(0xFF4BA1AE),
        body: _widgetOptions.elementAt(_selectedIndex),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF4BA1AE), Color(0xFF73B5C1)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4BA1AE).withOpacity(0.5),
                blurRadius: 15,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).padding.bottom + 12,
              top: 12,
              left: 16,
              right: 16,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavButton(0, Icons.home_rounded, 'Home'),
                  _buildNavButton(1, Icons.history_rounded, 'History'),
                  _buildNavButton(2, Icons.person_rounded, 'Profile'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavButton(int index, IconData icon, String label) {
    bool isSelected = _selectedIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => _onItemTapped(index),
        child: Container(
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
              colors: [Color(0xFF4BA1AE), Color(0xFF73B5C1)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            )
                : null,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : const Color(0xFF4BA1AE),
                size: 20,
              ),
              SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? Colors.white : const Color(0xFF4BA1AE),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomeContent extends StatelessWidget {
  HomeContent({super.key});

  final List<Map<String, dynamic>> _categories = [
    {
      'icon': Icons.auto_awesome_rounded,
      'title': 'Cosmetics',
      'description': 'Skin care & makeup',
      'category': 'Cosmetics',
      'color': Color(0xFFEC4899),
      'bgColor': Color(0xFFFCE7F3),
    },
    {
      'icon': Icons.health_and_safety_rounded,
      'title': 'Medical',
      'description': 'Health & wellness',
      'category': 'Medical',
      'color': Color(0xFF10B981),
      'bgColor': Color(0xFFD1FAE5),
    },
    {
      'icon': Icons.account_balance_wallet_rounded,
      'title': 'Financial',
      'description': 'Investments & budget',
      'category': 'Financial',
      'color': Color(0xFFF59E0B),
      'bgColor': Color(0xFFFEF3C7),
    },
    {
      'icon': Icons.flight_takeoff_rounded,
      'title': 'Travel',
      'description': 'Trips & stays',
      'category': 'Travel',
      'color': Color(0xFF8B5CF6),
      'bgColor': Color(0xFFEDE9FE),
    },
    {
      'icon': Icons.computer_rounded,
      'title': 'Tech Support',
      'description': 'Technical help',
      'category': 'Tech Support',
      'color': Color(0xFF3B82F6),
      'bgColor': Color(0xFFDBEAFE),
    },
    {
      'icon': Icons.gavel_rounded,
      'title': 'Legal',
      'description': 'Legal advice',
      'category': 'Legal',
      'color': Color(0xFFEF4444),
      'bgColor': Color(0xFFFEE2E2),
    },
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4BA1AE),
      appBar: AppBar(
        backgroundColor: const Color(0xFF4BA1AE),
        automaticallyImplyLeading: false,
        title: Container(
          width: MediaQuery.sizeOf(context).width,
          height: 115,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Image.asset(
            'assets/L6.png',
            fit: BoxFit.contain,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF4BA1AE),
              Color(0xFF73B5C1),
              Color(0xFF82BDC8),
              Color(0xFF92C6CF),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: ListView(
            children: [
              // Welcome card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.white, Color(0xFFF8FAFC)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 15,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Image in welcome card
                    SizedBox(height: 16),
                    Text(
                      "Hello, I'm AVA",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1E293B),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),
                    Text(
                      "Your Intelligent Assistant\nReady to Help You!",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF64748B),
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4BA1AE).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFF4BA1AE).withOpacity(0.2),
                        ),
                      ),
                      child: Text(
                        "Choose a category to get started",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF4BA1AE),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),

              // Categories title
              Text(
                "Expert Advisors",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),

              // Grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: _categories.length,
                itemBuilder: (context, index) => _buildCategoryCard(
                  context,
                  _categories[index],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCard(BuildContext context, Map<String, dynamic> category) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AdvisorScreen(category: category['category']),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    category['bgColor'],
                    category['bgColor'].withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                category['icon'],
                color: category['color'],
                size: 20,
              ),
            ),
            SizedBox(height: 8),
            Text(
              category['title'],
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E293B),
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 4),
            Text(
              category['description'],
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.normal,
                color: const Color(0xFF64748B),
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: category['color'].withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Start Chat',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: category['color'],
                    ),
                  ),
                  SizedBox(width: 2),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 9,
                    color: category['color'],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}