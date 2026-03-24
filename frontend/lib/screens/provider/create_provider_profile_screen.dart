import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/provider_provider.dart';
import '../../utils/theme.dart';

class CreateProviderProfileScreen extends StatefulWidget {
  const CreateProviderProfileScreen({super.key});

  @override
  State<CreateProviderProfileScreen> createState() => _CreateProviderProfileScreenState();
}

class _CreateProviderProfileScreenState extends State<CreateProviderProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _hourlyRateController = TextEditingController();
  final _experienceController = TextEditingController();
  final _serviceAreaController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _skillController = TextEditingController();
  
  List<String> _skills = [];
  bool _isLoading = false;
  String? _selectedCategoryId;
  
  // Availability schedule
  Map<String, DayAvailability> _availability = {
    'monday': DayAvailability(day: 'Monday'),
    'tuesday': DayAvailability(day: 'Tuesday'),
    'wednesday': DayAvailability(day: 'Wednesday'),
    'thursday': DayAvailability(day: 'Thursday'),
    'friday': DayAvailability(day: 'Friday'),
    'saturday': DayAvailability(day: 'Saturday'),
    'sunday': DayAvailability(day: 'Sunday'),
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProviderProvider>(context, listen: false).loadCategories();
    });
  }

  void _addSkill() {
    final skill = _skillController.text.trim();
    if (skill.isNotEmpty && !_skills.contains(skill)) {
      setState(() {
        _skills.add(skill);
        _skillController.clear();
      });
    }
  }

  void _removeSkill(String skill) {
    setState(() {
      _skills.remove(skill);
    });
  }

  Future<void> _createProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (_skills.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one skill')),
      );
      return;
    }
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a service category')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final providerProvider = Provider.of<ProviderProvider>(context, listen: false);
      
      final success = await providerProvider.createProviderProfile(
        categoryId: _selectedCategoryId!,
        skills: _skills,
        experience: int.parse(_experienceController.text),
        hourlyRate: double.parse(_hourlyRateController.text),
        description: _descriptionController.text,
        serviceArea: double.parse(_serviceAreaController.text),
        availability: _availability.map((key, value) => MapEntry(key, value.toJson())),
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile created successfully!')),
          );
          Navigator.pushReplacementNamed(context, '/provider-profile');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(providerProvider.error ?? 'Failed to create profile')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _hourlyRateController.dispose();
    _experienceController.dispose();
    _serviceAreaController.dispose();
    _descriptionController.dispose();
    _skillController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Provider Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.work_outline,
                            size: 80,
                            color: AppTheme.primaryColor.withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Set Up Your Profile',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Tell customers about your services',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Category
                    _buildSectionTitle('Service Category'),
                    const SizedBox(height: 8),
                    Consumer<ProviderProvider>(
                      builder: (context, providerProv, _) {
                        final categories = providerProv.categories;
                        return DropdownButtonFormField<String>(
                          value: _selectedCategoryId,
                          decoration: _inputDecoration(
                            hintText: 'Select your service category',
                            prefixIcon: Icons.category,
                          ),
                          items: categories.map((cat) {
                            return DropdownMenuItem<String>(
                              value: cat.id,
                              child: Text(cat.name),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() => _selectedCategoryId = value);
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please select a service category';
                            }
                            return null;
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 20),

                    // Hourly Rate
                    _buildSectionTitle('Hourly Rate (\$)'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _hourlyRateController,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration(
                        hintText: 'e.g., 50',
                        prefixIcon: Icons.attach_money,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your hourly rate';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Experience
                    _buildSectionTitle('Experience (Years)'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _experienceController,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration(
                        hintText: 'e.g., 5',
                        prefixIcon: Icons.timer,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your experience';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Service Area
                    _buildSectionTitle('Service Area (Miles)'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _serviceAreaController,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration(
                        hintText: 'e.g., 10',
                        prefixIcon: Icons.location_on,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your service area';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Skills
                    _buildSectionTitle('Skills'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _skillController,
                            decoration: _inputDecoration(
                              hintText: 'Add a skill (e.g., Plumbing)',
                              prefixIcon: Icons.star,
                            ),
                            onSubmitted: (_) => _addSkill(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _addSkill,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          ),
                          child: const Text('Add'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_skills.isNotEmpty)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _skills.map((skill) {
                          return Chip(
                            label: Text(skill),
                            deleteIcon: const Icon(Icons.close, size: 18),
                            onDeleted: () => _removeSkill(skill),
                            backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                            labelStyle: const TextStyle(color: AppTheme.primaryColor),
                          );
                        }).toList(),
                      ),
                    const SizedBox(height: 20),

                    // Description
                    _buildSectionTitle('About You'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 4,
                      decoration: _inputDecoration(
                        hintText: 'Describe your experience, expertise, and what customers can expect...',
                        prefixIcon: Icons.description,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a description';
                        }
                        if (value.length < 50) {
                          return 'Description should be at least 50 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Availability
                    _buildSectionTitle('Availability Schedule'),
                    const SizedBox(height: 8),
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: _availability.entries.map((entry) {
                            return _buildAvailabilityRow(entry.key, entry.value);
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _createProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Create Profile',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppTheme.textPrimary,
      ),
    );
  }

  InputDecoration _inputDecoration({required String hintText, required IconData prefixIcon}) {
    return InputDecoration(
      hintText: hintText,
      prefixIcon: Icon(prefixIcon, color: AppTheme.primaryColor),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
      ),
      filled: true,
      fillColor: Colors.grey[50],
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  Widget _buildAvailabilityRow(String dayKey, DayAvailability dayAvail) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              dayAvail.day,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Switch(
            value: dayAvail.available,
            onChanged: (value) {
              setState(() {
                dayAvail.available = value;
              });
            },
            activeColor: AppTheme.secondaryColor,
          ),
          const SizedBox(width: 8),
          if (dayAvail.available) ...[
            Expanded(
              child: TextButton(
                onPressed: () => _selectTime(dayAvail, true),
                child: Text(dayAvail.startTime),
              ),
            ),
            const Text('to'),
            Expanded(
              child: TextButton(
                onPressed: () => _selectTime(dayAvail, false),
                child: Text(dayAvail.endTime),
              ),
            ),
          ] else
            const Expanded(
              child: Text(
                'Unavailable',
                style: TextStyle(color: Colors.grey),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _selectTime(DayAvailability dayAvail, bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStartTime
          ? _parseTime(dayAvail.startTime)
          : _parseTime(dayAvail.endTime),
    );
    if (picked != null) {
      setState(() {
        final timeStr = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
        if (isStartTime) {
          dayAvail.startTime = timeStr;
        } else {
          dayAvail.endTime = timeStr;
        }
      });
    }
  }

  TimeOfDay _parseTime(String timeStr) {
    final parts = timeStr.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }
}

class DayAvailability {
  String day;
  bool available;
  String startTime;
  String endTime;

  DayAvailability({
    required this.day,
    this.available = false,
    this.startTime = '09:00',
    this.endTime = '17:00',
  });

  Map<String, dynamic> toJson() {
    return {
      'available': available,
      'startTime': startTime,
      'endTime': endTime,
    };
  }
}