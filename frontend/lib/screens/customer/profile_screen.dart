import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../utils/theme.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    if (user == null) {
      return const Center(child: Text('Please login'));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _showEditProfileDialog(context, authProvider),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Center(
              child: Column(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundImage: (user.profilePhoto?.isNotEmpty ?? false)
                            ? NetworkImage(user.profilePhoto!)
                            : null,
                        child: !(user.profilePhoto?.isNotEmpty ?? false)
                            ? const Icon(Icons.person, size: 60)
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: AppTheme.primaryColor,
                          child: IconButton(
                            icon: const Icon(Icons.camera_alt, size: 18),
                            color: Colors.white,
                            onPressed: () => _showPhotoDialog(context, authProvider),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user.name,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      user.role.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            _ProfileSection(
              title: 'Personal Information',
              children: [
                _ProfileTile(
                  icon: Icons.phone,
                  title: 'Phone',
                  subtitle: user.phone.isNotEmpty ? user.phone : 'Not set',
                  onTap: () => _showEditProfileDialog(context, authProvider),
                ),
                _ProfileTile(
                  icon: Icons.location_on,
                  title: 'Location',
                  subtitle: user.location?.fullAddress ?? 'Not set',
                  onTap: () => _showEditProfileDialog(context, authProvider),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _ProfileSection(
              title: 'Settings',
              children: [
                _ProfileTile(
                  icon: Icons.notifications,
                  title: 'Notifications',
                  subtitle: 'View notification preferences',
                  onTap: () => _showInfoDialog(
                    context,
                    title: 'Notifications',
                    message:
                        'Push and email notifications are enabled for bookings, provider updates, and account activity.',
                  ),
                ),
                _ProfileTile(
                  icon: Icons.lock,
                  title: 'Change Password',
                  subtitle: 'Update your password securely',
                  onTap: () => _showChangePasswordDialog(context, authProvider),
                ),
                _ProfileTile(
                  icon: Icons.privacy_tip,
                  title: 'Privacy',
                  subtitle: 'Review how your data is used',
                  onTap: () => _showInfoDialog(
                    context,
                    title: 'Privacy',
                    message:
                        'Your personal data is only used for bookings, account security, and service matching within ProConnect.',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _ProfileSection(
              title: 'Support',
              children: [
                _ProfileTile(
                  icon: Icons.help,
                  title: 'Help Center',
                  subtitle: 'Get tips for bookings and providers',
                  onTap: () => _showInfoDialog(
                    context,
                    title: 'Help Center',
                    message:
                        'Use Browse to find providers, Bookings to manage jobs, and Profile to keep your account up to date.',
                  ),
                ),
                _ProfileTile(
                  icon: Icons.feedback,
                  title: 'Send Feedback',
                  subtitle: 'Tell us what should improve',
                  onTap: () => _showFeedbackDialog(context),
                ),
                _ProfileTile(
                  icon: Icons.info,
                  title: 'About',
                  subtitle: 'App version 1.0.0',
                  onTap: () => _showInfoDialog(
                    context,
                    title: 'About ProConnect',
                    message:
                        'ProConnect helps customers discover trusted local service providers, manage bookings, and review completed services.',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showLogoutDialog(context),
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.errorColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditProfileDialog(
    BuildContext context,
    AuthProvider authProvider,
  ) async {
    final user = authProvider.user!;
    final nameController = TextEditingController(text: user.name);
    final phoneController = TextEditingController(text: user.phone);
    final addressController =
        TextEditingController(text: user.location?.address ?? '');
    final cityController = TextEditingController(text: user.location?.city ?? '');
    final stateController = TextEditingController(text: user.location?.state ?? '');
    final zipController = TextEditingController(text: user.location?.zipCode ?? '');

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Edit Profile'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
                const SizedBox(height: 12),
                TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Phone')),
                const SizedBox(height: 12),
                TextField(controller: addressController, decoration: const InputDecoration(labelText: 'Address')),
                const SizedBox(height: 12),
                TextField(controller: cityController, decoration: const InputDecoration(labelText: 'City')),
                const SizedBox(height: 12),
                TextField(controller: stateController, decoration: const InputDecoration(labelText: 'State')),
                const SizedBox(height: 12),
                TextField(controller: zipController, decoration: const InputDecoration(labelText: 'Zip Code')),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (saved != true || !context.mounted) return;

    final hasLocation = addressController.text.trim().isNotEmpty ||
        cityController.text.trim().isNotEmpty ||
        stateController.text.trim().isNotEmpty ||
        zipController.text.trim().isNotEmpty;

    final success = await authProvider.updateProfile(
      name: nameController.text.trim(),
      phone: phoneController.text.trim(),
      location: hasLocation
          ? Location(
              address: addressController.text.trim(),
              city: cityController.text.trim(),
              state: stateController.text.trim(),
              zipCode: zipController.text.trim(),
            )
          : null,
    );

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Profile updated successfully.'
              : (authProvider.error ?? 'Failed to update profile.'),
        ),
        backgroundColor: success ? AppTheme.successColor : AppTheme.errorColor,
      ),
    );
  }

  Future<void> _showPhotoDialog(
    BuildContext context,
    AuthProvider authProvider,
  ) async {
    final controller = TextEditingController(
      text: authProvider.user?.profilePhoto ?? '',
    );

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Profile Photo URL'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Image URL',
            hintText: 'https://example.com/photo.jpg',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Update'),
          ),
        ],
      ),
    );

    if (saved != true || !context.mounted) return;

    final success = await authProvider.updateProfile(
      profilePhoto: controller.text.trim(),
    );

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Profile photo updated successfully.'
              : (authProvider.error ?? 'Failed to update profile photo.'),
        ),
        backgroundColor: success ? AppTheme.successColor : AppTheme.errorColor,
      ),
    );
  }

  Future<void> _showChangePasswordDialog(
    BuildContext context,
    AuthProvider authProvider,
  ) async {
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();

    final submit = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Change Password'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Current password'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: newController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'New password'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Confirm new password'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Update'),
          ),
        ],
      ),
    );

    if (submit != true || !context.mounted) return;

    if (newController.text != confirmController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('New passwords do not match.'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    final success = await authProvider.changePassword(
      currentController.text.trim(),
      newController.text.trim(),
    );

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Password changed successfully.'
              : (authProvider.error ?? 'Failed to change password.'),
        ),
        backgroundColor: success ? AppTheme.successColor : AppTheme.errorColor,
      ),
    );
  }

  void _showInfoDialog(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _showFeedbackDialog(BuildContext context) async {
    final controller = TextEditingController();
    final submitted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Send Feedback'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Your feedback',
            hintText: 'Tell us what should be improved...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Submit'),
          ),
        ],
      ),
    );

    if (submitted == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thanks for the feedback!'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              await authProvider.logout();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

class _ProfileSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _ProfileSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        Card(child: Column(children: children)),
      ],
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ProfileTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryColor),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
