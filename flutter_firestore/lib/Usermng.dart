import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Usermng extends StatefulWidget {
  const Usermng({super.key});

  @override
  State<Usermng> createState() => _UsermngState();
}

class _UsermngState extends State<Usermng> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  Future<void> _addTenant(Map<String, dynamic> tenantData) async {
    int roomNumber = tenantData['roomNumber'];

    // ตรวจสอบห้องในระบบก่อนเพิ่มผู้เช่า
    var roomDoc = await FirebaseFirestore.instance
        .collection('rooms')
        .where('roomNumber', isEqualTo: roomNumber)
        .get();

    if (roomDoc.docs.isEmpty) {
      // ถ้าห้องไม่มีในระบบ แจ้งเตือนและไม่เพิ่มผู้เช่า
      showDialog(
        context: context,
        builder: (context) {
          return Center( // ทำให้อยู่กลางหน้าจอ
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 1000), // ปรับขนาดความกว้าง
              child: AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: const Text(
                  'ห้องไม่ถูกต้อง',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                content: const Text(
                  'ไม่สามารถเพิ่มผู้เช่าได้ เนื่องจากห้องนี้ไม่มีในระบบ',
                  style: TextStyle(fontSize: 18),
                ),
                actionsAlignment: MainAxisAlignment.center,
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.redAccent,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('ปิด', style: TextStyle(fontSize: 16)),
                  ),
                ],
              ),
            ),
          );
        },
      );
      return;
    }

    // ตรวจสอบว่าห้องนั้นมีผู้เช่าแล้วหรือไม่
    var existingTenant = await FirebaseFirestore.instance
        .collection('tenants')
        .where('roomNumber', isEqualTo: roomNumber)
        .get();

    if (existingTenant.docs.isNotEmpty) { // แจ้งเตือนเมื่อเลือกห้องซ้ำ
      showDialog(
        context: context,
        builder: (context) {
          return Center( // ทำให้อยู่กลางหน้าจอ
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 1000), // ปรับขนาดความกว้าง
              child: AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: const Text(
                  'กรุณาระบุห้องใหม่',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                content: const Text(
                  'ไม่สามารถเพิ่มผู้เช่าได้ เนื่องจากห้องนี้มีผู้เช่าในระบบแล้ว',
                  style: TextStyle(fontSize: 18),
                ),
                actionsAlignment: MainAxisAlignment.center,
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.redAccent,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('ปิด', style: TextStyle(fontSize: 16)),
                  ),
                ],
              ),
            ),
          );
        },
      );
      return;
    }

    // ถ้าห้องมีอยู่ในระบบและยังไม่มีผู้เช่า ให้เพิ่มผู้เช่า
    var docRef = await FirebaseFirestore.instance.collection('tenants').add({
      ...tenantData,
      'timestamp': FieldValue.serverTimestamp(),  // Add timestamp
    });

    String tenantID = docRef.id;

    await docRef.update({'tenantID': tenantID});

    // อัพเดตข้อมูลในห้อง
    String roomId = roomDoc.docs.first.id;

    await FirebaseFirestore.instance.collection('rooms').doc(roomId).update({
      'tenantID': tenantID,
      'room_status': 'ไม่ว่าง',
    });

    await FirebaseFirestore.instance.collection('tenants').doc(tenantID).update({
      'roomID': roomId,
    });
  }

  Future<void> _updateTenant(String tenantId, Map<String, dynamic> updatedData) async {
    await FirebaseFirestore.instance.collection('tenants').doc(tenantId).update(updatedData);
  }

  void _showAddOrEditTenantDialog({Map<String, dynamic>? tenantData, String? tenantId}) {
    String newTenantName = tenantData?['T_name'] ?? '';
    String newTenantRoom = tenantData?['roomNumber']?.toString() ?? '';
    String newTenantStartDate = tenantData?['start_date'] ?? '';
    String newTenantEndDate = tenantData?['end_date'] ?? '';
    String newTenantPhone = tenantData?['phone'] ?? '';
    String tenantStatus = tenantData?['status'] ?? 'Active';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(tenantData == null ? 'เพิ่มผู้เช่า' : 'แก้ไขผู้เช่า'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTextField((value) => newTenantName = value, 'ชื่อผู้เช่า', initialValue: newTenantName),
                _buildTextField((value) => newTenantStartDate = value, 'วันที่เริ่มเช่า', initialValue: newTenantStartDate),
                _buildTextField((value) => newTenantEndDate = value, 'วันที่หมดสัญญา', initialValue: newTenantEndDate),
                _buildTextField((value) => newTenantPhone = value, 'เบอร์โทร', initialValue: newTenantPhone),
                _buildTextField((value) => newTenantRoom = value, 'ห้อง', initialValue: newTenantRoom),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: tenantStatus,
                  decoration: const InputDecoration(labelText: 'สถานะผู้เช่า'),
                  items: ['Active', 'Inactive'].map((String value) {
                    return DropdownMenuItem<String>(value: value, child: Text(value));
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) tenantStatus = value;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('ยกเลิก')),
            ElevatedButton(
              onPressed: () {
                final tenantData = {
                  'T_name': newTenantName,
                  'roomNumber': int.parse(newTenantRoom),
                  'start_date': newTenantStartDate,
                  'end_date': newTenantEndDate,
                  'phone': newTenantPhone,
                  'status': tenantStatus,
                };

                if (tenantId == null) {
                  _addTenant(tenantData);
                } else {
                  _updateTenant(tenantId, tenantData);
                }

                Navigator.pop(context);
              },
              child: Text(tenantData == null ? 'เพิ่ม' : 'อัปเดต'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTextField(Function(String) onChanged, String label, {String? initialValue}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: TextEditingController(text: initialValue),
        decoration: InputDecoration(labelText: label),
        onChanged: onChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.only(top: 20.0, left: 0.0, right: 20.0, bottom: 20.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: 'ค้นหา',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8), // Replace 😎 with 8
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: () {
                    _showAddOrEditTenantDialog();
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('เพิ่มผู้เช่า'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('tenants')
                    .orderBy('timestamp', descending: false)  // การเรียงลำดับการแสดงผล
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  var tenants = snapshot.data?.docs ?? [];
                  if (_searchQuery.isNotEmpty) {
                    tenants = tenants.where((doc) {
                      var data = doc.data() as Map<String, dynamic>? ?? {};
                      return (data['T_name']?.toString().contains(_searchQuery) ?? false) ||
                             (data['phone']?.toString().contains(_searchQuery) ?? false) ||
                             (data['roomNumber']?.toString().contains(_searchQuery) ?? false);
                    }).toList();
                  }

                  return Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black26),
                      borderRadius: BorderRadius.circular(8), // Replace 😎 with 8
                    ),
                    child: SingleChildScrollView(
                      child: DataTable(
                        columnSpacing: 20,
                        columns: const [
                          DataColumn(label: Text('ลำดับ', style: TextStyle(fontSize: 15))),
                          DataColumn(label: Text('ผู้เช่า', style: TextStyle(fontSize: 15))),
                          DataColumn(label: Text('วันที่เช่า', style: TextStyle(fontSize: 15))),
                          DataColumn(label: Text('วันที่หมดสัญญา', style: TextStyle(fontSize: 15))),
                          DataColumn(label: Text('เบอร์โทร', style: TextStyle(fontSize: 15))),
                          DataColumn(label: Text('ห้อง', style: TextStyle(fontSize: 15))),
                          DataColumn(label: Text('สถานะ', style: TextStyle(fontSize: 15))),
                          DataColumn(label: Text('การจัดการ', style: TextStyle(fontSize: 15))),
                        ],
                        rows: List.generate(tenants.length, (index) {
                          var tenantDoc = tenants[index];
                          var tenant = tenantDoc.data() as Map<String, dynamic>? ?? {};

                          return DataRow(cells: [
                            DataCell(Text((index + 1).toString())),
                            DataCell(Text(tenant['T_name'] ?? 'ไม่มีข้อมูล')),
                            DataCell(Text(tenant['start_date'] ?? '-')),
                            DataCell(Text(tenant['end_date'] ?? '-')),
                            DataCell(Text(tenant['phone'] ?? '-')),
                            DataCell(Text(tenant['roomNumber'].toString())),
                            DataCell(Text(tenant['status'] ?? '-')),
                            DataCell(Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blueAccent),
                                  onPressed: () {
                                    _showAddOrEditTenantDialog(
                                      tenantData: tenant,
                                      tenantId: tenantDoc.id,
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () {
                                    // แสดงหน้าต่างยืนยันการลบ
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          title: const Text('ยืนยันการลบ'),
                                          content: const Text('คุณแน่ใจหรือว่าต้องการลบข้อมูลนี้?'),
                                          actions: [
                                            TextButton(
                                              onPressed: () {
                                                Navigator.pop(context); // ปิด Dialog
                                              },
                                              child: const Text('ยกเลิก'),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                // ลบข้อมูลจาก Firestore
                                                FirebaseFirestore.instance
                                                    .collection('tenants')
                                                    .doc(tenantDoc.id)
                                                    .delete()
                                                    .then((_) {
                                                      Navigator.pop(context); // ปิด Dialog หลังจากลบข้อมูล
                                                    }).catchError((error) {
                                                      print("Error deleting tenant: $error");
                                                    });
                                              },
                                              child: const Text('ยืนยัน'),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                ),
                              ],
                            )),
                          ]);
                        }),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
