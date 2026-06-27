import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dog_friendly_map/utils/translations.dart';
import 'package:dog_friendly_map/main.dart';
import 'package:dog_friendly_map/services/settings_service.dart';

class Pet {
  String name;
  String? imagePath;
  Pet({required this.name, this.imagePath});

  Map<String, dynamic> toJson() => {
    'name': name,
    'imagePath': imagePath,
  };

  factory Pet.fromJson(Map<String, dynamic> json) => Pet(
    name: json['name'],
    imagePath: json['imagePath'],
  );
}

class ProfileScreen extends StatefulWidget {
  final VoidCallback onBackToMap;
  final String currentLang;

  const ProfileScreen({
    super.key,
    required this.onBackToMap,
    required this.currentLang,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ImagePicker _picker = ImagePicker();
  final List<Pet> _myPets = [];
  String _userName = '';
  String _userNickname = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? petsJson = prefs.getString('saved_pets');

    setState(() {
      _userName = prefs.getString('user_name') ?? 'Имя не указано';
      _userNickname = prefs.getString('user_nickname') ?? '@nickname';

      if (petsJson != null) {
        final List<dynamic> decodedList = jsonDecode(petsJson);
        _myPets.clear();
        _myPets.addAll(decodedList.map((e) => Pet.fromJson(e)).toList());
      }
    });
  }

  Future<void> _savePets() async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedData = jsonEncode(_myPets.map((p) => p.toJson()).toList());
    await prefs.setString('saved_pets', encodedData);
  }

  void _deletePet(int index) {
    setState(() {
      _myPets.removeAt(index);
    });
    _savePets();
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_registered', false);
    await prefs.remove('user_name');
    await prefs.remove('user_nickname');

    if (!mounted) return;

    final settingsService = SettingsService(prefs);

    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => MyApp(
          settingsService: settingsService,
          isRegistered: false,
        ),
      ),
          (Route<dynamic> route) => false,
    );
  }

  Future<void> _addNewPet() async {
    final t = AppTranslations.data[widget.currentLang]!;
    String petName = "";
    XFile? selectedImage;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(t['new_pet_title']!, textAlign: TextAlign.center),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () async {
                      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
                      if (image != null) {
                        setStateDialog(() {
                          selectedImage = image;
                        });
                      }
                    },
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: selectedImage != null ? FileImage(File(selectedImage!.path)) : null,
                      child: selectedImage == null
                          ? const Icon(Icons.add_a_photo, size: 40, color: Colors.grey)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    autofocus: true,
                    style: const TextStyle(color: Colors.black, fontSize: 16),
                    decoration: InputDecoration(
                      hintText: t['pet_name_hint'],
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                    onChanged: (value) => petName = value.trim(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(t['cancel']!, style: const TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text(t['save']!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );

    if (petName.isNotEmpty || selectedImage != null) {
      setState(() {
        _myPets.add(Pet(
          name: petName.isEmpty ? t['no_name']! : petName,
          imagePath: selectedImage?.path,
        ));
      });
      _savePets();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTranslations.data[widget.currentLang]!;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: widget.onBackToMap,
        ),
        title: Text(t['my_profile']!, style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app, color: Colors.red),
            onPressed: _logout,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.green,
                  child: Icon(Icons.person, size: 40, color: Colors.white),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_userName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    Text(_userNickname, style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                ActionChip(label: const Text('Instagram'), avatar: const Icon(Icons.camera_alt, size: 16), onPressed: () {}),
                const SizedBox(width: 10),
                ActionChip(label: const Text('Telegram'), avatar: const Icon(Icons.send, size: 16), onPressed: () {}),
              ],
            ),
            const Divider(height: 40, thickness: 1),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(t['my_pets']!, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.green, size: 32),
                  onPressed: _addNewPet,
                ),
              ],
            ),
            const SizedBox(height: 16),

            SizedBox(
              height: 130,
              child: _myPets.isEmpty
                  ? Center(child: Text(t['add_first_pet']!, style: TextStyle(color: Colors.grey[500], fontSize: 15)))
                  : ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _myPets.length,
                itemBuilder: (context, index) {
                  final pet = _myPets[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 20.0),
                    child: Column(
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            CircleAvatar(
                              radius: 42,
                              backgroundColor: Colors.grey[300],
                              backgroundImage: pet.imagePath != null ? FileImage(File(pet.imagePath!)) : null,
                              child: pet.imagePath == null ? const Icon(Icons.pets, color: Colors.white, size: 30) : null,
                            ),
                            Positioned(
                              top: -4,
                              right: -4,
                              child: GestureDetector(
                                onTap: () => _deletePet(index),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close, color: Colors.white, size: 16),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(pet.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      ],
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