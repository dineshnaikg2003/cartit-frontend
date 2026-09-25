import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/app_colors.dart';
import '../../providers/address_provider.dart';
import '../address/location_picker_screen.dart';
import '../checkout/address_form_dialog.dart';

class AddressListScreen extends StatefulWidget {
  const AddressListScreen({super.key});

  @override
  State<AddressListScreen> createState() => _AddressListScreenState();
}

class _AddressListScreenState extends State<AddressListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AddressProvider>().fetchAddresses();
    });
  }

  @override
  Widget build(BuildContext context) {
    final addressProvider = context.watch<AddressProvider>();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBgColor = isDark ? AppColors.darkSurface : Colors.white;
    final borderColor = isDark ? AppColors.darkCardBorder : AppColors.border.withValues(alpha: 0.7);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: cardBgColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0.5,
        shadowColor: AppColors.cardShadow,
        titleSpacing: 16,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDark ? AppColors.darkTitle : AppColors.title,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Saved Addresses',
              style: TextStyle(
                color: isDark ? AppColors.darkTitle : AppColors.title,
                fontWeight: FontWeight.w900,
                fontSize: 18,
                letterSpacing: -0.3,
              ),
            ),
            Text(
              'Manage your delivery locations',
              style: TextStyle(
                color: isDark ? AppColors.darkSubtitle : AppColors.subtitle,
                fontWeight: FontWeight.w500,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final locationResult = await Navigator.push<Map<String, String>>(
            context,
            MaterialPageRoute(builder: (_) => const LocationPickerScreen()),
          );

          if (locationResult != null && context.mounted) {
            final added = await showDialog<bool>(
              context: context,
              builder: (_) => AddressFormDialog(initialLocation: locationResult),
            );
            if (added == true && context.mounted) {
              context.read<AddressProvider>().fetchAddresses();
            }
          }
        },
        backgroundColor: AppColors.primary,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.add_location_alt_rounded, color: Colors.white, size: 20),
        label: const Text(
          'Add New Address',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 14,
            letterSpacing: 0.2,
          ),
        ),
      ),
      body: addressProvider.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : addressProvider.addresses.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                  itemCount: addressProvider.addresses.length,
                  itemBuilder: (context, index) {
                    final address = addressProvider.addresses[index];
                    final hasCoordinates = address.latitude != null && address.longitude != null;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: cardBgColor,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: address.isDefault
                              ? AppColors.primary
                              : borderColor,
                          width: address.isDefault ? 1.8 : 1.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: address.isDefault
                                ? AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.08)
                                : AppColors.cardShadow.withValues(alpha: isDark ? 0.2 : 0.06),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () async {
                            if (!address.isDefault) {
                              await addressProvider.setDefaultAddress(address.id);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Row(
                                      children: [
                                        Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                                        SizedBox(width: 8),
                                        Text('Default delivery address updated'),
                                      ],
                                    ),
                                    backgroundColor: AppColors.success,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              }
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Top Header Row
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      child: Wrap(
                                        spacing: 6,
                                        runSpacing: 6,
                                        crossAxisAlignment: WrapCrossAlignment.center,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                            decoration: BoxDecoration(
                                              color: address.isDefault
                                                  ? (isDark ? AppColors.primary.withValues(alpha: 0.18) : AppColors.primaryLight)
                                                  : (isDark ? Colors.white.withValues(alpha: 0.05) : AppColors.background),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(
                                                color: address.isDefault
                                                    ? AppColors.primary.withValues(alpha: 0.35)
                                                    : (isDark ? AppColors.darkCardBorder : AppColors.border),
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  address.isDefault
                                                      ? Icons.check_circle_rounded
                                                      : Icons.radio_button_unchecked_rounded,
                                                  size: 14,
                                                  color: address.isDefault
                                                      ? AppColors.primary
                                                      : (isDark ? AppColors.darkSubtitle : AppColors.subtitle),
                                                ),
                                                const SizedBox(width: 5),
                                                Text(
                                                  address.isDefault ? 'DEFAULT DELIVER TO' : 'SET AS DEFAULT',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w900,
                                                    color: address.isDefault
                                                        ? AppColors.primary
                                                        : (isDark ? AppColors.darkSubtitle : AppColors.subtitle),
                                                    letterSpacing: 0.3,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (hasCoordinates)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                              decoration: BoxDecoration(
                                                color: isDark ? Colors.blue.withValues(alpha: 0.15) : Colors.blue.shade50,
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.pin_drop_rounded,
                                                    size: 13,
                                                    color: isDark ? const Color(0xFF60A5FA) : Colors.blue.shade700,
                                                  ),
                                                  const SizedBox(width: 3),
                                                  Text(
                                                    'GPS Pinned',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.w800,
                                                      color: isDark ? const Color(0xFF60A5FA) : Colors.blue.shade700,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          constraints: const BoxConstraints(),
                                          padding: EdgeInsets.zero,
                                          icon: const Icon(
                                            Icons.edit_outlined,
                                            color: AppColors.primary,
                                            size: 20,
                                          ),
                                          onPressed: () async {
                                            final updated = await showDialog<bool>(
                                              context: context,
                                              builder: (_) => AddressFormDialog(initialAddress: address),
                                            );
                                            if (updated == true && mounted) {
                                              addressProvider.fetchAddresses();
                                            }
                                          },
                                        ),
                                        const SizedBox(width: 10),
                                        IconButton(
                                          constraints: const BoxConstraints(),
                                          padding: EdgeInsets.zero,
                                          icon: const Icon(
                                            Icons.delete_outline_rounded,
                                            color: AppColors.error,
                                            size: 20,
                                          ),
                                          onPressed: () async {
                                            final confirm = await showDialog<bool>(
                                              context: context,
                                              builder: (ctx) => AlertDialog(
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                                                title: const Text(
                                                  'Delete Address',
                                                  style: TextStyle(fontWeight: FontWeight.w800),
                                                ),
                                                content: const Text(
                                                  'Are you sure you want to remove this delivery address?',
                                                  style: TextStyle(color: AppColors.subtitle),
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () => Navigator.pop(ctx, false),
                                                    child: const Text('Cancel'),
                                                  ),
                                                  ElevatedButton(
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: AppColors.error,
                                                      foregroundColor: Colors.white,
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.circular(10),
                                                      ),
                                                    ),
                                                    onPressed: () => Navigator.pop(ctx, true),
                                                    child: const Text('Delete'),
                                                  ),
                                                ],
                                              ),
                                            );
                                            if (confirm == true && mounted) {
                                              await addressProvider.deleteAddress(address.id);
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),

                                // Contact & Location details
                                Text(
                                  address.fullName,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: isDark ? AppColors.darkTitle : AppColors.title,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  address.street,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark ? AppColors.darkTitle : AppColors.title,
                                    fontWeight: FontWeight.w500,
                                    height: 1.35,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${address.city}, ${address.state} - ${address.zipCode}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? AppColors.darkSubtitle : AppColors.subtitle,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Divider(height: 1, color: isDark ? AppColors.darkCardBorder : AppColors.border.withValues(alpha: 0.6)),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.phone_in_talk_rounded,
                                      size: 14,
                                      color: isDark ? AppColors.primary : AppColors.subtitle,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '+91 ${address.phone}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: isDark ? AppColors.darkTitle : AppColors.title,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: const BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.location_off_rounded,
                size: 48,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'No Saved Addresses',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppColors.title,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add delivery addresses to place orders in one tap.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.subtitle),
            ),
          ],
        ),
      ),
    );
  }
}
