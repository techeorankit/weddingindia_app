import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/api_service.dart';

class DocumentUploadScreen extends StatefulWidget {
  const DocumentUploadScreen({super.key});

  @override
  State<DocumentUploadScreen> createState() => _DocumentUploadScreenState();
}

class _DocumentUploadScreenState extends State<DocumentUploadScreen> {
  File? _document;
  File? _selfie;
  String? _documentType;
  bool _uploading = false;

  static const _documentTypes = ['Aadhaar Card', 'PAN Card', 'Voter ID', 'Passport'];

  Future<void> _pickDocument() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'webp'],
    );
    final path = result?.files.single.path;
    if (path != null) setState(() => _document = File(path));
  }

  Future<void> _pickSelfie() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
      maxWidth: 1200,
    );
    if (picked != null) setState(() => _selfie = File(picked.path));
  }

  Future<void> _upload() async {
    if (_document == null || _selfie == null || _documentType == null) return;
    setState(() => _uploading = true);
    final result = await ApiService.uploadDocument(
      documentFile: _document!,
      documentType: _documentType!,
      selfieFile: _selfie!,
    );
    if (!mounted) return;
    setState(() => _uploading = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(result['message']?.toString() ?? 'Document upload failed'),
      backgroundColor: result['status'] == true ? Colors.green : Colors.red,
    ));
    if (result['status'] == true) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload Document')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Upload any one document: Aadhaar Card, PAN Card, Voter ID, or Passport',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _documentType,
              decoration: const InputDecoration(
                labelText: 'Select document type',
                border: OutlineInputBorder(),
              ),
              items: _documentTypes
                  .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                  .toList(),
              onChanged: _uploading ? null : (value) => setState(() => _documentType = value),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _uploading ? null : _pickDocument,
              icon: const Icon(Icons.upload_file),
              label: Text(_document == null
                  ? 'Choose document'
                  : _document!.path.split(Platform.pathSeparator).last),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: _uploading ? null : _pickSelfie,
              icon: const Icon(Icons.camera_alt_outlined),
              label: Text(_selfie == null
                  ? 'Take selfie with document'
                  : _selfie!.path.split(Platform.pathSeparator).last),
            ),
            const SizedBox(height: 8),
            Text(
              'Selfie is required with the selected document.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _document == null || _selfie == null || _documentType == null || _uploading
                  ? null
                  : _upload,
              icon: _uploading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.cloud_upload_outlined),
              label: Text(_uploading ? 'Uploading...' : 'Upload document'),
            ),
          ],
        ),
      ),
    );
  }
}
