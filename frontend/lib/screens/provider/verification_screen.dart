import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/provider_provider.dart';
import '../../utils/theme.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  bool _isUploading = false;
  final List<XFile> _selectedFiles = [];

  Future<void> _pickFiles() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> files = await picker.pickMultiImage(
      imageQuality: 80,
    );

    if (files.isEmpty) return;

    setState(() {
      _selectedFiles.addAll(files);
    });
  }

  void _removeFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
    });
  }

  Future<void> _submit() async {
    if (_selectedFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one document.')),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      final providerProvider = Provider.of<ProviderProvider>(context, listen: false);
      final success = await providerProvider.uploadVerificationDocuments(_selectedFiles);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Documents submitted successfully! Our team will review them.'),
              backgroundColor: AppTheme.successColor,
            ),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to submit documents.'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final providerProvider = Provider.of<ProviderProvider>(context);
    final status = providerProvider.currentProvider?.verificationStatus ?? 'pending';
    final isVerified = providerProvider.currentProvider?.isVerified ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ID Verification'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusHeader(status, isVerified),
            const SizedBox(height: 24),
            const Text(
              'Upload Documents',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please upload a clear photo of your Government ID and any professional certifications to become a verified provider.',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 24),
            
            // File List
            if (_selectedFiles.isNotEmpty) ...[
              const Text('Selected Files:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _selectedFiles.length,
                itemBuilder: (context, index) => ListTile(
                  leading: const Icon(Icons.description, color: AppTheme.primaryColor),
                  title: Text(_selectedFiles[index].name),
                  trailing: IconButton(
                    icon: const Icon(Icons.close, color: AppTheme.errorColor),
                    onPressed: () => _removeFile(index),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Add button
            OutlinedButton.icon(
              onPressed: _isUploading ? null : _pickFiles,
              icon: const Icon(Icons.upload_file),
              label: const Text('Select Files'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
            const SizedBox(height: 32),

            // Submit button
            ElevatedButton(
              onPressed: (_isUploading || _selectedFiles.isEmpty) ? null : _submit,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: _isUploading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Submit for Verification', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            
            const SizedBox(height: 40),
            _buildSecurityNote(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHeader(String status, bool isVerified) {
    Color color = AppTheme.warningColor;
    String text = 'Action Required';
    String desc = 'Your profile is not yet verified. Customers trust verified providers more.';

    if (isVerified) {
      color = AppTheme.successColor;
      text = 'Verified';
      desc = 'Your account is verified. You have full access to the platform.';
    } else if (status == 'pending') {
      color = AppTheme.primaryColor;
      text = 'Under Review';
      desc = 'We have received your documents and are reviewing them. This usually takes 24-48 hours.';
    } else if (status == 'rejected') {
      color = AppTheme.errorColor;
      text = 'Rejected';
      desc = 'Your verification was rejected. Please re-upload clear documents.';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(isVerified ? Icons.verified : Icons.info_outline, color: color),
              const SizedBox(width: 12),
              Text(
                text,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(desc, style: const TextStyle(height: 1.4)),
        ],
      ),
    );
  }

  Widget _buildSecurityNote() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lock_outline, size: 20, color: AppTheme.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Your documents are encrypted and stored securely. They are only used for verification purposes and will never be shared with others.',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
