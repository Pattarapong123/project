import 'package:flutter/material.dart'; 
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:flutter/services.dart';  // สำหรับ rootBundle
import 'package:intl/intl.dart';  // สำหรับวันที่

class BillMng extends StatefulWidget {
  final String tenantID;
  final String billID; // เพิ่ม billID มาเป็นพารามิเตอร์
  const BillMng({super.key, required this.tenantID, required this.billID});

  @override
  _BillMngState createState() => _BillMngState();
}

class _BillMngState extends State<BillMng> {
  final _formKey = GlobalKey<FormState>();  // Key สำหรับ Form
  final TextEditingController _roomIDController = TextEditingController();
  final TextEditingController _billIDController = TextEditingController();
  final TextEditingController _billingDateController = TextEditingController();
  final TextEditingController _dueDateController = TextEditingController();
  final TextEditingController _electricityCostController = TextEditingController();
  final TextEditingController _electricityCostInBahtController = TextEditingController();
  final TextEditingController _waterCostController = TextEditingController();
  final TextEditingController _waterCostInBahtController = TextEditingController();
  final TextEditingController _outstandingAmountController = TextEditingController();
  final TextEditingController _totalAmountController = TextEditingController();
  final TextEditingController _roomCostController = TextEditingController(); // เพิ่มตัวแปรเพื่อรับค่า roomCost

  @override
  void initState() {
    super.initState();
    _generateBillingDate();  // เรียกใช้ฟังก์ชันสร้างวันที่ออกบิล
    _fetchBillData();  // ดึงข้อมูลจาก Firestore
  }

  // ฟังก์ชันสร้างวันที่ออกบิล
  void _generateBillingDate() {
    final now = DateTime.now();
    final formatter = DateFormat('yyyy-MM-dd'); // รูปแบบวันที่
    _billingDateController.text = formatter.format(now); // กำหนดวันที่เป็นวันที่ปัจจุบัน
  }

  // ฟังก์ชันดึงข้อมูลจาก Firestore
  Future<void> _fetchBillData() async {
    var paymentDoc = await FirebaseFirestore.instance
        .collection('Payments')
        .doc(widget.billID)  // ใช้ billID ที่รับมา
        .get();

    if (paymentDoc.exists) {
      var paymentData = paymentDoc.data();

      // ดึงข้อมูลที่จำเป็น
      _billIDController.text = paymentData?['billID'] ?? '';  // ดึง billID จาก Firestore
      _roomIDController.text = paymentData?['roomNumber'] ?? '';
      _dueDateController.text = paymentData?['dueDate'] ?? '';

      // ดึงค่าการใช้ไฟฟ้า (จำนวนหน่วย) และการใช้งานน้ำ (ค่าดิบ)
      _electricityCostController.text = paymentData?['energyUsage']?.toString() ?? '';  // energy usage (ค่าดิบ)
      _waterCostController.text = paymentData?['waterUsage']?.toString() ?? '';  // water usage (ค่าดิบ)

      // ค่าไฟฟ้าและค่าน้ำ (หน่วยเป็นบาท) ที่คำนวณแล้ว
      _electricityCostInBahtController.text = paymentData?['electricityCostInBaht']?.toString() ?? '';
      _waterCostInBahtController.text = paymentData?['waterCostInBaht']?.toString() ?? '';

      // ดึงข้อมูลยอดค้างชำระและยอดรวมทั้งหมด (amount) จากฐานข้อมูล
      _totalAmountController.text = paymentData?['amount']?.toString() ?? '';  // ดึงจาก amount

      // ดึงข้อมูลค่าเช่าห้อง (roomCost) จากฐานข้อมูล
      _roomCostController.text = paymentData?['roomCost']?.toString() ?? '';  // ดึงจาก roomCost

      setState(() {});
    }
  }

