import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_selector/file_selector.dart';

Future<String?> pickImageFromGallery() async {
  try {
    XFile? file;
    try {
      const group = XTypeGroup(
        label: 'Images',
        extensions: ['jpg', 'jpeg', 'png'],
        mimeTypes: ['image/jpeg', 'image/png'],
      );
      file = await openFile(acceptedTypeGroups: [group]);
    } catch (_) {
      file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
      );
    }
    if (file == null) return null;
    return base64Encode(await file.readAsBytes());
  } catch (_) {
    return null;
  }
}

Future<String?> pickImageFromCamera() async {
  try {
    final file = await ImagePicker().pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
      maxWidth: 1024,
      maxHeight: 1024,
    );
    if (file == null) return null;
    return base64Encode(await file.readAsBytes());
  } catch (_) {
    return null;
  }
}

void showAttachImageDialog(
  BuildContext context, {
  required Future<void> Function() onGallery,
  required Future<void> Function() onCamera,
}) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Add Image'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _AttachOption(
            icon: Icons.image,
            label: 'Choose from Gallery',
            sub: 'Select from your device',
            onTap: () {
              Navigator.pop(context);
              onGallery();
            },
          ),
          const SizedBox(height: 8),
          _AttachOption(
            icon: Icons.camera_alt,
            label: 'Take Photo',
            sub: 'Capture with camera',
            onTap: () {
              Navigator.pop(context);
              onCamera();
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    ),
  );
}

class _AttachOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sub;
  final VoidCallback onTap;

  const _AttachOption({
    required this.icon,
    required this.label,
    required this.sub,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => ListTile(
        leading: Icon(icon, color: Colors.blue[400]),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle:
            Text(sub, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Colors.grey[300]!),
        ),
      );
}
