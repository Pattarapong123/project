import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'roomHistory.dart';

class Roommng extends StatefulWidget {
  const Roommng({super.key});

  @override
  State<Roommng> createState() => _RoommngState();
}

class _RoommngState extends State<Roommng> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    listenToTenantChanges();
  }

  void listenToTenantChanges() {
    FirebaseFirestore.instance.collection('tenants').snapshots().listen((snapshot) async {
      final tenantRoomIDs = snapshot.docs.map((doc) => doc['roomID']).toSet();

      final roomSnapshot = await FirebaseFirestore.instance.collection('rooms').get();

      for (var roomDoc in roomSnapshot.docs) {
        String roomId = roomDoc.id;

        // ถ้าห้องนี้ไม่มีผู้เช่า -> set สถานะเป็น "ว่าง"
        if (!tenantRoomIDs.contains(roomId)) {
          await FirebaseFirestore.instance.collection('rooms').doc(roomId).update({
            'room_status': 'ว่าง',
            'status': 'ว่าง',
            'tenantID': '',
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(0.0),
        child: Container(
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              _buildSearchAndAddButton(),
              const SizedBox(height: 20),
              _buildRoomList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchAndAddButton() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'ค้นหาห้องเช่า',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
        ),
        const SizedBox(width: 10),
        ElevatedButton.icon(
          onPressed: () => _showAddOrEditRoomDialog(),
          icon: const Icon(Icons.add),
          label: const Text('เพิ่มห้องเช่า'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white),
        ),
      ],
    );
  }

  Widget _buildRoomList() {
    return Expanded(
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('rooms')
            .orderBy('roomNumber', descending: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          var rooms = snapshot.data!.docs;
          if (_searchQuery.isNotEmpty) {
            rooms = rooms.where((doc) {
              String room = doc['roomNumber'].toString();
              String status = doc['status'].toString();
              return room.contains(_searchQuery) || status.contains(_searchQuery);
            }).toList();
          }

          return _buildRoomTable(rooms);
        },
      ),
    );
  }

  Widget _buildRoomTable(List<QueryDocumentSnapshot> rooms) {
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
            DataColumn(label: Text('ห้อง', style: TextStyle(fontSize: 15))),
            DataColumn(label: Text('สถานะห้อง', style: TextStyle(fontSize: 15))),
            DataColumn(label: Text('ค่าเช่า', style: TextStyle(fontSize: 15))),
            DataColumn(label: Text('ค่ามัดจำ', style: TextStyle(fontSize: 15))),
            DataColumn(label: Text('การจัดการ', style: TextStyle(fontSize: 15))),
          ],
          rows: List.generate(rooms.length, (index) {
            var room = rooms[index];
            return DataRow(cells: [
              DataCell(Text((index + 1).toString())),
              DataCell(Text(room['roomNumber'].toString())),
              DataCell(Text(room['room_status'] ?? 'ไม่ระบุ')),
              DataCell(Text(room['monthlyRent'].toString())),
              DataCell(Text(room['deposit'].toString())),
              DataCell(_buildRoomActions(room)),
            ]);
          }),
        ),
      ),
    );
  }

  Widget _buildRoomActions(QueryDocumentSnapshot room) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.history, color: Colors.orange),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RoomHistory(roomId: room.id),
              ),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.edit, color: Colors.blue),
          onPressed: () => _showAddOrEditRoomDialog(
              roomData: room.data() as Map<String, dynamic>, roomId: room.id),
        ),
        IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () async {
            bool? confirm = await _showDeleteConfirmationDialog();
            if (confirm == true) {
              FirebaseFirestore.instance.collection('rooms').doc(room.id).delete();
            }
          },
        ),
      ],
    );
  }

  void _showAddOrEditRoomDialog({Map<String, dynamic>? roomData, String? roomId}) {
    String newRoom = roomData?['roomNumber']?.toString() ?? '';
    String newRoomStatus = roomData?['status'] ?? 'ว่าง';
    int newMonthlyRent = roomData?['monthlyRent'] ?? 0;
    int newDeposit = roomData?['deposit'] ?? 0;
    int newRentFee = roomData?['rent_fee'] ?? 0;
    String newTenantID = roomData?['tenantID'] ?? '';

    final TextEditingController newRoomController = TextEditingController(text: newRoom);
    final TextEditingController newMonthlyRentController = TextEditingController(text: newMonthlyRent.toString());
    final TextEditingController newDepositController = TextEditingController(text: newDeposit.toString());
    final TextEditingController newRentFeeController = TextEditingController(text: newRentFee.toString());

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(roomData == null ? 'เพิ่มห้องเช่า' : 'แก้ไขห้องเช่า'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTextField(newRoomController, 'หมายเลขห้อง'),
                _buildTextField(newMonthlyRentController, 'ค่าเช่า'),
                _buildTextField(newDepositController, 'ค่ามัดจำ'),
                _buildTextField(newRentFeeController, 'ค่าบริการ'),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: ['ว่าง', 'ไม่ว่าง', 'กำลังซ่อมบำรุง'].contains(newRoomStatus)
                      ? newRoomStatus
                      : 'ว่าง',
                  decoration: const InputDecoration(labelText: 'สถานะห้อง'),
                  items: ['ว่าง', 'ไม่ว่าง', 'กำลังซ่อมบำรุง'].map((String value) {
                    return DropdownMenuItem<String>(value: value, child: Text(value));
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        newRoomStatus = value;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('ยกเลิก')),
            ElevatedButton(
              onPressed: () async {
                final roomData = {
                  'roomNumber': int.parse(newRoomController.text),
                  'status': newRoomStatus,
                  'monthlyRent': int.parse(newMonthlyRentController.text),
                  'deposit': int.parse(newDepositController.text),
                  'rent_fee': int.parse(newRentFeeController.text),
                  'room_status': newRoomStatus,
                  'tenantID': newTenantID,
                };

                if (roomId == null) {
                  await _addRoom(roomData);
                } else {
                  await _updateRoom(roomId, roomData);
                }

                Navigator.pop(context);
              },
              child: Text(roomData == null ? 'เพิ่ม' : 'อัปเดต'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }

  Future<void> _addRoom(Map<String, dynamic> roomData) async {
    var docRef = await FirebaseFirestore.instance.collection('rooms').add(roomData);
    await docRef.update({
      'roomID': docRef.id,
    });
  }

  Future<void> _updateRoom(String roomId, Map<String, dynamic> updatedData) async {
    await FirebaseFirestore.instance.collection('rooms').doc(roomId).update(updatedData);
  }

  Future<bool?> _showDeleteConfirmationDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('ยืนยันการลบ'),
          content: const Text('คุณแน่ใจหรือไม่ว่าต้องการลบข้อมูลนี้?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('ยกเลิก')),
            ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('ยืนยัน')),
          ],
        );
      },
    );
  }
}
