import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class RoomHistory extends StatefulWidget {
  final String roomId;

  const RoomHistory({super.key, required this.roomId});

  @override
  _RoomHistoryState createState() => _RoomHistoryState();
}

class _RoomHistoryState extends State<RoomHistory> {
  String tenantID = '';
  String roomNumber = '';
  String startDate = '';
  String endDate = '';
  String phone = '';
  String tName = '';

  @override
  void initState() {
    super.initState();
    _getTenantInfo();
  }

  Future<void> _getTenantInfo() async {
    var roomId = widget.roomId;

    try {
      var tenantSnapshot = await FirebaseFirestore.instance
          .collection('tenants')
          .where('roomID', isEqualTo: roomId)
          .get();

      if (tenantSnapshot.docs.isNotEmpty) {
        var tenantData = tenantSnapshot.docs.first.data();

        setState(() {
          tenantID = tenantSnapshot.docs.first.id;
          roomNumber = tenantData['roomNumber']?.toString() ?? '';
          startDate = tenantData['start_date'] ?? '';
          endDate = tenantData['end_date'] ?? '';
          phone = tenantData['phone'] ?? '';
          tName = tenantData['T_name'] ?? '';
        });

        _checkAndAddRoomHistory();
      } else {
        print('ไม่พบผู้เช่าที่เชื่อมโยงกับห้องนี้');
      }
    } catch (e) {
      print("Error fetching tenant data: $e");
    }
  }

  Future<void> _checkAndAddRoomHistory() async {
    try {
      var roomHistorySnapshot = await FirebaseFirestore.instance
          .collection('roomHistory')
          .where('roomNumber', isEqualTo: roomNumber)
          .where('tenantID', isEqualTo: tenantID)
          .get();

      if (roomHistorySnapshot.docs.isEmpty) {
        await FirebaseFirestore.instance.collection('roomHistory').add({
          'tenantID': tenantID,
          'roomNumber': roomNumber,
          'start_date': startDate,
          'end_date': endDate,
          'status': 'Active',
          'tenantName': tName,
          'phone': phone,
          'updateTimestamp': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('บันทึกข้อมูลการเปลี่ยนแปลงสำเร็จ')),
        );

        print('บันทึกข้อมูลประวัติห้องลงใน Firestore สำเร็จ');
      } else {
        print('ข้อมูลนี้มีอยู่แล้วใน roomHistory');
      }
    } catch (e) {
      print('Error adding room history: $e');
    }
  }

 @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      iconTheme: const IconThemeData(color: Colors.white),
      title: const Text('ประวัติผู้เช่า',style: TextStyle(color: Colors.white),),
      flexibleSpace: Container(
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
      ),
    ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black26),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DataTable(
            columnSpacing: 20,
            headingRowColor: MaterialStateColor.resolveWith((states) => Colors.blue.shade50),
            columns: const [
              DataColumn(label: Text('ลำดับ', style: TextStyle(fontSize: 16))),
              DataColumn(label: Text('ห้อง', style: TextStyle(fontSize: 16))),
              DataColumn(label: Text('วันที่เริ่ม', style: TextStyle(fontSize: 16))),
              DataColumn(label: Text('วันสิ้นสุด', style: TextStyle(fontSize: 16))),
              DataColumn(label: Text('ชื่อผู้เช่า', style: TextStyle(fontSize: 16))),
              DataColumn(label: Text('เบอร์โทร', style: TextStyle(fontSize: 16))),
            ],
            rows: [
              DataRow(cells: [
                const DataCell(Text('1')),
                DataCell(Text(roomNumber)),
                DataCell(Text(startDate)),
                DataCell(Text(endDate)),
                DataCell(Text(tName)),
                DataCell(Text(phone)),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}
