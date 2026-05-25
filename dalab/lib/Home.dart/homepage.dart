import 'dart:io';
import 'package:dalab/Home.dart/Juicepage.dart';
import 'package:dalab/Home.dart/frieslist.dart';
import 'package:dalab/Home.dart/meals.dart';
import 'package:dalab/Home.dart/mealsburger.dart';
import 'package:dalab/Home.dart/profile_page.dart';
import 'package:dalab/Home.dart/search_page.dart';
import 'package:dalab/Home.dart/my_orders_page.dart';
import 'package:dalab/Home.dart/item_details_page.dart';
import 'package:dalab/models/menu_item.dart';
import 'package:dalab/Home.dart/widgets/menu_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  int currentIndex = 0;
  File? profileImage;
  String? profileImageUrl;
  String userName = "Macmiil";
  final ImagePicker picker = ImagePicker();
  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  Future<void> loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString('profile_name') ?? "Macmiil";
    });

    final profPath = prefs.getString('profile_image_path');
    if (profPath != null && profPath.isNotEmpty) {
      if (profPath.startsWith('http') || profPath.startsWith('https')) {
        setState(() {
          profileImageUrl = profPath;
          profileImage = null;
        });
      } else {
        final file = File(profPath);
        if (file.existsSync()) {
          setState(() {
            profileImage = file;
            profileImageUrl = null;
          });
        }
      }
    }

    // Background sync from Supabase
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final data = await _supabase
            .from('users')
            .select('name, avatar_url')
            .eq('id', user.uid)
            .maybeSingle();

        if (data != null) {
          final String? dbName = data['name'];
          final String? dbAvatar = data['avatar_url'];

          setState(() {
            if (dbName != null && dbName.isNotEmpty) {
              userName = dbName;
            }
            if (dbAvatar != null && dbAvatar.isNotEmpty) {
              if (profileImage == null || !profileImage!.existsSync()) {
                profileImageUrl = dbAvatar;
                profileImage = null;
              }
            }
          });

          if (dbName != null && dbName.isNotEmpty) {
            await prefs.setString('profile_name', dbName);
          }
          if (dbAvatar != null && dbAvatar.isNotEmpty) {
            if (profileImage == null || !profileImage!.existsSync()) {
              await prefs.setString('profile_image_path', dbAvatar);
            }
          }
        }
      } catch (e) {
        print("Error loading user data from Supabase: $e");
      }
    }
  }

  void ontaped(int index) {
    // PROFILE SCREEN NAVIGATION START
    // When Profile is tapped, open ProfilePage as a new screen.
    // This hides the dashboard AppBar from the profile screen.
    if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProfilePage(
            profileImage: profileImage,
            onProfileImageChanged: (image) {
              setState(() {
                profileImage = image;
                profileImageUrl = null;
              });
            },
          ),
        ),
      ).then((_) {
        loadUserData();
      });
      return;
    }
    // PROFILE SCREEN NAVIGATION END

    setState(() {
      currentIndex = index;
    });
  }

  Future<void> pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final directory = await getApplicationDocumentsDirectory();
      final permanentFile = await File(pickedFile.path).copy(
        '${directory.path}/profile_image_${DateTime.now().millisecondsSinceEpoch}.png',
      );

      setState(() {
        profileImage = permanentFile;
        profileImageUrl = null;
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profile_image_path', permanentFile.path);

      // Background upload to Supabase Storage
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          final fileName = 'avatar_${user.uid}_${DateTime.now().millisecondsSinceEpoch}.png';
          final storagePath = 'avatars/$fileName';
          
          await Supabase.instance.client.storage
              .from('avatars')
              .upload(storagePath, permanentFile);

          final publicUrl = Supabase.instance.client.storage
              .from('avatars')
              .getPublicUrl(storagePath);

          await prefs.setString('profile_image_path', publicUrl);
          setState(() {
            profileImageUrl = publicUrl;
            profileImage = null;
          });

          await _supabase.from('users').upsert({
            'id': user.uid,
            'phone': user.phoneNumber,
            'avatar_url': publicUrl,
          });
        } catch (e) {
          print("Supabase Storage profile upload error from Homepage: $e");
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: currentIndex != 0 ? null : AppBar(
        backgroundColor: Colors.white,
        titleSpacing: 0,
        elevation: 0,
        toolbarHeight: 55,
        title: Padding(
          padding: const EdgeInsets.only(left: 20, right: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Delivery to",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 5),
              Row(
                children: [
                  Icon(Icons.location_on, size: 20, color: Colors.black),
                  SizedBox(width: 4),
                  Text(
                    "My Home, Mogadishu",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  Icon(Icons.keyboard_arrow_down, size: 25),
                  Spacer(),
                  Icon(CupertinoIcons.bell),
                ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.black54,
        onTap: ontaped,
        currentIndex: currentIndex,
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.home),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.doc_text),
            label: "My order",
          ),
          BottomNavigationBarItem(
            icon: profileImage != null && profileImage!.existsSync()
                ? CircleAvatar(
                    backgroundImage: FileImage(profileImage!),
                    radius: 16,
                  )
                : (profileImageUrl != null && profileImageUrl!.isNotEmpty
                    ? CircleAvatar(
                        backgroundImage: NetworkImage(profileImageUrl!),
                        radius: 16,
                      )
                    : const Icon(CupertinoIcons.person)),
            activeIcon: profileImage != null && profileImage!.existsSync()
                ? CircleAvatar(
                    backgroundImage: FileImage(profileImage!),
                    radius: 16,
                  )
                : (profileImageUrl != null && profileImageUrl!.isNotEmpty
                    ? CircleAvatar(
                        backgroundImage: NetworkImage(profileImageUrl!),
                        radius: 16,
                      )
                    : const Icon(CupertinoIcons.person)),
            label: "Profile",
          ),
        ],
      ),
      body: currentIndex == 2
          ? ProfilePage(
              profileImage: profileImage,
              onPickProfileImage: pickImage,
            )
          : currentIndex == 1
          ? const MyOrdersPage()
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 13,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset("images/burger-banner-no-fire.png"),
                    ),
                    SizedBox(height: 15),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SearchPage(),
                                ),
                              );
                            },
                            child: Container(
                              margin: EdgeInsets.only(left: 20, right: 10),
                              padding: EdgeInsets.symmetric(horizontal: 10),
                              height: 50,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.black),
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.search,
                                    color: Colors.grey.shade600,
                                  ),
                                  SizedBox(width: 10),
                                  Text(
                                    "Search food, drink, etc...",
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            CupertinoIcons.line_horizontal_3_decrease,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Column(
                          children: [
                            GestureDetector(
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => Meals(),
                                  ),
                                );
                              },
                              child: Container(
                                padding: EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(60),
                                ),
                                child: Image.asset(
                                  "images/burger.png",
                                  height: 30,
                                  width: 30,
                                ),
                              ),
                            ),
                            SizedBox(height: 10),
                            Text(
                              "Burger",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),

                        Column(
                          children: [
                            GestureDetector(
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => Mealsburger(),
                                  ),
                                );
                              },
                              child: Container(
                                padding: EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(60),
                                ),
                                child: Image.asset(
                                  "images/shawarma.png",
                                  height: 30,
                                  width: 30,
                                ),
                              ),
                            ),
                            SizedBox(height: 10),
                            Text(
                              "Shawarma",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            GestureDetector(
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => Frieslist(),
                                  ),
                                );
                              },
                              child: Container(
                                padding: EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(60),
                                ),
                                child: Image.asset(
                                  "images/french-fries.png",
                                  height: 30,
                                  width: 30,
                                ),
                              ),
                            ),
                            SizedBox(height: 10),
                            Text(
                              "Fries",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),

                        Column(
                          children: [
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => Juicepage(),
                                  ),
                                );
                              },
                              child: Container(
                                padding: EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(60),
                                ),
                                child: Image.asset(
                                  "images/juice.png",
                                  height: 30,
                                  width: 30,
                                ),
                              ),
                            ),
                            SizedBox(height: 10),
                            Text(
                              "Shakes",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 15),
                    Padding(
                      padding: const EdgeInsets.only(left: 20),
                      child: Text(
                        "Recent Deals",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    SizedBox(
                      height: 300,
                      // width: MediaQuery.of(context).size.width,
                      child: StreamBuilder<List<Map<String, dynamic>>>(
                        stream: _supabase
                            .from('menu_items')
                            .stream(primaryKey: ['id'])
                            .eq('category', 'Deals'),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                                  ConnectionState.waiting &&
                              !snapshot.hasData) {
                            return const Center(
                              child: CircularProgressIndicator(
                                color: Colors.deepOrange,
                              ),
                            );
                          }

                           if (snapshot.hasError) {
                             return const Center(
                               child: Padding(
                                 padding: EdgeInsets.symmetric(vertical: 20),
                                 child: Text(
                                   "Lama xiriiri karo server-ka hadda. Hubi internet-kaaga.",
                                   style: TextStyle(color: Colors.grey, fontSize: 13),
                                   textAlign: TextAlign.center,
                                 ),
                               ),
                             );
                           }

                          final data = snapshot.data ?? [];
                          if (data.isEmpty) {
                            return const Center(
                              child: Text("No deals available"),
                            );
                          }

                          final deals = data.map((map) {
                            final item = MenuItem.fromMap(map);
                            item.updateQuantityFromCart();
                            return item;
                          }).toList();

                          return ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: deals.length,
                            itemBuilder: (context, index) {
                              final item = deals[index];
                              return Padding(
                                padding: const EdgeInsets.only(right: 15),
                                child: Column(
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                ItemDetailsPage(item: item),
                                          ),
                                        );
                                      },
                                      child: Container(
                                        margin: const EdgeInsets.only(left: 10),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade300,
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          child: MenuImage(
                                            imagePath: item.imagePath,
                                            height: 200,
                                            width: 280,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    SizedBox(
                                      width: 280,
                                      child: Text(
                                        item.name,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
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
            ),
    );
  }
}
