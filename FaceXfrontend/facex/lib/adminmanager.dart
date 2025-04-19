import 'package:facex/adminatdmanager.dart';
import 'package:facex/adminattendance.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';

class ManageStudentsPage extends StatefulWidget {
  const ManageStudentsPage({super.key});

  @override
  State<ManageStudentsPage> createState() => _ManageStudentsPageState();
}

class _ManageStudentsPageState extends State<ManageStudentsPage> {
  List<dynamic> students = [];
  String name = '';
  String regNo = '';
  String email = '';
  String password = '';
  PlatformFile? faceImage;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController regNoController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchStudents();
  }

  Future<void> fetchStudents() async {
    final res = await http.get(Uri.parse("http://localhost:5000/students"));
    if (res.statusCode == 200) {
      setState(() {
        students = jsonDecode(res.body);
      });
    }
  }

  Future<void> pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );

    if (result != null) {
      setState(() {
        faceImage = result.files.first;
      });
    }
  }

  Future<void> addStudent() async {
    if (faceImage == null ||
        name.isEmpty ||
        regNo.isEmpty ||
        email.isEmpty ||
        password.isEmpty) {
      return;
    }

    final request = http.MultipartRequest(
      "POST",
      Uri.parse("http://localhost:5000/admin/add-student"),
    );
    request.fields['name'] = name;
    request.fields['reg_no'] = regNo;
    request.fields['email'] = email;
    request.fields['password'] = password;

    // ✅ Web-compatible image upload
    request.files.add(
      http.MultipartFile.fromBytes(
        'face_image',
        faceImage!.bytes!,
        filename: faceImage!.name,
      ),
    );

    final response = await request.send();
    if (response.statusCode == 201) {
      setState(() {
        name = '';
        regNo = '';
        email = '';
        password = '';
        faceImage = null;

        nameController.clear();
        regNoController.clear();
        emailController.clear();
        passwordController.clear();
      });
      fetchStudents();
    } else {
      print("Upload failed: ${response.statusCode}");
    }
  }

  Future<void> removeStudent(String regNo) async {
    final res = await http.delete(
      Uri.parse("http://localhost:5000/student/$regNo"),
    );
    if (res.statusCode == 200) {
      fetchStudents();
    }
  }

  @override
  Widget build(BuildContext context) {
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
                      final student = students[index];
                      return ListTile(
                        leading: const Icon(Icons.person, color: Colors.white),
                        title: Text(
                          student['name'] ?? 'Unknown',
                          style: GoogleFonts.poppins(color: Colors.white),
                        ),
                        onTap: () {
                          showDialog(
                            context: context,
                            builder:
                                (_) => AlertDialog(
                                  title: const Text("Remove Student"),
                                  content: Text(
                                    "Are you sure you want to remove ${student['name']}?",
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text("Cancel"),
                                    ),
                                    TextButton(
                                      onPressed: () async {
                                        Navigator.pop(context);
                                        await removeStudent(student['reg_no']);
                                      },
                                      child: const Text("Remove"),
                                    ),
                                  ],
                                ),
                          );
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
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 15,
                  ),
                  color: const Color(0xFF9B4DE0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const SizedBox(width: 10),
                          Text(
                            "Hi admin!",
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
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
                          _navItem("Attendance Manager", () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => const AttendanceManagerPage(),
                              ),
                            );
                          }),
                          _navItem("Manage Students", () {}),
                          const SizedBox(width: 12),
                          const Icon(Icons.person, color: Colors.white),
                        ],
                      ),
                    ],
                  ),
                ),

                // Center Content - Add Student Form
                Expanded(
                  child: Center(
                    child: Container(
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
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextField(
                            controller: nameController,
                            decoration: const InputDecoration(
                              labelText: 'Name',
                            ),
                            onChanged: (val) => name = val,
                          ),
                          TextField(
                            controller: regNoController,
                            decoration: const InputDecoration(
                              labelText: 'Reg No',
                            ),
                            onChanged: (val) => regNo = val,
                          ),
                          TextField(
                            controller: emailController,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                            ),
                            onChanged: (val) => email = val,
                          ),
                          TextField(
                            controller: passwordController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'Password',
                            ),
                            onChanged: (val) => password = val,
                          ),

                          const SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: pickImage,
                            child: Text(
                              faceImage == null
                                  ? 'Pick Face Image'
                                  : faceImage!.name,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF9B4DE0),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              textStyle: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5),
                              ),
                              minimumSize: const Size.fromHeight(50),
                            ),
                            onPressed: addStudent,
                            child: const Text(
                              'Add Student',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
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
