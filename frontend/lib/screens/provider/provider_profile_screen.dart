import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/provider_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/provider_provider.dart';
import '../../utils/theme.dart';
import '../auth/login_screen.dart';

class ProviderProfileScreen extends StatefulWidget {
  const ProviderProfileScreen({super.key});

  @override
  State<ProviderProfileScreen> createState() => _ProviderProfileScreenState();
}

class _ProviderProfileScreenState extends State<ProviderProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProviderProfile();
    });
  }

  Future<void> _loadProviderProfile() async {
    final providerProvider = Provider.of<ProviderProvider>(context, listen: false);
    await providerProvider.getMyProviderProfile();
  }

  Future<void> _logout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final providerProvider = Provider.of<ProviderProvider>(context, listen: false);

    await authProvider.logout();
    providerProvider.reset();
    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final providerProvider = Provider.of<ProviderProvider>(context);
    final provider = providerProvider.currentProvider;
    final user = authProvider.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Provider Profile'),
        actions: [
          if (provider != null)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _showEditProviderDialog(context, providerProvider),
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: providerProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider == null
              ? _buildNoProfileState()
              : RefreshIndicator(
                  onRefresh: _loadProviderProfile,
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      Center(
                        child: Column(
                          children: [
                            Stack(
                              children: [
                                CircleAvatar(
                                  radius: 60,
                                  backgroundImage: (user?.profilePhoto?.isNotEmpty ?? false)
                                      ? NetworkImage(user!.profilePhoto!)
                                      : null,
                                  child: !(user?.profilePhoto?.isNotEmpty ?? false)
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
                              user?.name ?? provider.displayName,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              provider.category?.name ?? 'Service Provider',
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              decoration: BoxDecoration(
                                color: provider.isVerified
                                    ? AppTheme.secondaryColor.withOpacity(0.1)
                                    : Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                provider.isVerified
                                    ? 'Verified Provider'
                                    : 'Verification ${provider.verificationStatus.toUpperCase()}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: provider.isVerified
                                      ? AppTheme.secondaryColor
                                      : Colors.orange,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              title: 'Rating',
                              value: provider.rating.toStringAsFixed(1),
                              icon: Icons.star,
                              color: AppTheme.accentColor,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatCard(
                              title: 'Reviews',
                              value: '${provider.totalReviews}',
                              icon: Icons.reviews,
                              color: AppTheme.infoColor,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatCard(
                              title: 'Jobs',
                              value: '${provider.totalBookings}',
                              icon: Icons.work,
                              color: AppTheme.secondaryColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _SectionTitle('Hourly Rate'),
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.attach_money, color: AppTheme.primaryColor),
                          title: Text('\$${provider.hourlyRate.toStringAsFixed(2)} / hour'),
                          subtitle: Text('${provider.experience} years experience'),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _SectionTitle('About'),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            provider.description.isNotEmpty
                                ? provider.description
                                : 'No description added yet.',
                            style: const TextStyle(height: 1.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _SectionTitle('Skills'),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: provider.skills
                            .map(
                              (skill) => Chip(
                                label: Text(skill),
                                backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                                labelStyle: const TextStyle(color: AppTheme.primaryColor),
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 20),
                      _SectionTitle('Coverage'),
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.location_on, color: AppTheme.primaryColor),
                          title: Text('${provider.serviceArea} miles service radius'),
                          subtitle: Text(user?.location?.fullAddress ?? 'Location not configured'),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          const Expanded(child: _SectionTitle('Availability')),
                          TextButton.icon(
                            onPressed: () => _showEditAvailabilityDialog(context, providerProvider),
                            icon: const Icon(Icons.schedule),
                            label: const Text('Edit'),
                          ),
                        ],
                      ),
                      Card(
                        child: Column(
                          children: _availabilityRows(provider.availability),
                        ),
                      ),
                      const SizedBox(height: 24),
                      OutlinedButton.icon(
                        onPressed: _logout,
                        icon: const Icon(Icons.logout),
                        label: const Text('Logout'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.errorColor,
                          side: const BorderSide(color: AppTheme.errorColor),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
    );
  }

  Widget _buildNoProfileState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.work_outline, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text(
              'Provider profile not found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Create your provider profile to start receiving bookings.',
              style: TextStyle(color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/create-provider-profile'),
              child: const Text('Create Profile'),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _availabilityRows(Availability availability) {
    final days = [
      ('Monday', availability.monday),
      ('Tuesday', availability.tuesday),
      ('Wednesday', availability.wednesday),
      ('Thursday', availability.thursday),
      ('Friday', availability.friday),
      ('Saturday', availability.saturday),
      ('Sunday', availability.sunday),
    ];

    return days
        .map(
          (entry) => ListTile(
            title: Text(entry.$1),
            trailing: Text(
              entry.$2.available
                  ? '${entry.$2.startTime} - ${entry.$2.endTime}'
                  : 'Unavailable',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: entry.$2.available
                    ? AppTheme.secondaryColor
                    : AppTheme.errorColor,
              ),
            ),
          ),
        )
        .toList();
  }

  Future<void> _showPhotoDialog(
    BuildContext context,
    AuthProvider authProvider,
  ) async {
    final controller = TextEditingController(text: authProvider.user?.profilePhoto ?? '');
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Profile Photo URL'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Image URL',
            hintText: 'https://example.com/provider.jpg',
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

    final success = await authProvider.updateProfile(profilePhoto: controller.text.trim());
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

  Future<void> _showEditProviderDialog(
    BuildContext context,
    ProviderProvider providerProvider,
  ) async {
    final provider = providerProvider.currentProvider;
    if (provider == null) return;

    final hourlyRateController =
        TextEditingController(text: provider.hourlyRate.toString());
    final experienceController =
        TextEditingController(text: provider.experience.toString());
    final serviceAreaController =
        TextEditingController(text: provider.serviceArea.toString());
    final descriptionController =
        TextEditingController(text: provider.description);
    final skillsController =
        TextEditingController(text: provider.skills.join(', '));

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Provider Profile'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: hourlyRateController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Hourly rate'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: experienceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Experience (years)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: serviceAreaController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Service area (miles)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: skillsController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Skills',
                  hintText: 'Separate with commas',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Description'),
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
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (saved != true || !context.mounted) return;

    final skills = skillsController.text
        .split(',')
        .map((skill) => skill.trim())
        .where((skill) => skill.isNotEmpty)
        .toList();

    final success = await providerProvider.updateProviderProfile(
      id: provider.id,
      hourlyRate: double.tryParse(hourlyRateController.text.trim()),
      experience: int.tryParse(experienceController.text.trim()),
      serviceArea: int.tryParse(serviceAreaController.text.trim()),
      skills: skills,
      description: descriptionController.text.trim(),
    );

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Provider profile updated successfully.'
              : (providerProvider.error ?? 'Failed to update provider profile.'),
        ),
        backgroundColor: success ? AppTheme.successColor : AppTheme.errorColor,
      ),
    );
  }

  Future<void> _showEditAvailabilityDialog(
    BuildContext context,
    ProviderProvider providerProvider,
  ) async {
    final provider = providerProvider.currentProvider;
    if (provider == null) return;

    final editableDays = {
      'Monday': EditableDayAvailability.fromDay(provider.availability.monday),
      'Tuesday': EditableDayAvailability.fromDay(provider.availability.tuesday),
      'Wednesday': EditableDayAvailability.fromDay(provider.availability.wednesday),
      'Thursday': EditableDayAvailability.fromDay(provider.availability.thursday),
      'Friday': EditableDayAvailability.fromDay(provider.availability.friday),
      'Saturday': EditableDayAvailability.fromDay(provider.availability.saturday),
      'Sunday': EditableDayAvailability.fromDay(provider.availability.sunday),
    };

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Edit Availability'),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: editableDays.entries.map((entry) {
                      final day = entry.key;
                      final availability = entry.value;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.dividerColor),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      day,
                                      style: const TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                  Switch(
                                    value: availability.available,
                                    onChanged: (value) {
                                      setDialogState(() {
                                        availability.available = value;
                                      });
                                    },
                                  ),
                                ],
                              ),
                              if (availability.available)
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () async {
                                          final selected = await _pickTime(
                                            context,
                                            availability.startTime,
                                          );
                                          if (selected != null) {
                                            setDialogState(() {
                                              availability.startTime = selected;
                                            });
                                          }
                                        },
                                        child: Text('Start: ${availability.startTime}'),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () async {
                                          final selected = await _pickTime(
                                            context,
                                            availability.endTime,
                                          );
                                          if (selected != null) {
                                            setDialogState(() {
                                              availability.endTime = selected;
                                            });
                                          }
                                        },
                                        child: Text('End: ${availability.endTime}'),
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
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
      },
    );

    if (saved != true || !context.mounted) return;

    final success = await providerProvider.updateProviderProfile(
      id: provider.id,
      availability: Availability(
        monday: editableDays['Monday']!.toDayAvailability(),
        tuesday: editableDays['Tuesday']!.toDayAvailability(),
        wednesday: editableDays['Wednesday']!.toDayAvailability(),
        thursday: editableDays['Thursday']!.toDayAvailability(),
        friday: editableDays['Friday']!.toDayAvailability(),
        saturday: editableDays['Saturday']!.toDayAvailability(),
        sunday: editableDays['Sunday']!.toDayAvailability(),
      ),
    );

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Availability updated successfully.'
              : (providerProvider.error ?? 'Failed to update availability.'),
        ),
        backgroundColor: success ? AppTheme.successColor : AppTheme.errorColor,
      ),
    );
  }

  Future<String?> _pickTime(BuildContext context, String initialTime) async {
    final parts = initialTime.split(':');
    final initial = TimeOfDay(
      hour: int.tryParse(parts.first) ?? 9,
      minute: int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
    );

    final selected = await showTimePicker(
      context: context,
      initialTime: initial,
    );

    if (selected == null) return null;
    return '${selected.hour.toString().padLeft(2, '0')}:${selected.minute.toString().padLeft(2, '0')}';
  }
}

class EditableDayAvailability {
  bool available;
  String startTime;
  String endTime;

  EditableDayAvailability({
    required this.available,
    required this.startTime,
    required this.endTime,
  });

  factory EditableDayAvailability.fromDay(DayAvailability day) {
    return EditableDayAvailability(
      available: day.available,
      startTime: day.startTime.isNotEmpty ? day.startTime : '09:00',
      endTime: day.endTime.isNotEmpty ? day.endTime : '17:00',
    );
  }

  DayAvailability toDayAvailability() {
    return DayAvailability(
      available: available,
      startTime: available ? startTime : '',
      endTime: available ? endTime : '',
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