  // ฟังก์ชันพิมพ์บิลเป็น PDF
  Future<void> _printBill() async {
    final pdf = pw.Document();

    // โหลดฟอนต์
    final ttf = pw.Font.ttf(await rootBundle.load("assets/fonts/THSarabunNew.ttf"));

    // สร้างหน้า PDF
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4, // ตั้งขนาดกระดาษเป็น A4
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.black, width: 1),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Align(
                      alignment: pw.Alignment.center,  // จัดตำแหน่งคำว่า "ใบเสร็จรับเงิน" ให้อยู่ตรงกลาง
                      child: pw.Text('ใบเสร็จรับเงิน', style: pw.TextStyle(fontSize: 30, font: ttf, fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.SizedBox(height: 10),
                    _buildRow('หมายเลขบิล: ', _billIDController.text, ttf, 24), // ใช้ _billIDController.text
                    _buildRow('วันที่ออกบิล: ', _billingDateController.text, ttf, 24),
                    _buildRow('หมายเลขห้อง: ', _roomIDController.text, ttf, 24),
                    _buildRow('ค่าห้อง: ', _roomCostController.text, ttf, 24), // เพิ่มแสดงค่าห้อง
                    pw.Divider(),
                    _buildRow('การใช้งานไฟฟ้า: ', '${_electricityCostController.text} หน่วย', ttf, 24),
                    _buildRow('ค่าน้ำ: ', '${_waterCostController.text} หน่วย', ttf, 24),
                    _buildRow('ค่าไฟฟ้า (บาท): ', _electricityCostInBahtController.text, ttf, 24), // แสดงค่าไฟฟ้าในบาท
                    _buildRow('ค่าน้ำ (บาท): ', _waterCostInBahtController.text, ttf, 24), // แสดงค่าน้ำในบาท
                    pw.Divider(),
                    _buildRow('ยอดรวม: ', '${_totalAmountController.text} บาท', ttf, 28), // เพิ่มขนาดตัวอักษร
                    pw.SizedBox(height: 30),  // เพิ่มระยะห่างก่อนลายเซ็น
                    pw.Align(
                      alignment: pw.Alignment.center,  // จัดตำแหน่งลายเซ็นให้อยู่ตรงกลาง
                      child: pw.Text('ลายเซ็น: ___________________________ ผู้รับเงิน', style: pw.TextStyle(fontSize: 24, font: ttf)),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    // พิมพ์ PDF
    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  // ฟังก์ชันช่วยสร้างแถวข้อมูล
  pw.Widget _buildRow(String label, String value, pw.Font ttf, double fontSize) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: pw.TextStyle(font: ttf, fontSize: fontSize)),
        pw.Text(value, style: pw.TextStyle(font: ttf, fontSize: fontSize, fontWeight: pw.FontWeight.bold)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("จัดการบิล"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,  // กำหนด formKey
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                _buildTextField("หมายเลขบิล", _billIDController, TextInputType.text),
                _buildTextField("วันที่ออกบิล", _billingDateController, TextInputType.datetime),
                _buildTextField("รหัสห้อง", _roomIDController, TextInputType.number),
                _buildTextField("การใช้งานไฟฟ้า (จำนวนหน่วย)", _electricityCostController, TextInputType.number),
                _buildTextField("จำนวนค่าไฟฟ้า (หน่วยเป็นบาท)", _electricityCostInBahtController, TextInputType.number),
                _buildTextField("การใช้งานน้ำ (จำนวนหน่วย)", _waterCostController, TextInputType.number),
                _buildTextField("จำนวนค่าน้ำ (หน่วยเป็นบาท)", _waterCostInBahtController, TextInputType.number),
                _buildTextField("ยอดรวมทั้งหมด (ค่าชำระ + ค่าไฟฟ้า + ค่าน้ำ)", _totalAmountController, TextInputType.number),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _printBill, // เมื่อกดปุ่มจะพิมพ์บิล
                  child: const Text('พิมพ์ใบเสร็จ'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ฟังก์ชันสำหรับสร้างฟิลด์กรอกข้อมูลพร้อม validate
  Widget _buildTextField(String label, TextEditingController controller, TextInputType inputType) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        keyboardType: inputType,
        decoration: InputDecoration(labelText: label),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'กรุณากรอกข้อมูล $label';
          }
          return null;
        },
      ),
    );
  }
}
