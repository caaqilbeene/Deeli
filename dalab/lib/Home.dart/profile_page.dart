import 'dart:io';

import 'package:dalab/auth/loginpage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfilePage extends StatefulWidget {
  final File? profileImage;
  final Future<void> Function()? onPickProfileImage;
  final ValueChanged<File>? onProfileImageChanged;

  const ProfilePage({
    super.key,
    this.profileImage,
    this.onPickProfileImage,
    this.onProfileImageChanged,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final ImagePicker picker = ImagePicker();
  final TextEditingController nameController = TextEditingController();

  File? localProfileImage;
  File? backgroundImage;
  String profileName = "Mohamed Ali";
  double backgroundY = 0;
  String selectedDistrict = "Hodan";
  String joinedDate = "22 Apr, 2026";

  File? get currentProfileImage => widget.profileImage ?? localProfileImage;

  @override
  void initState() {
    super.initState();
    loadProfileData();
  }

  Future<void> loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      profileName = prefs.getString('profile_name') ?? "Mohamed Ali";
      
      final profPath = prefs.getString('profile_image_path');
      if (profPath != null && profPath.isNotEmpty) {
        localProfileImage = File(profPath);
      }
      
      final bgPath = prefs.getString('background_image_path');
      if (bgPath != null && bgPath.isNotEmpty) {
        backgroundImage = File(bgPath);
      }
      
      backgroundY = prefs.getDouble('background_y') ?? 0.0;
      selectedDistrict = prefs.getString('selected_district') ?? "Hodan";
      joinedDate = prefs.getString('joined_date') ?? "22 Apr, 2026";
    });

    // Auto-sync current logged in user to Supabase 'users' table (iga bilaaw logic)
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await Supabase.instance.client.from('users').upsert({
          'id': user.uid,
          'phone': user.phoneNumber,
          'name': profileName,
          'created_at': '2026-04-22T12:00:00Z', // Set to 22 April 2026 as requested!
        });
      } catch (e) {
        print("Error syncing current user to Supabase: $e");
      }
    }
  }

  String getTwitterHandle(String name) {
    return '@' + name.replaceAll(' ', '').toLowerCase();
  }



  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  Future<void> pickProfileImage() async {
    if (widget.onPickProfileImage != null &&
        widget.onProfileImageChanged == null) {
      await widget.onPickProfileImage!();
      return;
    }

    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    setState(() {
      localProfileImage = File(image.path);
    });
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_image_path', image.path);

    widget.onProfileImageChanged?.call(File(image.path));
  }

  Future<void> pickBackgroundImage() async {
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    setState(() {
      backgroundImage = File(image.path);
      backgroundY = 0;
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('background_image_path', image.path);
    await prefs.setDouble('background_y', 0.0);

    if (mounted) openBackgroundSlider();
  }

  void openBackgroundSlider() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, sheetSetState) {
            return Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Move background image",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),
                  Container(
                    height: 130,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                      image: (backgroundImage == null || !backgroundImage!.existsSync())
                          ? null
                          : DecorationImage(
                              image: FileImage(backgroundImage!),
                              fit: BoxFit.cover,
                              alignment: Alignment(0, backgroundY),
                            ),
                    ),
                  ),
                  // BACKGROUND IMAGE SLIDER START
                  // Change min and max if you want the image to move more or less.
                  Slider(
                    min: -3,
                    max: 3,
                    value: backgroundY,
                    activeColor: Colors.deepOrange,
                    onChanged: (value) {
                      setState(() {
                        backgroundY = value;
                      });
                      sheetSetState(() {});
                      SharedPreferences.getInstance().then((prefs) {
                        prefs.setDouble('background_y', value);
                      });
                    },
                  ),
                  // BACKGROUND IMAGE SLIDER END
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepOrange,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text("Done"),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void openEditProfile() {
    nameController.text = profileName;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Edit Profile",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 24),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: "Name",
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    final newName = nameController.text.trim();
                    if (newName.isNotEmpty) {
                      setState(() {
                        profileName = newName;
                      });
                      SharedPreferences.getInstance().then((prefs) {
                        prefs.setString('profile_name', newName);
                      });
                    }
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    "Save",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void openSettingsBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, sheetSetState) {
            final districts = [
              "Hodan",
              "Waaberi",
              "Howlwadaag",
              "Hamar Weyne",
              "Hamar Jajab",
              "Wadajir",
              "Dharkenley",
              "Daynile",
              "Yaqshid",
              "Shibis",
              "Abdiaziz",
              "Kaaraan",
              "Shangani",
              "Boondheere",
              "Heliwaa",
              "Kahda"
            ];
            
            final userPhone = FirebaseAuth.instance.currentUser?.phoneNumber ?? "Not Registered";

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    "Settings",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 24),
                  
                  // Phone Number Display Section
                  Text(
                    "Taleefankaaga (Phone Number)",
                    style: TextStyle(fontSize: 14, color: Colors.black54, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.phone, color: Colors.deepOrange, size: 20),
                        SizedBox(width: 12),
                        Text(
                          userPhone,
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 24),
                  
                  // District Selection Section
                  Text(
                    "Dooro Degmadaada Muqdisho (District)",
                    style: TextStyle(fontSize: 14, color: Colors.black54, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: districts.contains(selectedDistrict) ? selectedDistrict : districts.first,
                        isExpanded: true,
                        icon: Icon(Icons.arrow_drop_down, color: Colors.deepOrange),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              selectedDistrict = newValue;
                            });
                            sheetSetState(() {});
                            SharedPreferences.getInstance().then((prefs) {
                              prefs.setString('selected_district', newValue);
                            });
                          }
                        },
                        items: districts.map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(
                              value,
                              style: TextStyle(fontSize: 17, color: Colors.black87),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepOrange,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        "Done",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 260,
              child: Stack(
                children: [
                  GestureDetector(
                    onTap: pickBackgroundImage,
                    child: Container(
                      height: 190,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        image: (backgroundImage == null || !backgroundImage!.existsSync())
                            ? null
                            : DecorationImage(
                                image: FileImage(backgroundImage!),
                                fit: BoxFit.cover,
                                alignment: Alignment(0, backgroundY),
                              ),
                        gradient: (backgroundImage == null || !backgroundImage!.existsSync())
                            ? LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Color(0xFFFFF1E9), Color(0xFFEFF7FF)],
                              )
                            : null,
                      ),
                      child: (backgroundImage == null || !backgroundImage!.existsSync())
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 32,
                                  height: 64,
                                  margin: EdgeInsets.symmetric(horizontal: 3),
                                  color: Colors.blueGrey.shade200,
                                ),
                                Container(
                                  width: 44,
                                  height: 92,
                                  margin: EdgeInsets.symmetric(horizontal: 3),
                                  color: Colors.blueGrey.shade200,
                                ),
                                Container(
                                  width: 28,
                                  height: 70,
                                  margin: EdgeInsets.symmetric(horizontal: 3),
                                  color: Colors.blueGrey.shade200,
                                ),
                                Container(
                                  width: 54,
                                  height: 125,
                                  margin: EdgeInsets.symmetric(horizontal: 3),
                                  color: Colors.blueGrey.shade200,
                                ),
                                Container(
                                  width: 36,
                                  height: 86,
                                  margin: EdgeInsets.symmetric(horizontal: 3),
                                  color: Colors.blueGrey.shade200,
                                ),
                                Container(
                                  width: 46,
                                  height: 104,
                                  margin: EdgeInsets.symmetric(horizontal: 3),
                                  color: Colors.blueGrey.shade200,
                                ),
                                Container(
                                  width: 30,
                                  height: 76,
                                  margin: EdgeInsets.symmetric(horizontal: 3),
                                  color: Colors.blueGrey.shade200,
                                ),
                              ],
                            )
                          : null,
                    ),
                  ),
                  Positioned(
                    right: 18,
                    top: 48,
                    child: GestureDetector(
                      onTap: pickBackgroundImage,
                      child: CircleAvatar(
                        radius: 22,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.camera_alt, color: Colors.black),
                      ),
                    ),
                  ),
                  // BACK TO DASHBOARD ARROW START
                  // This arrow closes ProfilePage and returns to dashboard.
                  Positioned(
                    left: 18,
                    top: 48,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: CircleAvatar(
                        radius: 22,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.arrow_back, color: Colors.black),
                      ),
                    ),
                  ),
                  // BACK TO DASHBOARD ARROW END
                  // PROFILE AVATAR TAP AREA START
                  // This whole avatar opens gallery when you tap it.
                  Positioned(
                    left: 24,
                    top: 128,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: pickProfileImage,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          CircleAvatar(
                            radius: 62,
                            backgroundColor: Colors.white,
                            child: ClipOval(
                              child: Container(
                                width: 110,
                                height: 110,
                                color: Colors.deepOrange.shade50,
                                child: (currentProfileImage == null || !currentProfileImage!.existsSync())
                                    ? Icon(
                                        Icons.person,
                                        size: 56,
                                        color: Colors.deepOrange,
                                      )
                                    : Image.file(
                                        currentProfileImage!,
                                        fit: BoxFit.cover,
                                        alignment: Alignment.center,
                                      ),
                              ),
                            ),
                          ),
                          Positioned(
                            right: 4,
                            bottom: 5,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: pickProfileImage,
                              child: CircleAvatar(
                                radius: 20,
                                backgroundColor: Colors.deepOrange,
                                // PROFILE IMAGE CAMERA ICON START
                                // This camera icon opens the gallery for profile image.
                                child: Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                // PROFILE IMAGE CAMERA ICON END
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // PROFILE AVATAR TAP AREA END
                  // EDIT PROFILE BUTTON TAP AREA START
                  // This button opens the edit profile bottom sheet.
                  Positioned(
                    right: 22,
                    top: 202,
                    child: OutlinedButton.icon(
                      onPressed: openEditProfile,
                      icon: Icon(Icons.edit, size: 18),
                      label: Text("Edit Profile"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black87,
                        side: BorderSide(color: Colors.black12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  // EDIT PROFILE BUTTON TAP AREA END
                ],
              ),
            ),
            SizedBox(height: 20),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          profileName,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      SizedBox(width: 6),
                       // VERIFIED ICON START
                      // Only show if user is authenticated via Firebase
                      if (FirebaseAuth.instance.currentUser != null)
                        Icon(Icons.check_circle, color: Colors.blue, size: 16),
                      // VERIFIED ICON END
                    ],
                  ),
                  SizedBox(height: 12),
                  // JOINED DATE ROW START
                  Row(
                    children: [
                      Icon(Icons.calendar_month, color: Colors.black54),
                      SizedBox(width: 12),
                      Text(
                        "Joined $joinedDate",
                        style: TextStyle(fontSize: 17, color: Colors.black54),
                      ),
                    ],
                  ),
                  // JOINED DATE ROW END
                  SizedBox(height: 10),
                  // LOCATION MAP ROW START
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, color: Colors.black54),
                      SizedBox(width: 12),
                      Text(
                        "$selectedDistrict, Mogadishu",
                        style: TextStyle(fontSize: 17, color: Colors.black54),
                      ),
                    ],
                  ),
                  // LOCATION MAP ROW END
                  SizedBox(height: 36),
                  Text(
                    "General",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Icon(Icons.lock, color: Colors.green),
                              SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  "Password",
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Icon(Icons.chevron_right),
                            ],
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Icon(
                                Icons.notifications_none,
                                color: Colors.pink,
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  "Notifications",
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Icon(Icons.chevron_right),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // SizedBox(height: 28),
                  // Text(
                  //   "Others",
                  //   style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  // ),
                  SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Icon(Icons.headphones, color: Colors.deepPurple),
                              SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  "Support",
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Icon(Icons.chevron_right),
                            ],
                          ),
                        ),
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: openSettingsBottomSheet,
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Icon(Icons.settings, color: Colors.grey),
                                SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    "Settings",
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Icon(Icons.chevron_right),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await FirebaseAuth.instance.signOut();
                        if (context.mounted) {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (context) => LoginPage()),
                            (route) => false,
                          );
                        }
                      },
                      icon: Icon(Icons.logout),
                      label: Text("Log Out"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        backgroundColor: Colors.red.shade50,
                        side: BorderSide(color: Colors.red.shade100),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
