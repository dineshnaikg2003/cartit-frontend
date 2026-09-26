import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../app/app_colors.dart';
import '../../models/address_model.dart';
import '../../providers/address_provider.dart';
import '../../providers/auth_provider.dart';
import '../address/location_picker_screen.dart';

class AddressFormDialog extends StatefulWidget {
  final Map<String, String>? initialLocation;
  final AddressModel? initialAddress;

  const AddressFormDialog({
    super.key,
    this.initialLocation,
    this.initialAddress,
  });

  @override
  State<AddressFormDialog> createState() => _AddressFormDialogState();
}

class _AddressFormDialogState extends State<AddressFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _houseNoController = TextEditingController();
  final _buildingController = TextEditingController();
  final _landmarkController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  final bool _isDefault = true;
  String _selectedTag = 'Home'; // Home, Work, Other

  String _areaTitle = '';
  String _subAddress = '';
  String _city = '';
  String _state = '';
  String _pincode = '';
  double? _latitude;
  double? _longitude;

  @override
  void initState() {
    super.initState();
    final authProvider = context.read<AuthProvider>();

    if (widget.initialAddress != null) {
      final addr = widget.initialAddress!;
      _nameController.text = addr.fullName;
      _phoneController.text = addr.phone;
      _houseNoController.text = addr.street;
      _city = addr.city;
      _state = addr.state;
      _pincode = addr.zipCode;
      _latitude = addr.latitude;
      _longitude = addr.longitude;
      _areaTitle = '${addr.city}, ${addr.state}';
      _subAddress = addr.street;
    } else {
      if (authProvider.currentName != null && authProvider.currentName!.trim().isNotEmpty) {
        _nameController.text = authProvider.currentName!;
      }
      if (authProvider.currentPhone != null && authProvider.currentPhone!.trim().isNotEmpty) {
        _phoneController.text = authProvider.currentPhone!;
      }
    }

    if (widget.initialLocation != null) {
      _applyLocationData(widget.initialLocation!);
    }
  }

  void _applyLocationData(Map<String, String> data) {
    setState(() {
      _areaTitle = data['areaTitle'] ?? data['street'] ?? 'Selected Area';
      _subAddress = data['displayAddress'] ?? data['street'] ?? '';
      _city = data['city'] ?? '';
      _state = data['state'] ?? '';
      _pincode = data['zipCode'] ?? '';

      if (data['latitude'] != null) _latitude = double.tryParse(data['latitude']!);
      if (data['longitude'] != null) _longitude = double.tryParse(data['longitude']!);
    });
  }

  @override
  void dispose() {
    _houseNoController.dispose();
    _buildingController.dispose();
    _landmarkController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _changeLocation() async {
    final initialPos = (_latitude != null && _longitude != null && _latitude != 0.0 && _longitude != 0.0)
        ? LatLng(_latitude!, _longitude!)
        : null;

    final result = await Navigator.push<Map<String, String>>(
      context,
      MaterialPageRoute(builder: (_) => LocationPickerScreen(initialPosition: initialPos)),
    );

    if (result != null && mounted) {
      _applyLocationData(result);
    }
  }

  void _onSave() async {
    if (!_formKey.currentState!.validate()) return;

    if (_latitude == null || _longitude == null || _latitude == 0.0 || _longitude == 0.0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select location on map to confirm exact delivery GPS coordinates'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final addressProvider = context.read<AddressProvider>();

    // Build complete street text from house no, building & landmark
    List<String> streetParts = [];
    if (_houseNoController.text.trim().isNotEmpty) {
      streetParts.add(_houseNoController.text.trim());
    }
    if (_buildingController.text.trim().isNotEmpty) {
      streetParts.add(_buildingController.text.trim());
    }
    if (_landmarkController.text.trim().isNotEmpty) {
      streetParts.add(_landmarkController.text.trim());
    }
    if (_subAddress.isNotEmpty) {
      streetParts.add(_subAddress);
    }

    final combinedStreet = streetParts.join(', ');

    final authProvider = context.read<AuthProvider>();
    final defaultFullName = (authProvider.currentName != null && authProvider.currentName!.trim().isNotEmpty)
        ? authProvider.currentName!
        : 'Customer';
    final defaultPhone = (authProvider.currentPhone != null && authProvider.currentPhone!.trim().isNotEmpty)
        ? authProvider.currentPhone!
        : '9876543210';

    final isEditing = widget.initialAddress != null;
    final address = AddressModel(
      id: isEditing ? widget.initialAddress!.id : 0,
      fullName: _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : defaultFullName,
      phone: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : defaultPhone,
      street: combinedStreet.isNotEmpty ? combinedStreet : _areaTitle,
      city: _city.isNotEmpty ? _city : 'Bengaluru',
      state: _state.isNotEmpty ? _state : 'Karnataka',
      zipCode: _pincode.isNotEmpty ? _pincode : '560001',
      country: 'India',
      isDefault: isEditing ? widget.initialAddress!.isDefault : _isDefault,
      latitude: _latitude,
      longitude: _longitude,
    );

    final success = isEditing
        ? await addressProvider.updateAddress(address)
        : await addressProvider.addAddress(address);

    if (mounted) {
      if (success) {
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(addressProvider.errorMessage ?? 'Failed to save address'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  InputDecoration _buildInputDecoration({
    required String hint,
    required bool isDark,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: isDark ? AppColors.darkSubtitle : AppColors.subtitle.withValues(alpha: 0.7),
        fontSize: 13,
      ),
      filled: true,
      fillColor: isDark ? AppColors.darkBackground : Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: isDark ? AppColors.darkCardBorder : AppColors.border.withValues(alpha: 0.8)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: isDark ? AppColors.darkCardBorder : AppColors.border.withValues(alpha: 0.8)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final addressProvider = context.watch<AddressProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBgColor = isDark ? AppColors.darkSurface : Colors.white;
    final borderColor = isDark ? AppColors.darkCardBorder : AppColors.border;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        decoration: BoxDecoration(
          color: cardBgColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.26),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top App Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 18,
                      color: isDark ? AppColors.darkTitle : AppColors.title,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Add Address Details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: isDark ? AppColors.darkTitle : AppColors.title,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: borderColor),

            // Form Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Pinned Location Summary Header Card (Zomato / Blinkit Style)
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkBackground : AppColors.background,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isDark ? AppColors.darkCardBorder : AppColors.border.withValues(alpha: 0.7)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight.withValues(alpha: isDark ? 0.2 : 1.0),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _areaTitle.isNotEmpty ? _areaTitle : 'Pinned Delivery Area',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w900,
                                      color: isDark ? AppColors.darkTitle : AppColors.title,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _subAddress.isNotEmpty ? _subAddress : 'Exact GPS location set',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? AppColors.darkSubtitle : AppColors.subtitle,
                                      height: 1.25,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton(
                              onPressed: _changeLocation,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                side: const BorderSide(color: AppColors.primary, width: 1.2),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text(
                                'Change',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Section Title 1: Add Address
                      const Text(
                        'Add address',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: AppColors.title,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // House No. & Floor
                      TextFormField(
                        controller: _houseNoController,
                        textCapitalization: TextCapitalization.words,
                        style: TextStyle(
                          color: isDark ? AppColors.darkTitle : AppColors.title,
                          fontSize: 14,
                        ),
                        decoration: _buildInputDecoration(
                          hint: 'House No. & Floor',
                          isDark: isDark,
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Enter house no. & floor' : null,
                      ),
                      const SizedBox(height: 12),

                      // Building & Block No. (Optional)
                      TextFormField(
                        controller: _buildingController,
                        textCapitalization: TextCapitalization.words,
                        style: TextStyle(
                          color: isDark ? AppColors.darkTitle : AppColors.title,
                          fontSize: 14,
                        ),
                        decoration: _buildInputDecoration(
                          hint: 'Building & Block No. (Optional)',
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Landmark & Area Name (Optional)
                      TextFormField(
                        controller: _landmarkController,
                        textCapitalization: TextCapitalization.words,
                        style: TextStyle(
                          color: isDark ? AppColors.darkTitle : AppColors.title,
                          fontSize: 14,
                        ),
                        decoration: _buildInputDecoration(
                          hint: 'Landmark & Area Name (Optional)',
                          isDark: isDark,
                        ),
                      ),

                      const SizedBox(height: 22),

                      // Section Title 2: Add address label
                      Text(
                        'Add address label',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: isDark ? AppColors.darkTitle : AppColors.title,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Save Address As Chips (Home, Work, Other)
                      Row(
                        children: ['Home', 'Work', 'Other'].map((tag) {
                          final selected = _selectedTag == tag;
                          IconData tagIcon;
                          if (tag == 'Home') {
                            tagIcon = Icons.home_rounded;
                          } else if (tag == 'Work') {
                            tagIcon = Icons.work_rounded;
                          } else {
                            tagIcon = Icons.location_on_rounded;
                          }

                          final chipTextCol = selected
                              ? Colors.white
                              : (isDark ? AppColors.darkTitle : AppColors.title);

                          return Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: ChoiceChip(
                              showCheckmark: false,
                              avatar: Icon(
                                tagIcon,
                                size: 16,
                                color: chipTextCol,
                              ),
                              label: Text(
                                tag,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: chipTextCol,
                                ),
                              ),
                              selected: selected,
                              selectedColor: AppColors.primary,
                              backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
                              side: BorderSide(
                                color: selected
                                    ? AppColors.primary
                                    : (isDark ? AppColors.darkCardBorder : AppColors.border),
                              ),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              onSelected: (val) {
                                if (val) setState(() => _selectedTag = tag);
                              },
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 22),

                      // Section Title 3: Receiver details
                      Text(
                        'Receiver details',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: isDark ? AppColors.darkTitle : AppColors.title,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Receiver's Name
                      TextFormField(
                        controller: _nameController,
                        textCapitalization: TextCapitalization.words,
                        style: TextStyle(
                          color: isDark ? AppColors.darkTitle : AppColors.title,
                          fontSize: 14,
                        ),
                        decoration: _buildInputDecoration(
                          hint: "Receiver's Name",
                          isDark: isDark,
                        ).copyWith(
                          suffixIcon: Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: Icon(
                              Icons.import_contacts_rounded,
                              color: isDark ? AppColors.darkTitle : AppColors.title,
                              size: 20,
                            ),
                          ),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? "Enter receiver's name" : null,
                      ),
                      const SizedBox(height: 12),

                      // Receiver's Phone Number
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        maxLength: 10,
                        style: TextStyle(
                          color: isDark ? AppColors.darkTitle : AppColors.title,
                          fontSize: 14,
                        ),
                        decoration: _buildInputDecoration(
                          hint: "Receiver's Phone Number",
                          isDark: isDark,
                        ).copyWith(
                          counterText: '',
                          prefixIcon: Container(
                            width: 60,
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '+91',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? AppColors.darkTitle : AppColors.title,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                SizedBox(
                                  height: 16,
                                  child: VerticalDivider(
                                    width: 1,
                                    color: isDark ? AppColors.darkCardBorder : AppColors.border,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return "Enter receiver's phone number";
                          final trimmed = v.trim();
                          if (!RegExp(r'^[6-9]\d{9}$').hasMatch(trimmed)) {
                            return 'Enter valid 10-digit mobile number';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 30),

                      // CTA Button: SAVE ADDRESS
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: addressProvider.isLoading ? null : _onSave,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: addressProvider.isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                )
                              : const Text(
                                  'SAVE ADDRESS',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
