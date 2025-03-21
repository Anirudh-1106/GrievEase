import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:io';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/location_service.dart';
import 'package:geolocator/geolocator.dart';
import '../screen/location_picker_screen.dart';

class ComplaintSubmissionScreen extends StatefulWidget {
  final String userName;

  const ComplaintSubmissionScreen({super.key, required this.userName});

  @override
  State<ComplaintSubmissionScreen> createState() =>
      _ComplaintSubmissionScreenState();
}

class _ComplaintSubmissionScreenState extends State<ComplaintSubmissionScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedCategory = 'Infrastructure';
  File? _image;
  final ImagePicker _picker = ImagePicker();
  LatLng? _selectedLocation;
  String? _locationAddress;

  Future<void> _getImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Image Source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(context);
                _getImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.pop(context);
                _getImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    if (_image == null) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Image.file(
              _image!,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
            OverflowBar(
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('Change'),
                  onPressed: _showImageSourceDialog,
                ),
                TextButton.icon(
                  icon: const Icon(Icons.delete),
                  label: const Text('Remove'),
                  onPressed: () => setState(() => _image = null),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showLocationPicker() async {
    final Position? currentPosition =
        await LocationService.getCurrentLocation();
    if (currentPosition == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to get current location')),
      );
      return;
    }

    if (!mounted) return;
    final LatLng? result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LocationPickerScreen(
          initialPosition: LatLng(
            currentPosition.latitude,
            currentPosition.longitude,
          ),
        ),
      ),
    );

    if (result != null) {
      _selectedLocation = result;
      _locationAddress = await LocationService.getAddressFromCoordinates(
        result.latitude,
        result.longitude,
      );
      setState(() {});
    }
  }

  Future<void> _submitComplaint() async {
    try {
      // Get appropriate base URL
      final baseUrl = kIsWeb
          ? 'http://localhost:3000'
          : Platform.isAndroid
              ? 'http://10.0.2.2:3000'
              : 'http://localhost:3000';

      final response = await http
          .post(
            Uri.parse('$baseUrl/complaints'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: json.encode({
              'title': _titleController.text,
              'description': _descriptionController.text,
              'category': _selectedCategory,
              'userName': widget.userName,
              'image': _image != null
                  ? base64Encode(await _image!.readAsBytes())
                  : null, // If image is selected
              'location': _selectedLocation != null
                  ? {
                      'latitude': _selectedLocation!.latitude,
                      'longitude': _selectedLocation!.longitude,
                      'address': _locationAddress ?? 'Location selected'
                    }
                  : null,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (!mounted) return;

      final data = json.decode(response.body);
      if (response.statusCode == 201 && data['success']) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Complaint submitted: ${data['complaintId']}')),
        );
      } else {
        throw Exception(data['message'] ?? 'Failed to submit complaint');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lodge Complaint'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                items: <String>[
                  'Infrastructure',
                  'Academics',
                  'Administration',
                  'Hostel',
                  'Others'
                ].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedCategory = newValue!;
                  });
                },
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Subject/Title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _descriptionController,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Detailed Description',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _showImageSourceDialog,
                icon: const Icon(Icons.add_a_photo),
                label: const Text('Add Image'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                ),
              ),
              _buildImagePreview(),
              const SizedBox(height: 20),
              if (_selectedLocation != null)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.location_on),
                    title: Text(_locationAddress ?? 'Location selected'),
                    trailing: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() {
                        _selectedLocation = null;
                        _locationAddress = null;
                      }),
                    ),
                  ),
                ),
              ElevatedButton.icon(
                onPressed: _showLocationPicker,
                icon: const Icon(Icons.add_location),
                label: const Text('Add Location'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitComplaint,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                ),
                child: const Text('Submit Complaint'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
