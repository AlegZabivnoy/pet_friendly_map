import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dog_friendly_map/l10n/app_localizations.dart';
import 'package:dog_friendly_map/main.dart';
import 'package:dog_friendly_map/services/settings_service.dart';
import 'package:dog_friendly_map/services/api_service.dart';

class Pet {
  final int? id;
  final String name;
  final String? imagePath;
  final String size;

  Pet({
    this.id,
    required this.name,
    this.imagePath,
    this.size = 'medium',
  });

  factory Pet.fromJson(Map<String, dynamic> json) => Pet(
    id: json['id'],
    name: json['name'] ?? '',
    imagePath: json['image_path'] ?? json['imagePath'],
    size: json['size'] ?? 'medium',
  );
}

class ProfileScreen extends StatefulWidget {
  final VoidCallback onBackToMap;

  const ProfileScreen({
    super.key,
    required this.onBackToMap,
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
    setState(() {
      _userName = prefs.getString('user_name') ?? '';
      _userNickname = prefs.getString('user_nickname') ?? '@nickname';
    });

    final profileData = await ApiService.fetchProfile();
    if (profileData != null && mounted) {
      setState(() {
        _userName = profileData['user']?['name'] ?? _userName;
        _userNickname = profileData['user']?['nickname'] ?? _userNickname;
        if (profileData['pets'] is List) {
          final petsList = profileData['pets'] as List<dynamic>;
          _myPets.clear();
          _myPets.addAll(petsList.map((e) => Pet.fromJson(e)).toList());
        }
      });
    }
  }

  void _deletePet(int index) async {
    final pet = _myPets[index];
    if (pet.id != null) {
      final success = await ApiService.deletePet(pet.id!);
      if (success && mounted) {
        setState(() {
          _myPets.removeAt(index);
        });
      }
    } else {
      setState(() {
        _myPets.removeAt(index);
      });
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    await prefs.remove('user_name');
    await prefs.remove('user_nickname');
    await prefs.remove('saved_pets');
    await prefs.setBool('is_registered', false);

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

  String _getPetSizeLabel(String size, AppLocalizations l10n) {
    switch (size) {
      case 'small':
        return l10n.sizeSmallShort;
      case 'large':
        return l10n.sizeLargeShort;
      default:
        return l10n.sizeMediumShort;
    }
  }

  Future<void> _addNewPet(AppLocalizations l10n) async {
    String petName = "";
    String selectedSize = "medium";
    XFile? selectedImage;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(l10n.newPetTitle, textAlign: TextAlign.center),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () async {
                        try {
                          final XFile? image = await _picker.pickImage(
                            source: ImageSource.gallery,
                            imageQuality: 85,
                          );
                          if (image != null) {
                            setStateDialog(() {
                              selectedImage = image;
                            });
                          }
                        } catch (e) {
                          debugPrint('Error picking image: $e');
                        }
                      },
                      child: CircleAvatar(
                        radius: 46,
                        backgroundColor: Colors.grey[200],
                        backgroundImage: selectedImage != null
                            ? FileImage(File(selectedImage!.path))
                            : null,
                        child: selectedImage == null
                            ? const Icon(Icons.add_a_photo, size: 36, color: Colors.grey)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      autofocus: true,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: l10n.petNameHint,
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.grey[100],
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      onChanged: (value) => petName = value.trim(),
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        l10n.petSize,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(
                          label: Text(l10n.sizeSmall, style: const TextStyle(fontSize: 12)),
                          selected: selectedSize == 'small',
                          onSelected: (val) {
                            if (val) setStateDialog(() => selectedSize = 'small');
                          },
                        ),
                        ChoiceChip(
                          label: Text(l10n.sizeMedium, style: const TextStyle(fontSize: 12)),
                          selected: selectedSize == 'medium',
                          onSelected: (val) {
                            if (val) setStateDialog(() => selectedSize = 'medium');
                          },
                        ),
                        ChoiceChip(
                          label: Text(l10n.sizeLarge, style: const TextStyle(fontSize: 12)),
                          selected: selectedSize == 'large',
                          onSelected: (val) {
                            if (val) setStateDialog(() => selectedSize = 'large');
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.cancel, style: const TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    l10n.save,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (petName.isNotEmpty || selectedImage != null) {
      final savedName = petName.isEmpty ? l10n.noName : petName;
      final createdPetData = await ApiService.addPet(
        savedName,
        selectedImage?.path,
        size: selectedSize,
      );
      if (createdPetData != null && mounted) {
        setState(() {
          _myPets.insert(0, Pet.fromJson(createdPetData));
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final displayName = _userName.isNotEmpty ? _userName : l10n.nameNotSpecified;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: widget.onBackToMap,
        ),
        title: Text(l10n.myProfile, style: const TextStyle(fontWeight: FontWeight.bold)),
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
                    Text(displayName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
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
                Text(l10n.myPets, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.green, size: 32),
                  onPressed: () => _addNewPet(l10n),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 145,
              child: _myPets.isEmpty
                  ? Center(
                child: Text(
                  l10n.addFirstPet,
                  style: TextStyle(color: Colors.grey[500], fontSize: 15),
                ),
              )
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
                              radius: 38,
                              backgroundColor: Colors.grey[300],
                              backgroundImage: pet.imagePath != null
                                  ? FileImage(File(pet.imagePath!))
                                  : null,
                              child: pet.imagePath == null
                                  ? const Icon(Icons.pets, color: Colors.white, size: 28)
                                  : null,
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
                                  child: const Icon(Icons.close, color: Colors.white, size: 14),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          pet.name,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                        Container(
                          margin: const EdgeInsets.only(top: 2),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _getPetSizeLabel(pet.size, l10n),
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.green,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
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