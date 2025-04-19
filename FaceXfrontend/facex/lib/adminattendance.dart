import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'adminmanager.dart';
import 'adminatdmanager.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  List<dynamic> students = [];
  List<dynamic> attendanceRecords = [];
  int selectedStudentIndex = 0;

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
      final fetched = json.decode(response.body);
      setState(() {
        students = fetched;
      });
      if (fetched.isNotEmpty) {
        fetchAttendance(fetched[0]['reg_no']);
      }
    }
  }

  Future<void> fetchAttendance(String regNo) async {
    final response = await http.get(
      Uri.parse('http://localhost:5000/attendance/$regNo'),
    );
    if (response.statusCode == 200) {
      final records = json.decode(response.body);
      records.sort(
        (a, b) =>
            DateTime.parse(b['date']).compareTo(DateTime.parse(a['date'])),
      );
      setState(() {
        attendanceRecords = records;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentStudent =
        students.isNotEmpty ? students[selectedStudentIndex] : null;

    return Scaffold(
      body: Row(
        children: [
          // Sidebar
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
                        selected: index == selectedStudentIndex,
                        selectedTileColor: Colors.white24,
                        onTap: () {
                          setState(() {
                            selectedStudentIndex = index;
                          });
                          fetchAttendance(students[index]['reg_no']);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Main Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Bar
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
                          _navItem("Student Attendance", () {}),
                          _navItem("Attendance Manager", () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => const AttendanceManagerPage(),
                              ),
                            );
                          }),
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

                // Student Name Tag
                if (currentStudent != null)
                  Container(
                    margin: const EdgeInsets.only(top: 30, left: 40),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3E8FF),
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.person, size: 24),
                        const SizedBox(width: 10),
                        Text(
                          currentStudent['name'],
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Attendance Records Grouped by Date
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 20,
                    ),
                    child:
                        attendanceRecords.isEmpty
                            ? Center(
                              child: Text(
                                "No attendance records found.",
                                style: GoogleFonts.poppins(fontSize: 16),
                              ),
                            )
                            : ListView(children: _buildGroupedAttendance()),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildGroupedAttendance() {
    Map<String, List<dynamic>> groupedByDate = {};
    Map<String, List<dynamic>> groupedBySubject = {};

    for (var rec in attendanceRecords) {
      final parsed = DateTime.parse(rec['date']);
      final date =
          "${parsed.year}-${parsed.month.toString().padLeft(2, '0')}-${parsed.day.toString().padLeft(2, '0')}";
      groupedByDate.putIfAbsent(date, () => []).add(rec);

      final subject = rec['subject'] ?? 'Unknown';
      groupedBySubject.putIfAbsent(subject, () => []).add(rec);
    }

    return groupedByDate.entries.map((entry) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "🗓️ ${entry.key}",
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.indigo,
            ),
          ),
          const SizedBox(height: 8),
          ...entry.value.map((r) {
            final subject = r['subject'] ?? 'Unknown Subject';
            final subjectRecords = groupedBySubject[subject] ?? [];
            final total = subjectRecords.length;
            final presentCount =
                subjectRecords.where((e) => e['status'] == "Present").length;
            final percent =
                total > 0 ? ((presentCount / total) * 100).round() : 0;

            return ListTile(
              leading: Icon(
                r['status'] == "Present" ? Icons.check_circle : Icons.cancel,
                color: r['status'] == "Present" ? Colors.green : Colors.red,
              ),
              title: Text("$subject", style: GoogleFonts.poppins(fontSize: 16)),
              subtitle: Text(
                "Status: ${r['status']}  •  $presentCount/$total → $percent%",
                style: GoogleFonts.poppins(fontSize: 14),
              ),
            );
          }),
          const Divider(),
        ],
      );
    }).toList();
  }

  Widget _navItem(String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
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
    );
  }
}
