import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/auth_provider.dart';
import '../../services/upload_service.dart';
import '../../utils/theme.dart';
import '../../utils/constants.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/location_picker_map.dart';
import '../../models/user_model.dart';
import '../../providers/provider_provider.dart';
import 'package:latlong2/latlong.dart';

class RegisterScreen extends StatefulWidget {
  final String role;
  const RegisterScreen({super.key, required this.role});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _hourlyRateCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  String? _selectedCategoryId;
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _agreeToTerms = false;
  XFile? _selectedImage;
  LatLng? _selectedLocation;
  String? _addressText;
  late AnimationController _animCtrl;
  late Animation<double> _fadeIn;

  bool get _isProvider => widget.role == AppConstants.roleProvider;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fadeIn = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();

    if (_isProvider) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Provider.of<ProviderProvider>(context, listen: false).loadCategories();
      });
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    _hourlyRateCtrl.dispose();
    _descriptionCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final image = await UploadService.pickImage();
    if (image != null) {
      setState(() => _selectedImage = image);
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please fill in all fields correctly'),
        backgroundColor: AppTheme.errorColor,
      ));
      return;
    }
    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please agree to the terms and conditions'),
        backgroundColor: AppTheme.errorColor,
      ));
      return;
    }
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final success = await auth.register(
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
      role: widget.role,
      phone: _phoneCtrl.text.trim(),
      profileImage: _selectedImage,
      location: _selectedLocation != null 
          ? Location(
              address: _addressText ?? '',
              city: '',
              state: '',
              zipCode: '',
              latitude: _selectedLocation!.latitude,
              longitude: _selectedLocation!.longitude,
            )
          : null,
      jsonMetadata: _isProvider ? {
        'categoryId': _selectedCategoryId,
        'hourlyRate': double.tryParse(_hourlyRateCtrl.text) ?? 50.0,
        'description': _descriptionCtrl.text.trim().isNotEmpty ? _descriptionCtrl.text.trim() : 'Professional ${_isProvider ? "Service Provider" : "User"}',
      } : null,
    );
    if (!mounted) return;
    if (success) {
      Navigator.pushReplacementNamed(
          context, auth.isProvider ? '/provider-home' : '/customer-home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(auth.error ?? 'Registration failed'),
        backgroundColor: AppTheme.errorColor,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final gradient =
        _isProvider ? AppTheme.primaryGradient : AppTheme.goldGradient;
    final accentCol =
        _isProvider ? AppTheme.primaryColor : AppTheme.accentColor;

    return Scaffold(
      backgroundColor: AppTheme.navyDeep,
      body: Stack(children: [
        // bg gradient
        Container(
          decoration: const BoxDecoration(gradient: AppTheme.heroGradient),
        ),
        Positioned(
            top: -60, left: -60, child: _Orb(color: accentCol, size: 200)),
        const Positioned(
            bottom: -80,
            right: -80,
            child: _Orb(color: AppTheme.primaryColor, size: 160)),

        SafeArea(
          child: FadeTransition(
            opacity: _fadeIn,
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  leading: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      margin: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.navySurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.dividerColor),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new,
                          size: 16, color: AppTheme.textPrimary),
                    ),
                  ),
                  pinned: false,
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Header
                      Row(children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: gradient,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _isProvider
                                ? Icons.engineering_rounded
                                : Icons.person_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _isProvider
                                      ? 'Become a Provider'
                                      : 'Create Account',
                                  style: GoogleFonts.inter(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.textPrimary),
                                ),
                                Text(
                                  _isProvider
                                      ? 'Share your skills & earn'
                                      : 'Find trusted professionals',
                                  style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: AppTheme.textSecondary),
                                ),
                              ]),
                        ),
                      ]),
                      const SizedBox(height: 28),

                      // Role badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: gradient,
                          borderRadius: BorderRadius.circular(100),
                          boxShadow: AppTheme.glowShadow(accentCol, blur: 12),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(
                              _isProvider
                                  ? Icons.engineering_rounded
                                  : Icons.person_rounded,
                              size: 14,
                              color: Colors.white),
                          const SizedBox(width: 6),
                          Text(
                            _isProvider ? 'SERVICE PROVIDER' : 'CUSTOMER',
                            style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 1.2),
                          ),
                        ]),
                      ),

                      const SizedBox(height: 32),

                      // Photo Picker
                      Center(
                        child: Stack(children: [
                          GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              width: 100, height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppTheme.navySurface,
                                border: Border.all(color: accentCol, width: 2),
                                boxShadow: AppTheme.glowShadow(accentCol, blur: 20, spread: -5),
                              ),
                              child: _selectedImage != null
                                  ? ClipOval(child: Image.network(_selectedImage!.path, fit: BoxFit.cover, errorBuilder: (_,__,___) => const Icon(Icons.person, size: 50, color: AppTheme.textHint)))
                                  : Icon(Icons.person_add_rounded, size: 40, color: accentCol),
                            ),
                          ),
                          Positioned(bottom: 0, right: 0,
                            child: GestureDetector(
                              onTap: _pickImage,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: accentCol,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppTheme.navyDeep, width: 2),
                                ),
                                child: const Icon(Icons.camera_alt_rounded, size: 14, color: Colors.white),
                              ),
                            ),
                          ),
                        ]),
                      ),
                      const SizedBox(height: 8),
                      Center(child: Text('Optional Profile Photo',
                        style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textHint))),

                      const SizedBox(height: 32),

                      // Form
                      Form(
                        key: _formKey,
                        autovalidateMode: AutovalidateMode.disabled,
                        child: Column(children: [
                          _card(children: [
                            CustomTextField(
                              controller: _nameCtrl,
                              label: 'Full Name',
                              hint: 'Your full name',
                              prefixIcon: Icons.person_outline_rounded,
                              textInputAction: TextInputAction.next,
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Please enter your name';
                                }
                                if (v.trim().length < 2)
                                  return 'At least 2 characters';
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),
                            CustomTextField(
                              controller: _emailCtrl,
                              label: 'Email Address',
                              hint: 'you@example.com',
                              keyboardType: TextInputType.emailAddress,
                              prefixIcon: Icons.email_outlined,
                              textInputAction: TextInputAction.next,
                              validator: (v) {
                                if (v == null || v.trim().isEmpty)
                                  return 'Enter your email';
                                if (!v.contains('@') || !v.contains('.')) {
                                  return 'Enter a valid email';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),
                            CustomTextField(
                              controller: _phoneCtrl,
                              label: 'Phone Number',
                              hint: '+1 000 000 0000',
                              keyboardType: TextInputType.phone,
                              prefixIcon: Icons.phone_outlined,
                              textInputAction: _isProvider ? TextInputAction.next : TextInputAction.done,
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Enter your phone number';
                                }
                                if (v.length < 10)
                                  return 'Enter a valid phone number';
                                return null;
                              },
                            ),

                            if (_isProvider) ...[
                              const SizedBox(height: 14),
                              Consumer<ProviderProvider>(
                                builder: (context, pp, _) {
                                  return DropdownButtonFormField<String>(
                                    value: _selectedCategoryId,
                                    decoration: InputDecoration(
                                      labelText: 'Service Category',
                                      prefixIcon: const Icon(Icons.category_outlined, color: AppTheme.primaryColor),
                                      filled: true,
                                      fillColor: AppTheme.navyElevated,
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                                      labelStyle: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 14),
                                    ),
                                    dropdownColor: AppTheme.navySurface,
                                    style: GoogleFonts.inter(color: AppTheme.textPrimary, fontSize: 14),
                                    items: pp.categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                                    onChanged: (v) => setState(() => _selectedCategoryId = v),
                                    validator: (v) => v == null ? 'Select a category' : null,
                                  );
                                },
                              ),
                              const SizedBox(height: 14),
                              CustomTextField(
                                controller: _hourlyRateCtrl,
                                label: 'Hourly Rate (\₹)',
                                hint: 'e.g. 500',
                                keyboardType: TextInputType.number,
                                prefixIcon: Icons.currency_rupee_rounded,
                                textInputAction: TextInputAction.next,
                                validator: (v) => (v == null || v.isEmpty) ? 'Enter your rate' : null,
                              ),
                              const SizedBox(height: 14),
                              CustomTextField(
                                controller: _descriptionCtrl,
                                label: 'About Your Services',
                                hint: 'Briefly describe what you offer...',
                                maxLines: 3,
                                prefixIcon: Icons.description_outlined,
                                textInputAction: TextInputAction.done,
                                validator: (v) => (v == null || v.isEmpty) ? 'Enter a description' : null,
                              ),
                            ],
                          ]),
                          const SizedBox(height: 12),

                          // Location Selection
                          _card(children: [
                            Row(children: [
                              Icon(Icons.location_on_outlined, color: accentCol, size: 20),
                              const SizedBox(width: 8),
                              Text('Service Location', 
                                style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                            ]),
                            const SizedBox(height: 12),
                            if (_selectedLocation != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Text(
                                  _addressText ?? 'Location selected',
                                  style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary),
                                ),
                              ),
                            OutlinedButton.icon(
                              onPressed: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const LocationPickerMap()),
                                );
                                if (result != null && result is Map) {
                                  setState(() {
                                    _selectedLocation = result['location'];
                                    _addressText = result['address'];
                                  });
                                }
                              },
                              icon: const Icon(Icons.map_rounded, size: 18),
                              label: Text(_selectedLocation == null ? 'Select on Map' : 'Change Location'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: accentCol,
                                side: BorderSide(color: accentCol.withOpacity(0.5)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ]),
                          const SizedBox(height: 12),
                          _card(children: [
                            CustomTextField(
                              controller: _passCtrl,
                              label: 'Password',
                              hint: 'Min. 6 characters',
                              obscureText: _obscurePass,
                              prefixIcon: Icons.lock_outline_rounded,
                              textInputAction: TextInputAction.next,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePass
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: AppTheme.textSecondary,
                                  size: 20,
                                ),
                                onPressed: () => setState(
                                    () => _obscurePass = !_obscurePass),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty)
                                  return 'Enter a password';
                                if (v.length < 6)
                                  return 'At least 6 characters';
                                if (!RegExp(r'(?=.*[a-z])')
                                    .hasMatch(v.trim())) {
                                  return 'Must have a lowercase letter';
                                }
                                if (!RegExp(r'(?=.*[A-Z])')
                                    .hasMatch(v.trim())) {
                                  return 'Must have an uppercase letter';
                                }
                                if (!RegExp(r'(?=.*\d)').hasMatch(v.trim())) {
                                  return 'Must have a number';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),
                            CustomTextField(
                              controller: _confirmCtrl,
                              label: 'Confirm Password',
                              hint: 'Repeat your password',
                              obscureText: _obscureConfirm,
                              prefixIcon: Icons.lock_outline_rounded,
                              textInputAction: TextInputAction.done,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirm
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: AppTheme.textSecondary,
                                  size: 20,
                                ),
                                onPressed: () => setState(
                                    () => _obscureConfirm = !_obscureConfirm),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty)
                                  return 'Confirm your password';
                                if (v != _passCtrl.text)
                                  return 'Passwords do not match';
                                return null;
                              },
                            ),
                          ]),

                          const SizedBox(height: 16),

                          // Terms
                          GestureDetector(
                            onTap: () =>
                                setState(() => _agreeToTerms = !_agreeToTerms),
                            child: Row(children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: _agreeToTerms
                                      ? accentCol
                                      : AppTheme.navyElevated,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: _agreeToTerms
                                        ? accentCol
                                        : AppTheme.dividerColor,
                                    width: 1.5,
                                  ),
                                ),
                                child: _agreeToTerms
                                    ? const Icon(Icons.check,
                                        size: 14, color: Colors.white)
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text.rich(TextSpan(
                                  text: 'I agree to the ',
                                  style: GoogleFonts.inter(
                                      color: AppTheme.textSecondary,
                                      fontSize: 13),
                                  children: [
                                    TextSpan(
                                        text: 'Terms of Service',
                                        style: TextStyle(
                                            color: accentCol,
                                            fontWeight: FontWeight.w600)),
                                    const TextSpan(text: ' and '),
                                    TextSpan(
                                        text: 'Privacy Policy',
                                        style: TextStyle(
                                            color: accentCol,
                                            fontWeight: FontWeight.w600)),
                                  ],
                                )),
                              ),
                            ]),
                          ),

                          const SizedBox(height: 28),

                          CustomButton(
                            text: 'Create Account',
                            isGold: !_isProvider,
                            onPressed: auth.isLoading ? null : _register,
                            isLoading: auth.isLoading,
                          ),

                          const SizedBox(height: 20),

                          Wrap(
                              alignment: WrapAlignment.center,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text('Already have an account?',
                                    style: GoogleFonts.inter(
                                        color: AppTheme.textSecondary,
                                        fontSize: 14)),
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text('Sign In',
                                      style: GoogleFonts.inter(
                                          color: AppTheme.primaryColor,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14)),
                                ),
                              ]),
                          const SizedBox(height: 32),
                        ]),
                      ),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ]),
    );
  }

  Widget _card({required List<Widget> children}) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.navySurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.dividerColor, width: 1),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
      );
}

class _Orb extends StatelessWidget {
  final Color color;
  final double size;
  const _Orb({required this.color, required this.size});
  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient:
              RadialGradient(colors: [color.withAlpha(30), color.withAlpha(0)]),
        ),
      );
}
