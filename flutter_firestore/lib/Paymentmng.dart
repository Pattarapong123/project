import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async'; // เพิ่มการใช้ Timer
import 'BillMng.dart';  // เพิ่มการนำเข้าไฟล์ BillMng.dart

class Paymentmng extends StatefulWidget {
  const Paymentmng({super.key});

  @override
  State<Paymentmng> createState() => _PaymentmngState();
}

class _PaymentmngState extends State<Paymentmng> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  String _selectedCategory = 'รอพิจารณา'; // Default category

  final TextEditingController _T_nameController = TextEditingController();
  final TextEditingController _waterCostController = TextEditingController();
  final TextEditingController _electricityCostController = TextEditingController();

  double? latestEnergy;
  double? latestWater;
  double? waterCostInBaht;
  double? electricityCostInBaht;
  double? totalAmount;  // ตัวแปรสำหรับเก็บจำนวนเงินรวม

  late Timer _timer; // ตัวแปร Timer

  // ฟังก์ชันดึงข้อมูลจาก InfluxDB
  Future<void> fetchInfluxData() async {
    try {
      final response = await http.get(Uri.parse('http://localhost:3001/get-influx-data'));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        double? newEnergy;
        double? newWater;

        for (var item in data) {
          if (item['type'] == 'energy') {
            newEnergy = item['value']; // ค่าใช้พลังงาน (จำนวนหน่วยไฟฟ้า)
          } else if (item['type'] == 'water') {
            newWater = item['value']; // ค่าใช้น้ำ (จำนวนหน่วยน้ำ)
          }
        }

        // ตรวจสอบว่ามีการเปลี่ยนแปลงหรือไม่
        if (newEnergy != latestEnergy || newWater != latestWater) {
          // คำนวณค่าไฟและค่าน้ำในเงินบาท
          waterCostInBaht = (newWater ?? 0) * 20.0;  // ค่าน้ำ = ค่าที่ได้จาก InfluxDB * 20 บาท
          electricityCostInBaht = (newEnergy ?? 0) * 7.0;  // ค่าไฟ = kWh * 7 บาท

          // คำนวณจำนวนเงินรวม (ค่าห้อง + ค่าน้ำ + ค่าไฟ)
          totalAmount = 1500 + (waterCostInBaht ?? 0) + (electricityCostInBaht ?? 0);  // สมมติว่าค่าห้อง = 1500

          latestEnergy = newEnergy;
          latestWater = newWater;

          setState(() {}); // รีเฟรช UI

          // สร้างข้อมูลที่จะส่งไปยัง Firebase
          var meterData = {
            'waterUsage': latestWater?.toString() ?? '0',  // ค่าดิบของการใช้น้ำ
            'energyUsage': latestEnergy?.toString() ?? '0',  // ค่าดิบของการใช้พลังงาน
            'createdAt': FieldValue.serverTimestamp(), // เพิ่มวันที่และเวลา
            'roomNumber': '101', // หรือหมายเลขห้องที่ต้องการ
            'tenantID': 'tenant_id_example', // หรือ tenantID ที่ต้องการ
          };

          // ส่งข้อมูลไปยัง collection 'meter'
          await _addMeterData(meterData);

          // ส่งข้อมูลไปยัง collection 'Payments'
          await _addPayment({
            'waterUsage': latestWater?.toString() ?? '0',
            'energyUsage': latestEnergy?.toString() ?? '0',
            'waterCostInBaht': waterCostInBaht?.toStringAsFixed(2) ?? '0',
            'electricityCostInBaht': electricityCostInBaht?.toStringAsFixed(2) ?? '0',
            'totalAmount': totalAmount?.toStringAsFixed(2) ?? '0',
            'amount': totalAmount?.toStringAsFixed(2) ?? '0',
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      } else {
        print('❌ Failed to fetch InfluxDB data: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching data: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    fetchInfluxData(); // เรียกใช้ฟังก์ชันดึงข้อมูลครั้งแรก
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      fetchInfluxData(); // เรียกใช้ฟังก์ชันดึงข้อมูลทุกๆ 5 วินาที
    });
  }

  @override
  void dispose() {
    _timer.cancel();  // เมื่อ widget หายไป ให้หยุดการดึงข้อมูล
    super.dispose();
  }

  // ฟังก์ชันเพิ่มข้อมูลใน collection 'meter'
  Future<void> _addMeterData(Map<String, dynamic> meterData) async {
    try {
      await FirebaseFirestore.instance.collection('meter').add(meterData);
      print('เพิ่มข้อมูลใน collection meter สำเร็จ');
    } catch (e) {
      print('❌ Error adding data to meter collection: $e');
    }
  }

  // ฟังก์ชันดึงข้อมูลจาก Firebase
  Future<DocumentSnapshot> _getUser() async {
    String? uid = FirebaseAuth.instance.currentUser?.uid;
    return FirebaseFirestore.instance.collection('pro').doc(uid).get();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding( 
        padding: const EdgeInsets.only(top: 20.0, left: 0.0, right: 0.0, bottom: 20.0),
        child: Container(
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSearchAndAddButton(), // แสดงปุ่มค้นหาและเพิ่มการชำระเงิน
              const SizedBox(height: 20), // เว้นระยะห่าง
              _buildCategorySelector(), // ฟังก์ชันเลือกหมวดหมู่
              const SizedBox(height: 20), // เว้นระยะห่าง
              _buildPaymentList(), // แสดงรายการการชำระเงิน
            ],
          ),
        ),
      ),
    );
  }

  // ฟังก์ชันเพิ่มข้อมูลการชำระเงิน
  Future<void> _showAddPaymentDialog() async {
    String tenantID = "";
    String roomNumber = "";
    int amount = 0;

    double waterCost = 0.0;
    double electricityCost = 0.0;
    double total = 0.0;
    double waterMultiplier = 20.0;  // ตัวคูณค่าน้ำ
    double electricityMultiplier = 7.0;  // ตัวคูณค่าไฟฟ้า

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('ข้อมูลการชำระเงิน'),
          content: Column(
            children: [
              TextField(
                onChanged: (value) => roomNumber = value,
                decoration: const InputDecoration(labelText: 'หมายเลขห้อง'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: TextEditingController(text: latestWater?.toString() ?? '0.00'),
                decoration: const InputDecoration(labelText: 'การใช้งานน้ำ (จำนวนหน่วย)'),
                readOnly: true,
              ),
              TextField(
                controller: TextEditingController(text: latestEnergy?.toString() ?? '0.00'),
                decoration: const InputDecoration(labelText: 'การใช้งานไฟฟ้า (จำนวนหน่วย)'),
                readOnly: true,
              ),
              TextField(
                onChanged: (value) {
                  waterMultiplier = double.tryParse(value) ?? 20.0;
                },
                decoration: InputDecoration(labelText: 'ค่าน้ำหน่วยละ/บาท'),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
              TextField(
                onChanged: (value) {
                  electricityMultiplier = double.tryParse(value) ?? 7.0;
                },
                decoration: InputDecoration(labelText: 'ค่าไฟหน่วยละ/บาท'),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('ยกเลิก')),
            ElevatedButton(
              onPressed: () async {
                int? roomNumberInt = int.tryParse(roomNumber);

                if (roomNumberInt != null) {
                  // ดึงข้อมูลค่าเช่าห้อง (monthlyRent) จาก Collection 'rooms'
                  var roomSnapshot = await FirebaseFirestore.instance
                      .collection('rooms')
                      .where('roomNumber', isEqualTo: roomNumberInt)
                      .get();

                  if (roomSnapshot.docs.isNotEmpty) {
                    // ดึงค่า monthlyRent จากข้อมูลห้อง
                    double roomCost = roomSnapshot.docs[0].get('monthlyRent') ?? 1500;

                    // เพิ่มเงื่อนไขว่าห้อง 101 เท่านั้นที่คำนวณค่าใช้จ่ายได้
                    if (roomNumberInt == 101) {
                      waterCost = (latestWater ?? 0) * waterMultiplier;
                      electricityCost = (latestEnergy ?? 0) * electricityMultiplier;
                    } else {
                      waterCost = 0.0;
                      electricityCost = 0.0;
                    }

                    total = roomCost + waterCost + electricityCost;

                    // ดึงข้อมูลผู้เช่าจาก Firebase
                    var tenantSnapshot = await FirebaseFirestore.instance
                        .collection('tenants')
                        .where('roomNumber', isEqualTo: roomNumberInt)
                        .get();

                    if (tenantSnapshot.docs.isNotEmpty) {
                      tenantID = tenantSnapshot.docs[0].id;

                      // ดึงข้อมูล billID ล่าสุดจาก Payments
                      var paymentSnapshot = await FirebaseFirestore.instance
                          .collection('Payments')
                          .orderBy('createdAt', descending: true)
                          .limit(1)
                          .get();

                      String billID = paymentSnapshot.docs.isNotEmpty
                          ? paymentSnapshot.docs[0].id // ใช้ ID ล่าสุดที่บันทึก
                          : 'bill_${DateTime.now().millisecondsSinceEpoch}'; // สร้าง billID ใหม่ถ้าไม่มี

                      final paymentData = {
                        'tenantID': tenantID,
                        'roomNumber': roomNumber,
                        'roomCost': roomCost,
                        'amount': total.toStringAsFixed(2),
                        'paymentStatus': 'รอพิจารณา',
                        'waterCostInBaht': waterCost.toStringAsFixed(2),
                        'electricityCostInBaht': electricityCost.toStringAsFixed(2),
                        'waterUsage': latestWater?.toString() ?? '0',  // ค่าดิบของน้ำ
                        'energyUsage': latestEnergy?.toString() ?? '0',  // ค่าดิบของไฟฟ้า
                        'waterMultiplier': waterMultiplier.toString(), // เก็บตัวคูณค่าน้ำ
                        'electricityMultiplier': electricityMultiplier.toString(), // เก็บตัวคูณค่าไฟ
                        'billID': billID, // ใช้ billID ที่ดึงมา
                        'createdAt': FieldValue.serverTimestamp(), // เพิ่มวันที่และเวลาเมื่อเพิ่มการชำระเงิน
                      };

                      await _addPayment(paymentData);
                      Navigator.pop(context);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ไม่พบข้อมูลผู้เช่า')));
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ไม่พบข้อมูลห้อง')));
                  }
                }
              },
              child: const Text('เพิ่มการชำระเงิน'),
            ),
          ],
        );
      },
    );
  }

  // ฟังก์ชันเพิ่มการชำระเงินไปยัง Firebase
  Future<void> _addPayment(Map<String, dynamic> paymentData) async {
    var tenantSnapshot = await FirebaseFirestore.instance
        .collection('tenants')
        .doc(paymentData['tenantID'])
        .get();

    if (tenantSnapshot.exists) {
      String tenantName = tenantSnapshot['T_name'] ?? 'ไม่ระบุ';
      paymentData['T_name'] = tenantName;

      // เพิ่มข้อมูลการชำระเงินไปยัง Firebase พร้อมกับ billID ที่ดึงมา
      await FirebaseFirestore.instance.collection('Payments').add(paymentData);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('เพิ่มการชำระเงินสำเร็จ')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ไม่พบข้อมูลผู้เช่า')));
    }
  }

  // ฟังก์ชันสร้างปุ่มค้นหาและเพิ่มข้อมูลการชำระเงิน
  Widget _buildSearchAndAddButton() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'ค้นหาการชำระเงิน',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
        ),
        const SizedBox(width: 10),
        ElevatedButton.icon(
          onPressed: _showAddPaymentDialog,
          icon: const Icon(Icons.add),
          label: const Text('ดึงข้อมูลการชำระเงิน'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white),
        ),
      ],
    );
  }

  // ฟังก์ชันเลือกหมวดหมู่การชำระเงิน
  Widget _buildCategorySelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        _categoryButton('รอพิจารณา'),
        const SizedBox(width: 10),
        _categoryButton('ชำระแล้ว'),
        const SizedBox(width: 10),
        _categoryButton('ค้างชำระ'),
      ],
    );
  }

  // ฟังก์ชันสำหรับปุ่มหมวดหมู่การชำระเงิน
  Widget _categoryButton(String category) {
    Color backgroundColor;

    // กำหนดสีพื้นหลังของปุ่มตามหมวดหมู่ที่เลือก
    if (_selectedCategory == category) {
      if (category == 'ค้างชำระ') {
        backgroundColor = Colors.red; // สีแดงสำหรับ 'ค้างชำระ'
      } else if (category == 'ชำระแล้ว') {
        backgroundColor = Colors.green; // สีเขียวสำหรับ 'ชำระแล้ว'
      } else {
        backgroundColor = Colors.orange; // สีส้มสำหรับ 'รอพิจารณา'
      }
    } else {
      backgroundColor = Colors.grey; // สีเทาสำหรับปุ่มที่ไม่ได้เลือก
    }

    return ElevatedButton(
      onPressed: () => setState(() => _selectedCategory = category),
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor, // ใช้สีพื้นหลังตามที่กำหนด
      ),
      child: Text(
        category,
        style: const TextStyle(
          color: Colors.white, // ฟอนต์สีขาว
        ),
      ),
    );
  }

  // ฟังก์ชันแสดงรายการการชำระเงิน
  Widget _buildPaymentList() {
    return Expanded(
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('Payments')
            .where('paymentStatus', isEqualTo: _selectedCategory)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          var payments = snapshot.data!.docs;

          // กรองข้อมูลตามคำค้นหาที่พิมพ์ในช่องค้นหา (ไม่ใช้ phone)
          if (_searchQuery.isNotEmpty) {
            payments = payments.where((doc) {
              var data = doc.data() as Map<String, dynamic>? ?? {};
              return (data['T_name']?.toString().contains(_searchQuery) ?? false) ||
                     (data['roomNumber']?.toString().contains(_searchQuery) ?? false);
            }).toList();
          }

          return _buildPaymentTable(payments);
        },
      ),
    );
  }

  // ฟังก์ชันแสดงตารางการชำระเงิน
  Widget _buildPaymentTable(List<QueryDocumentSnapshot> payments) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black26),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SingleChildScrollView(
        child: DataTable(
          columnSpacing: 20,
          columns: const [
            DataColumn(label: Text('ลำดับ', style: TextStyle(fontSize: 15))),
            DataColumn(label: Text('ผู้เช่า', style: TextStyle(fontSize: 15))),
            DataColumn(label: Text('หมายเลขห้อง', style: TextStyle(fontSize: 15))),
            DataColumn(label: Text('ค่าห้อง', style: TextStyle(fontSize: 15))),
            DataColumn(label: Text('ค่าน้ำ', style: TextStyle(fontSize: 15))),
            DataColumn(label: Text('ค่าไฟ', style: TextStyle(fontSize: 15))),
            DataColumn(label: Text('จำนวนเงิน', style: TextStyle(fontSize: 15))),
            DataColumn(label: Text('การจัดการ', style: TextStyle(fontSize: 15))),
          ],
          rows: List.generate(payments.length, (index) {
            var payment = payments[index];
            return DataRow(cells: [
              DataCell(Text((index + 1).toString())),
              DataCell(Text(payment['T_name'] ?? 'ไม่ระบุ')),
              DataCell(Text(payment['roomNumber'] ?? 'ไม่ระบุ')),
              DataCell(Text(payment['roomCost'].toString() ?? 'ไม่ระบุ')),
              DataCell(Text(payment['waterCostInBaht'] ?? '0')),  // ค่าน้ำที่คำนวณแล้ว
              DataCell(Text(payment['electricityCostInBaht'] ?? '0')),  // ค่าไฟที่คำนวณแล้ว
              DataCell(Text(payment['amount'].toString() ?? '0')),  // จำนวนเงิน
              DataCell(
                Row(
                  children: [
                    if (_selectedCategory == 'รอพิจารณา') ...[ 
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () async {
                          await _updatePaymentStatus(payment.id, 'ชำระแล้ว');
                        },
                        child: const Text('ชำระแล้ว'),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () async {
                          await _updatePaymentStatus(payment.id, 'ค้างชำระ');
                        },
                        child: const Text('ค้างชำระ'),
                      ),
                    ],
                    if (_selectedCategory == 'ชำระแล้ว') ...[
                      IconButton(
                        icon: const Icon(Icons.receipt, color: Colors.blue),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BillMng(tenantID: payment['tenantID'], billID: payment.id), // ส่ง tenantID และ billID ไปที่ BillMng
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 10),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          await _deletePayment(payment.id);
                        },
                      ),
                    ],
                    if (_selectedCategory == 'ค้างชำระ') ...[
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () async {
                          await _updatePaymentStatus(payment.id, 'ชำระแล้ว');
                        },
                        child: const Text('ชำระแล้ว'),
                      ),
                    ],
                  ],
                ),
              ),
            ]);
          }),
        ),
      ),
    );
  }

  // ฟังก์ชันอัปเดตสถานะการชำระเงิน
  Future<void> _updatePaymentStatus(String paymentId, String newStatus) async {
    await FirebaseFirestore.instance
        .collection('Payments')
        .doc(paymentId)
        .update({
      'paymentStatus': newStatus,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('การชำระเงินได้ถูกย้ายไปยัง $newStatus')),
    );
  }

  // ฟังก์ชันลบการชำระเงิน
  Future<void> _deletePayment(String paymentId) async {
    await FirebaseFirestore.instance
        .collection('Payments')
        .doc(paymentId)
        .delete();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ข้อมูลการชำระเงินถูกลบแล้ว')),
    );
  }
}
