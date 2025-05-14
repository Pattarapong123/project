import 'dart:ui' as ui;
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'Paymentmng.dart';
import 'Roommng.dart';
import 'Usermng.dart';
import 'Login.dart';

class FirstPage extends StatefulWidget {
  const FirstPage({super.key});

  @override
  State<FirstPage> createState() => _FirstPageState();
}

class _FirstPageState extends State<FirstPage> {
  List<String> iframeUrls = [
    'http://localhost:3000/d-solo/feiof04b23saoc/meter-water?orgId=1&from=now-5m&to=now&timezone=Asia%2FBangkok&refresh=5s&theme=light&panelId=2&__feature.dashboardSceneSolo',
    'http://localhost:3000/d-solo/feiof04b23saoc/meter-water?orgId=1&from=1746857819582&to=1746858119582&timezone=Asia%2FBangkok&refresh=auto&theme=light&panelId=3&__feature.dashboardSceneSolo',
    'http://localhost:3000/d-solo/feiof04b23saoc/meter-water?orgId=1&from=1746857852520&to=1746858152520&timezone=Asia%2FBangkok&refresh=auto&theme=light&panelId=4&__feature.dashboardSceneSolo',
    'http://localhost:3000/d-solo/feiof04b23saoc/meter-water?orgId=1&from=1746857872760&to=1746858172760&timezone=Asia%2FBangkok&refresh=auto&theme=light&panelId=5&__feature.dashboardSceneSolo',
  ];
  String currentPage = 'Dashboard';

  Map<String, String>? userData;

  @override
  void initState() {
    super.initState();

    // ลงทะเบียน iframe แต่ละตัว
    for (int i = 0; i < iframeUrls.length; i++) {
      ui.platformViewRegistry.registerViewFactory(
        'iframeElement$i',
        (int viewId) {
          final iframe = html.IFrameElement()
            ..src = iframeUrls[i]
            ..style.border = 'none'
            ..width = '100%'
            ..height = '400'
            ..setAttribute('frameborder', '0');

          return iframe;
        },
      );
    }
  }

  Stream<DocumentSnapshot> _getUser() {
    String? uid = FirebaseAuth.instance.currentUser?.uid;
    return FirebaseFirestore.instance.collection('pro').doc(uid).snapshots();
  }

  final Map<String, Widget> pageWidgets = {
    'Dashboard': HtmlElementView(viewType: 'iframeElement0'),
    'User Management': Usermng(),
    'Room Management': Roommng(),
    'Payment Management': Paymentmng(),
  };

  Widget _buildSidebar(BuildContext context, String fullname, String email, String firstletter) {
    return Container(
      width: 300,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF112C70),
            Color(0xFF3A5B93),
            Color(0xFF6A6FBA),
            Color(0xFF8A84D4),
            Color(0xFFB4A9D9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 50),
          CircleAvatar(
            radius: 40,
            backgroundColor: Color(0xFF7B8FDC),
            child: Text(
              firstletter,
              style: const TextStyle(fontSize: 30, color: Colors.white),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            fullname,
            style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          _buildMenuItem(Icons.dashboard, 'แดชบอร์ด', 'Dashboard'),
          _buildMenuItem(Icons.person, 'บริหารจัดการข้อมูลผู้เช่า', 'User Management'),
          _buildMenuItem(Icons.home, 'บริหารจัดการข้อมูลห้องเช่า', 'Room Management'),
          _buildMenuItem(Icons.payment, 'บริหารจัดการการชำระเงิน', 'Payment Management'),
          _buildMenuItem(Icons.logout, 'ออกจากระบบ', 'Logout', isLogout: true),
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, String pageName, {bool isLogout = false}) {
    final bool isSelected = currentPage == pageName;

    return Container(
      color: isSelected ? Color(0xFF8A7BFF) : Colors.transparent,
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? Colors.white : Colors.white70,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        onTap: () async {
          if (isLogout) {
            await FirebaseAuth.instance.signOut();
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const Login()),
              (route) => false,
            );
          } else {
            setState(() {
              currentPage = pageName;
            });
          }
        },
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _getUser(),
      builder: (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(child: Text('User not found'));
        }

        userData ??= {
          'fullname': snapshot.data!.get('fullname'),
          'email': snapshot.data!.get('email'),
        };

        String fullname = userData!['fullname']!;
        String email = userData!['email']!;
        String firstletter = fullname.isNotEmpty ? fullname[0].toUpperCase() : '?';

        return Scaffold(
          body: Row(
            children: [
              _buildSidebar(context, fullname, email, firstletter),
              Expanded(
                child: Container(
                  color: Colors.white,
                  child: Column(
                    children: [
                      AppBar(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        title: Padding(
                          padding: const EdgeInsets.only(top: 25.0),
                          child: Text(
                            _getAppBarTitle(currentPage),
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                        automaticallyImplyLeading: false,
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Center(
                            child: currentPage == 'Dashboard'
                                ? GridView.builder(
                                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2, // 2 คอลัมน์
                                      crossAxisSpacing: 10.0, // ระยะห่างระหว่างคอลัมน์
                                      mainAxisSpacing: 10.0, // ระยะห่างระหว่างแถว
                                      childAspectRatio: 1.5, // อัตราส่วนของขนาด
                                    ),
                                    itemCount: iframeUrls.length,
                                    itemBuilder: (context, index) {
                                      return Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: HtmlElementView(
                                          viewType: 'iframeElement$index',
                                        ),
                                      );
                                    },
                                  )
                                : pageWidgets[currentPage] ?? const Text('ไม่พบหน้านี้'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getAppBarTitle(String pageKey) {
    switch (pageKey) {
      case 'Dashboard':
        return 'แดชบอร์ด';
      case 'User Management':
        return 'บริหารจัดการข้อมูลผู้เช่า';
      case 'Room Management':
        return 'บริหารจัดการข้อมูลห้องเช่า';
      case 'Payment Management':
        return 'บริหารจัดการการชำระเงิน';
      default:
        return pageKey;
    }
  }
}
