import 'package:facex/adminattendance.dart';
import 'package:facex/adminmanager.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AttendanceManagerPage extends StatefulWidget {
  const AttendanceManagerPage({super.key});

  @override
  State<AttendanceManagerPage> createState() => _AttendanceManagerPageState();
}

class _AttendanceManagerPageState extends State<AttendanceManagerPage> {
  List<dynamic> students = [];
  String selectedSubject = '';
  DateTime? selectedDate;
  String attendanceStatus = '';
  String selectedRegNo = '';

  final List<String> subjects = [
    'Software Construction',
    'DBMS',
    'AI',
    'Web Development',
    'Operating Systems',
    'Testing Period',
  ];

  @override
  void initState() {
    super.initState();
    fetchStudents();
  }

  Future<void> fetchStudents() async {
    final response = await http.get(
      Uri.parse('http://localhost:5000/students'),
    );
    if (response.statusCode == 200) {
      setState(() {
        students = json.decode(response.body);
      });
    }
  }

  Future<void> fetchAttendanceStatus() async {
    if (selectedSubject.isEmpty ||
        selectedDate == null ||
        selectedRegNo.isEmpty) {
      return;
    }

    final String formattedDate = selectedDate!.toIso8601String().split('T')[0];
    final uri = Uri.parse(
      'http://localhost:5000/attendance/status?reg_no=$selectedRegNo&subject=$selectedSubject&date=$formattedDate',
    );

    final response = await http.get(uri);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        attendanceStatus = data['status'];
      });
    } else {
      setState(() {
        attendanceStatus = 'No Record';
      });
    }
  }

  Future<void> updateAttendanceStatus() async {
    if (selectedSubject.isEmpty ||
        selectedDate == null ||
        selectedRegNo.isEmpty) {
      return;
    }

    final newStatus = attendanceStatus == 'Present' ? 'Absent' : 'Present';

    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Confirm Update"),
            content: Text(
              "Are you sure you want to change the status to $newStatus?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Confirm"),
              ),
            ],
          ),
    );

    if (confirm == true) {
      final uri = Uri.parse('http://localhost:5000/attendance/update');
      final response = await http.put(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'reg_no': selectedRegNo,
          'subject': selectedSubject,
          'date': selectedDate!.toIso8601String().split('T')[0],
          'status': newStatus,
        }),
      );

      if (response.statusCode == 200) {
        fetchAttendanceStatus();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Container(
            width: 250,
            color: const Color(0xFF9B4DE0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 30,
                  ),
                  alignment: Alignment.centerLeft,
                  child: Image.asset(
                    'assets/rec_logo.jpg',
                    width: 200,
                    height: 90,
                    fit: BoxFit.contain,
                  ),
                ),
                const Divider(color: Colors.white70),
                Expanded(
                  child: ListView.builder(
                    itemCount: students.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        leading: const Icon(Icons.person, color: Colors.white),
                        title: Text(
                          students[index]['name'],
                          style: GoogleFonts.poppins(color: Colors.white),
                        ),
                        onTap: () {
                          setState(() {
                            selectedRegNo = students[index]['reg_no'];
                            attendanceStatus = '';
                          });
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 15,
                  ),
                  color: const Color(0xFF9B4DE0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Hi admin!",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Row(
                        children: [
                          _navItem("Student Attendance", () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => const AdminDashboardPage(),
                              ),
                            );
                          }),
                          _navItem("Attendance Manager", () {}),
                          _navItem("Manage Students", () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => const ManageStudentsPage(),
                              ),
                            );
                          }),
                          const SizedBox(width: 12),
                          const Icon(Icons.person, color: Colors.white),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (selectedRegNo.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.all(20),
                            width: 400,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3E8FF),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                DropdownButtonFormField(
                                  decoration: const InputDecoration(
                                    filled: true,
                                    fillColor: Colors.white,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(5),
                                      ),
                                    ),
                                  ),
                                  items:
                                      subjects
                                          .map(
                                            (subj) => DropdownMenuItem(
                                              value: subj,
                                              child: Text(subj),
                                            ),
                                          )
                                          .toList(),
                                  hint: const Text('Select Subject'),
                                  onChanged: (value) {
                                    setState(() {
                                      selectedSubject = value.toString();
                                    });
                                  },
                                ),
                                const SizedBox(height: 10),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF9B4DE0),
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: DateTime.now(),
                                      firstDate: DateTime(2023),
                                      lastDate: DateTime(2026),
                                    );
                                    if (picked != null) {
                                      setState(() {
                                        selectedDate = picked;
                                      });
                                    }
                                  },
                                  child: Text(
                                    selectedDate == null
                                        ? "Pick Date"
                                        : selectedDate!
                                            .toLocal()
                                            .toString()
                                            .split(' ')[0],
                                  ),
                                ),
                                const SizedBox(height: 10),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF9B4DE0),
                                  ),
                                  onPressed: fetchAttendanceStatus,
                                  child: const Text(
                                    "Check Status",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  attendanceStatus.isNotEmpty
                                      ? 'Status: $attendanceStatus'
                                      : '',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF9B4DE0),
                                  ),
                                  onPressed: updateAttendanceStatus,
                                  child: const Text(
                                    'Edit',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _navItem(String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: Text(
            label,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
