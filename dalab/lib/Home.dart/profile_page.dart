import 'dart:io';

import 'package:dalab/Home.dart/bonus_wallet_page.dart';
import 'package:dalab/auth/loginpage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

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
  // Support configuration (edit these variables to change your contact details)
  final String whatsappNumber = "+252622843233";
  final String supportEmail = "caaqilbeene@hotmail.com";

  final ImagePicker picker = ImagePicker();
  final TextEditingController nameController = TextEditingController();

  File? localProfileImage;
  File? backgroundImage;
  String? profileImageUrl;
  String? backgroundImageUrl;
  String profileName = ""; // Madhan - Supabase/Firebase ka soo gashan
  double backgroundY = 0;
  String selectedDistrict = ""; // Madhan ilaa qofku dooro
  String joinedDate = "";

  bool get isProfileComplete {
    final hasImage =
        localProfileImage != null ||
        (profileImageUrl != null && profileImageUrl!.isNotEmpty) ||
        widget.profileImage != null;
    final hasDistrict = selectedDistrict.isNotEmpty;
    return hasImage && hasDistrict;
  }

  @override
  void initState() {
    super.initState();
    loadProfileData();
  }

  Future<void> loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    final user = FirebaseAuth.instance.currentUser;
    final String? displayName = user?.displayName;
    setState(() {
      final rawName = prefs.getString('profile_name') ?? (displayName ?? "");
      if (rawName.contains('|')) {
        final parts = rawName.split('|');
        profileName = parts[0];
        selectedDistrict = parts[1];
        prefs.setString('selected_district', parts[1]);
      } else {
        profileName = rawName;
        selectedDistrict = prefs.getString('selected_district') ?? "";
      }

      final profPath = prefs.getString('profile_image_path');
      if (profPath != null && profPath.isNotEmpty) {
        if (profPath.startsWith('http') || profPath.startsWith('https')) {
          profileImageUrl = profPath;
          localProfileImage = null;
        } else {
          final file = File(profPath);
          if (file.existsSync()) {
            localProfileImage = file;
            profileImageUrl = null;
          }
        }
      }

      final bgPath = prefs.getString('background_image_path');
      if (bgPath != null && bgPath.isNotEmpty) {
        if (bgPath.startsWith('http') || bgPath.startsWith('https')) {
          backgroundImageUrl = bgPath;
          backgroundImage = null;
        } else {
          final file = File(bgPath);
          if (file.existsSync()) {
            backgroundImage = file;
            backgroundImageUrl = null;
          }
        }
      }

      backgroundY = prefs.getDouble('background_y') ?? 0.0;
      joinedDate = prefs.getString('joined_date') ?? "";
    });

    if (user != null) {
      // 1. Fetch current profile from Supabase to sync across devices/re-installs
      try {
        Map<String, dynamic>? data;
        try {
          data = await Supabase.instance.client
              .from('users')
              .select('name, avatar_url, background_url, created_at, district')
              .eq('id', user.uid)
              .maybeSingle();
        } catch (_) {
          data = await Supabase.instance.client
              .from('users')
              .select('name, avatar_url, background_url, created_at')
              .eq('id', user.uid)
              .maybeSingle();
        }

        if (data != null) {
          final String? dbName = data['name'];
          final String? dbAvatar = data['avatar_url'];
          final String? dbBg = data['background_url'];
          final String? dbCreatedAt = data['created_at'];
          final String? dbDistrict = data.containsKey('district')
              ? data['district']
              : null;

          setState(() {
            if (dbName != null && dbName.isNotEmpty) {
              profileName = dbName;
              prefs.setString('profile_name', dbName);
            }
            if (dbAvatar != null && dbAvatar.isNotEmpty) {
              if (localProfileImage == null ||
                  !localProfileImage!.existsSync()) {
                profileImageUrl = dbAvatar;
                localProfileImage = null;
                prefs.setString('profile_image_path', dbAvatar);
              }
            }
            if (dbBg != null && dbBg.isNotEmpty) {
              if (backgroundImage == null || !backgroundImage!.existsSync()) {
                backgroundImageUrl = dbBg;
                backgroundImage = null;
                prefs.setString('background_image_path', dbBg);
              }
            }
            if (dbCreatedAt != null) {
              try {
                final dt = DateTime.parse(dbCreatedAt).toLocal();
                final months = [
                  "Jan",
                  "Feb",
                  "Mar",
                  "Apr",
                  "May",
                  "Jun",
                  "Jul",
                  "Aug",
                  "Sep",
                  "Oct",
                  "Nov",
                  "Dec",
                ];
                joinedDate = "${dt.day} ${months[dt.month - 1]}, ${dt.year}";
                prefs.setString('joined_date', joinedDate);
              } catch (_) {}
            }
            if (dbDistrict != null && dbDistrict.isNotEmpty) {
              selectedDistrict = dbDistrict;
              prefs.setString('selected_district', dbDistrict);
            }
          });
        }
      } catch (e) {
        print("Error fetching user profile from Supabase: $e");
      }

      // 2. Ensure current record is updated/active in Supabase 'users' table
      try {
        // Hubi user-ku horay u jiray iyo in kale
        final existingUser = await Supabase.instance.client
            .from('users')
            .select('id')
            .eq('id', user.uid)
            .maybeSingle();

        if (existingUser == null) {
          // USER CUSUB — created_at = hadda
          final Map<String, dynamic> insertData = {
            'id': user.uid,
            'phone': user.phoneNumber,
            'created_at': DateTime.now().toUtc().toIso8601String(),
          };
          if (profileName.isNotEmpty) {
            insertData['name'] = profileName;
          }
          if (selectedDistrict.isNotEmpty) {
            insertData['district'] = selectedDistrict;
          }

          try {
            await Supabase.instance.client.from('users').insert(insertData);
          } catch (_) {
            if (insertData.containsKey('district')) {
              insertData.remove('district');
              await Supabase.instance.client.from('users').insert(insertData);
            }
          }
        } else {
          // USER JIRAY — kaliya name iyo phone update garee, created_at HA TAABAN
          final Map<String, dynamic> updateData = {'phone': user.phoneNumber};
          if (profileName.isNotEmpty) {
            updateData['name'] = profileName;
          }
          if (selectedDistrict.isNotEmpty) {
            updateData['district'] = selectedDistrict;
          }

          try {
            await Supabase.instance.client
                .from('users')
                .update(updateData)
                .eq('id', user.uid);
          } catch (_) {
            if (updateData.containsKey('district')) {
              updateData.remove('district');
              await Supabase.instance.client
                  .from('users')
                  .update(updateData)
                  .eq('id', user.uid);
            }
          }
        }
      } catch (e) {
        print("Error syncing current user to Supabase: $e");
      }
    }
    await checkAndShowVerifiedPopup(isFromUserAction: false);
  }

  String getTwitterHandle(String name) {
    return '@${name.replaceAll(' ', '').toLowerCase()}';
  }

  void showVerificationSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              const Icon(Icons.check_circle, color: Colors.blue, size: 80),
              const SizedBox(height: 24),
              const Text(
                "Koontadaada waa la xaqiijiyay!",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                "Verified",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                "Waad ku mahadsan tahay dhamaystirka profile-kaaga.",
                style: TextStyle(fontSize: 14, color: Colors.black54),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    "Cancel",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<void> checkAndShowVerifiedPopup({bool isFromUserAction = false}) async {
    if (!mounted) return;
    if (FirebaseAuth.instance.currentUser == null) return;
    
    if (isProfileComplete) {
      final prefs = await SharedPreferences.getInstance();
      final hasSeen = prefs.getBool('has_seen_verified_popup') ?? false;
      if (!hasSeen) {
        await prefs.setBool('has_seen_verified_popup', true);
        if (isFromUserAction) {
          if (mounted) {
            // Sug 300ms si bottom sheet-ka ama sawir-qaaduhu u xirmo si buuxda
            await Future.delayed(const Duration(milliseconds: 300));
            if (mounted) {
              showVerificationSuccessDialog();
            }
          }
        }
      }
    } else {
      // Haddii profile-ku uusan dhammaystirnayn, dib u reset garee flag-ga si uu mustaqbalka u soo bandhigo dialog-ga
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_seen_verified_popup', false);
    }
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
      await loadProfileData();
      await checkAndShowVerifiedPopup(isFromUserAction: true);
      return;
    }

    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    final directory = await getApplicationDocumentsDirectory();
    final permanentFile = await File(image.path).copy(
      '${directory.path}/profile_image_${DateTime.now().millisecondsSinceEpoch}.png',
    );

    setState(() {
      localProfileImage = permanentFile;
      profileImageUrl = null;
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_image_path', permanentFile.path);

    widget.onProfileImageChanged?.call(permanentFile);

    // Background upload to Supabase Storage
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final fileName =
            'avatar_${user.uid}_${DateTime.now().millisecondsSinceEpoch}.png';
        final storagePath = 'avatars/$fileName';

        await Supabase.instance.client.storage
            .from('avatars')
            .upload(storagePath, permanentFile);

        final publicUrl = Supabase.instance.client.storage
            .from('avatars')
            .getPublicUrl(storagePath);

        setState(() {
          profileImageUrl = publicUrl;
        });

        await Supabase.instance.client.from('users').upsert({
          'id': user.uid,
          'phone': user.phoneNumber,
          'name': profileName,
          'avatar_url': publicUrl,
        });
      } catch (e) {
        print("Supabase Storage profile upload error: $e");
      }
    }
    await checkAndShowVerifiedPopup(isFromUserAction: true);
  }

  Future<void> pickBackgroundImage() async {
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    final directory = await getApplicationDocumentsDirectory();
    final permanentFile = await File(image.path).copy(
      '${directory.path}/background_image_${DateTime.now().millisecondsSinceEpoch}.png',
    );

    setState(() {
      backgroundImage = permanentFile;
      backgroundImageUrl = null;
      backgroundY = 0;
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('background_image_path', permanentFile.path);
    await prefs.setDouble('background_y', 0.0);

    if (mounted) openBackgroundSlider();

    // Background upload to Supabase Storage
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final fileName =
            'bg_${user.uid}_${DateTime.now().millisecondsSinceEpoch}.png';
        final storagePath = 'backgrounds/$fileName';

        await Supabase.instance.client.storage
            .from('backgrounds')
            .upload(storagePath, permanentFile);

        final publicUrl = Supabase.instance.client.storage
            .from('backgrounds')
            .getPublicUrl(storagePath);

        setState(() {
          backgroundImageUrl = publicUrl;
        });

        await Supabase.instance.client.from('users').upsert({
          'id': user.uid,
          'phone': user.phoneNumber,
          'name': profileName,
          'background_url': publicUrl,
        });
      } catch (e) {
        print("Supabase Storage background upload error: $e");
      }
    }
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
                      image:
                          (backgroundImage == null ||
                              !backgroundImage!.existsSync())
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
                  onPressed: () async {
                    final rawName = nameController.text.trim();
                    if (rawName.isNotEmpty) {
                      final formattedName = rawName
                          .split(RegExp(r'\s+'))
                          .map((w) {
                            if (w.isEmpty) return '';
                            return w[0].toUpperCase() +
                                w.substring(1).toLowerCase();
                          })
                          .join(' ');

                      setState(() {
                        profileName = formattedName;
                      });

                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setString('profile_name', formattedName);

                      // Sync to Firebase and Supabase immediately
                      final user = FirebaseAuth.instance.currentUser;
                      if (user != null) {
                        try {
                          final combinedName = "$formattedName|$selectedDistrict";
                          await user.updateDisplayName(combinedName);
                          await user.reload();
                          await Supabase.instance.client.from('users').upsert({
                            'id': user.uid,
                            'phone': user.phoneNumber,
                            'name': formattedName,
                          });
                        } catch (e) {
                          print(
                            "Error syncing name update to Firebase/Supabase: $e",
                          );
                        }
                      }
                    }
                    if (mounted) Navigator.pop(context);
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

  Future<void> openSettingsBottomSheet() async {
    await showModalBottomSheet(
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
              "Dooro",
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
              "Kahda",
            ];

            final userPhone =
                FirebaseAuth.instance.currentUser?.phoneNumber ??
                "Not Registered";

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
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                      fontWeight: FontWeight.w600,
                    ),
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
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 24),

                  // District Selection Section
                  Text(
                    "Dooro Degmadaada Muqdisho (District)",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                      fontWeight: FontWeight.w600,
                    ),
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
                        value:
                            selectedDistrict.isNotEmpty &&
                                districts.contains(selectedDistrict)
                            ? selectedDistrict
                            : "Dooro",
                        isExpanded: true,
                        icon: Icon(
                          Icons.arrow_drop_down,
                          color: Colors.deepOrange,
                        ),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            final mappedValue = newValue == "Dooro"
                                ? ""
                                : newValue;
                            setState(() {
                              selectedDistrict = mappedValue;
                            });
                            sheetSetState(() {});
                            SharedPreferences.getInstance().then((prefs) {
                              prefs.setString('selected_district', mappedValue);
                            });
                            // Background sync to Supabase
                            final user = FirebaseAuth.instance.currentUser;
                            if (user != null) {
                              final combinedName = "$profileName|$mappedValue";
                              user.updateDisplayName(combinedName).then((_) async {
                                 await user.reload();
                               }).catchError((e) {
                                print("Firebase displayName update failed: $e");
                              });
                              Supabase.instance.client
                                  .from('users')
                                  .update({
                                    'phone': user.phoneNumber,
                                    'district': mappedValue,
                                  })
                                  .eq('id', user.uid)
                                  .catchError((e) {
                                    print(
                                      "District sync failed (might not exist in schema): $e",
                                    );
                                  });
                            }
                          }
                        },
                        items: districts.map<DropdownMenuItem<String>>((
                          String value,
                        ) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(
                              value,
                              style: TextStyle(
                                fontSize: 17,
                                color: Colors.black87,
                              ),
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
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
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
    await checkAndShowVerifiedPopup(isFromUserAction: true);
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
                        image:
                            backgroundImage != null &&
                                backgroundImage!.existsSync()
                            ? DecorationImage(
                                image: FileImage(backgroundImage!),
                                fit: BoxFit.cover,
                                alignment: Alignment(0, backgroundY),
                              )
                            : (backgroundImageUrl != null &&
                                      backgroundImageUrl!.isNotEmpty
                                  ? DecorationImage(
                                      image: NetworkImage(backgroundImageUrl!),
                                      fit: BoxFit.cover,
                                      alignment: Alignment(0, backgroundY),
                                    )
                                  : null),
                        gradient:
                            (backgroundImage == null ||
                                    !backgroundImage!.existsSync()) &&
                                (backgroundImageUrl == null ||
                                    backgroundImageUrl!.isEmpty)
                            ? const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Color(0xFFFFF1E9), Color(0xFFEFF7FF)],
                              )
                            : null,
                      ),
                      child:
                          (backgroundImage == null ||
                                  !backgroundImage!.existsSync()) &&
                              (backgroundImageUrl == null ||
                                  backgroundImageUrl!.isEmpty)
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 32,
                                  height: 64,
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 3,
                                  ),
                                  color: Colors.blueGrey.shade200,
                                ),
                                Container(
                                  width: 44,
                                  height: 92,
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 3,
                                  ),
                                  color: Colors.blueGrey.shade200,
                                ),
                                Container(
                                  width: 28,
                                  height: 70,
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 3,
                                  ),
                                  color: Colors.blueGrey.shade200,
                                ),
                                Container(
                                  width: 54,
                                  height: 125,
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 3,
                                  ),
                                  color: Colors.blueGrey.shade200,
                                ),
                                Container(
                                  width: 36,
                                  height: 86,
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 3,
                                  ),
                                  color: Colors.blueGrey.shade200,
                                ),
                                Container(
                                  width: 46,
                                  height: 104,
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 3,
                                  ),
                                  color: Colors.blueGrey.shade200,
                                ),
                                Container(
                                  width: 30,
                                  height: 76,
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 3,
                                  ),
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
                      child: const CircleAvatar(
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
                      child: const CircleAvatar(
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
                                child:
                                    localProfileImage != null &&
                                        localProfileImage!.existsSync()
                                    ? Image.file(
                                        localProfileImage!,
                                        fit: BoxFit.cover,
                                        alignment: Alignment.center,
                                      )
                                    : (widget.profileImage != null &&
                                              widget.profileImage!.existsSync()
                                          ? Image.file(
                                              widget.profileImage!,
                                              fit: BoxFit.cover,
                                              alignment: Alignment.center,
                                            )
                                          : (profileImageUrl != null &&
                                                    profileImageUrl!.isNotEmpty
                                                ? Image.network(
                                                    profileImageUrl!,
                                                    fit: BoxFit.cover,
                                                    alignment: Alignment.center,
                                                    errorBuilder: (c, e, s) =>
                                                        const Icon(
                                                          Icons.person,
                                                          size: 56,
                                                          color:
                                                              Colors.deepOrange,
                                                        ),
                                                  )
                                                : const Icon(
                                                    Icons.person,
                                                    size: 56,
                                                    color: Colors.deepOrange,
                                                  ))),
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
                          profileName.isNotEmpty ? profileName : "User",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      SizedBox(width: 6),
                      // VERIFIED ICON START
                      // Only show if user is authenticated via Firebase and has completed their profile
                      if (FirebaseAuth.instance.currentUser != null &&
                          isProfileComplete)
                        const Padding(
                          padding: EdgeInsets.only(left: 4),
                          child: Icon(
                            Icons.check_circle,
                            color: Colors.blue,
                            size: 16,
                          ),
                        ),
                      // VERIFIED ICON END
                    ],
                  ),
                  SizedBox(height: 12),
                  // JOINED DATE ROW START
                  if (joinedDate.isNotEmpty)
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
                  // Hadda waxay u muuqataa oo keliya hadduu qofku degmo doorto
                  GestureDetector(
                    onTap:
                        openSettingsBottomSheet, // Taabo si aad degmo u dooratid
                    child: Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          color: selectedDistrict.isEmpty
                              ? Colors.deepOrange
                              : Colors.black54,
                        ),
                        SizedBox(width: 12),
                        Text(
                          selectedDistrict.isEmpty
                              ? "Dooro degmadaada →" // Placeholder marka la'aan
                              : "$selectedDistrict, Mogadishu",
                          style: TextStyle(
                            fontSize: 17,
                            color: selectedDistrict.isEmpty
                                ? Colors.deepOrange
                                : Colors.black54,
                            fontWeight: selectedDistrict.isEmpty
                                ? FontWeight.w500
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // LOCATION MAP ROW END

                  // PROFILE COMPLETION CARD START
                  if (!isProfileComplete) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB), // Soft premium amber
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFFEF3C7),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                color: Colors.amber.shade800,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "Dhamaystir Profile-kaaga",
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.amber.shade900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Si aad u hesho calaamada verified-ka (blue badge), fadlan buuxi shuruudaha soo socda:",
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.amber.shade900,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Divider(color: Color(0xFFFEF3C7), height: 1),
                          const SizedBox(height: 12),
                          _buildChecklistItem(
                            title:
                                "Saar sawirkaaga profile-ka (Profile Picture)",
                            isDone:
                                localProfileImage != null ||
                                (profileImageUrl != null &&
                                    profileImageUrl!.isNotEmpty),
                          ),
                          const SizedBox(height: 8),
                          _buildChecklistItem(
                            title: "Dooro degmadaada (Select District)",
                            isDone: selectedDistrict.isNotEmpty,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  // PROFILE COMPLETION CARD END
                  if (isProfileComplete) const SizedBox(height: 10),

                  // BONUS WALLET ROW START
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const BonusWalletPage(),
                        ),
                      );
                    },
                    child: Row(
                      children: [
                        const Icon(Icons.wallet, color: Colors.black54),
                        const SizedBox(width: 12),
                        const Text(
                          "Bonus Wallet",
                          style: TextStyle(fontSize: 17, color: Colors.black54),
                        ),
                        const Spacer(),
                        Icon(Icons.chevron_right, color: Colors.grey.shade400),
                      ],
                    ),
                  ),
                  // BONUS WALLET ROW END
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
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: _showSupportBottomSheet,
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.headphones,
                                  color: Colors.deepPurple,
                                ),
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
                        // Tirtir xogda user-ka hore si user cusub uu u helo slate nadiif ah
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.remove('profile_name');
                        await prefs.remove('profile_image_path');
                        await prefs.remove('background_image_path');
                        await prefs.remove('background_y');
                        await prefs.remove('selected_district');
                        await prefs.remove('joined_date');
                        await prefs.remove('bonus_balance');
                        await prefs.remove('linked_card_number');
                        await prefs.remove('restaurant_logo_path');
                        await prefs.remove('has_seen_verified_popup');

                        await FirebaseAuth.instance.signOut();
                        if (context.mounted) {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LoginPage(),
                            ),
                            (route) => false,
                          );
                        }
                      },
                      icon: Icon(Icons.logout),
                      label: Text("Log Out"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.red,
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

  void _showSupportBottomSheet() {
    final emailController = TextEditingController(
      text: FirebaseAuth.instance.currentUser?.email ?? "",
    );
    final messageController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            top: 24,
            left: 24,
            right: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Qeybta Caawinaada",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // WhatsApp option card
                  InkWell(
                    onTap: () async {
                      final cleanPhone = whatsappNumber.replaceAll(
                        RegExp(r'[^\d+]'),
                        '',
                      );
                      final whatsappUrl = Uri.parse(
                        "https://wa.me/$cleanPhone",
                      );
                      if (await canLaunchUrl(whatsappUrl)) {
                        await launchUrl(
                          whatsappUrl,
                          mode: LaunchMode.externalApplication,
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Lama furi karo WhatsApp-ka hadda."),
                          ),
                        );
                      }
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.message,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Support-ka WhatsApp",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.green,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Si toos ah noogula soo xiriir $whatsappNumber",
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.green.shade800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Colors.green.shade700,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey.shade300)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          "Ama noogu soo dir Email",
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: Colors.grey.shade300)),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Email input
                  TextFormField(
                    controller: emailController,
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: InputDecoration(
                      labelText: "Emailkaaga",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.email_outlined),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return "Fadlan geli emailkaaga";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Message input
                  TextFormField(
                    controller: messageController,
                    autocorrect: false,
                    enableSuggestions: false,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: "Fariintaada",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignLabelWithHint: true,
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return "Fadlan qor fariintaada caawinaada";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Send button
                  ElevatedButton(
                    onPressed: () async {
                      if (formKey.currentState!.validate()) {
                        final enteredEmail = emailController.text.trim();
                        final enteredMessage = messageController.text.trim();

                        final String subject = Uri.encodeComponent(
                          "Deeli App Support Request",
                        );
                        final String body = Uri.encodeComponent(
                          "Customer Email: $enteredEmail\n\nMessage:\n$enteredMessage",
                        );
                        final Uri emailUri = Uri.parse(
                          "mailto:$supportEmail?subject=$subject&body=$body",
                        );

                        // Close bottom sheet immediately & synchronously
                        Navigator.pop(context);

                        // Show success snackbar
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          const SnackBar(
                            content: Text("Farriintaada waa la diray!"),
                            backgroundColor: Colors.green,
                            duration: Duration(seconds: 3),
                          ),
                        );

                        // Save support request in the background
                        Supabase.instance.client
                            .from('support_messages')
                            .insert({
                              'email': enteredEmail,
                              'message': enteredMessage,
                              'created_at': DateTime.now().toIso8601String(),
                            })
                            .then((_) {})
                            .catchError((_) {});

                        // Launch email client
                        try {
                          await launchUrl(
                            emailUri,
                            mode: LaunchMode.externalApplication,
                          );
                        } catch (_) {
                          try {
                            await launchUrl(emailUri);
                          } catch (_) {
                            // Quiet fallback, message is already saved in database
                          }
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "Dir Fariinta Caawinaada",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildChecklistItem({required String title, required bool isDone}) {
    return Row(
      children: [
        Icon(
          isDone ? Icons.check_circle : Icons.radio_button_unchecked,
          color: isDone ? Colors.green.shade600 : Colors.amber.shade700,
          size: 16,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              color: isDone ? Colors.green.shade800 : Colors.amber.shade900,
              fontWeight: isDone ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }
}
