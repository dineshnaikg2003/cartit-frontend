import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../providers/auth_provider.dart';
import '../../providers/address_provider.dart';
import '../../providers/theme_provider.dart';
import '../wishlist/wishlist_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final addressProvider = context.watch<AddressProvider>();

    final userPhone = authProvider.currentPhone ?? 'Customer';
    final userName = (authProvider.currentName != null && authProvider.currentName!.trim().isNotEmpty)
        ? authProvider.currentName!
        : 'CartIT Member';
    final savedAddressesCount = addressProvider.addresses.length;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.darkSurface : Colors.white;
    final borderColor = isDark ? AppColors.darkCardBorder : AppColors.border.withValues(alpha: 0.7);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: cardColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0.5,
        shadowColor: AppColors.cardShadow,
        titleSpacing: 20,
        title: Text(
          'My Profile',
          style: TextStyle(
            color: isDark ? AppColors.darkTitle : AppColors.title,
            fontWeight: FontWeight.w900,
            fontSize: 20,
            letterSpacing: -0.4,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 14),
            decoration: const BoxDecoration(
              color: AppColors.background,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.headset_mic_rounded, color: AppColors.title, size: 20),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Row(
                      children: [
                        Icon(Icons.support_agent_rounded, color: Colors.white, size: 18),
                        SizedBox(width: 8),
                        Text('Support active 24/7 at support@cartit.com'),
                      ],
                    ),
                    backgroundColor: AppColors.primary,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero User Card with Gradient Glassmorphism & Quick Stats Bar
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.28),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Decorative background accent circle
                  Positioned(
                    right: -20,
                    top: -20,
                    child: Container(
                      width: 130,
                      height: 130,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.06),
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.12),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Icon(Icons.person_rounded, size: 38, color: AppColors.primary),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          userName,
                                          style: const TextStyle(
                                            fontSize: 19,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.white,
                                            letterSpacing: -0.3,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      IconButton(
                                        constraints: const BoxConstraints(),
                                        padding: EdgeInsets.zero,
                                        icon: const Icon(Icons.edit_outlined, color: Colors.white, size: 18),
                                        onPressed: () => _showEditProfileDialog(context, authProvider, userName),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '+91 $userPhone',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.white.withValues(alpha: 0.85),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.18),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: Colors.white.withValues(alpha: 0.3),
                                      ),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.verified_rounded, size: 13, color: AppColors.secondary),
                                        SizedBox(width: 5),
                                        Text(
                                          'VERIFIED ACCOUNT',
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.white,
                                            letterSpacing: 0.6,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Section 1: Orders & Delivery
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                'YOUR ACCOUNT',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: AppColors.subtitle,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            Material(
              color: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.cardShadow.withValues(alpha: 0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildMenuItem(
                      context: context,
                      icon: Icons.shopping_bag_outlined,
                      iconColor: const Color(0xFF2563EB),
                      title: 'My Orders',
                      subtitle: 'Check order status & purchase history',
                      onTap: () => Navigator.pushNamed(context, AppRoutes.orderList),
                    ),
                    Divider(height: 1, indent: 62, color: borderColor),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.favorite_outline_rounded,
                      iconColor: const Color(0xFFE91E63),
                      title: 'My Wishlist',
                      subtitle: 'View and manage your saved items',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const WishlistScreen()),
                      ),
                    ),
                    Divider(height: 1, indent: 62, color: borderColor),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.location_on_outlined,
                      iconColor: const Color(0xFF16A34A),
                      title: 'Delivery Addresses',
                      subtitle: '$savedAddressesCount addresses saved for fast checkout',
                      onTap: () => Navigator.pushNamed(context, AppRoutes.addresses),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 22),

            // Section 2: Settings & Theme Preferences
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                'SETTINGS & PREFERENCES',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: isDark ? AppColors.darkSubtitle : AppColors.subtitle,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            Material(
              color: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.cardShadow.withValues(alpha: 0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Consumer<ThemeProvider>(
                  builder: (context, themeProvider, child) {
                    String themeLabel = 'System Auto';
                    if (themeProvider.themeMode == ThemeMode.dark) {
                      themeLabel = 'Dark Aurora';
                    } else if (themeProvider.themeMode == ThemeMode.light) {
                      themeLabel = 'Light';
                    }

                    return Column(
                      children: [
                        _buildMenuItem(
                          context: context,
                          icon: Icons.palette_outlined,
                          iconColor: const Color(0xFF6366F1),
                          title: 'App Theme',
                          subtitle: 'Theme: $themeLabel',
                          onTap: () => _showThemeSelectionModal(context, themeProvider),
                        ),
                        Divider(height: 1, indent: 62, color: borderColor),
                        _buildMenuItem(
                          context: context,
                          icon: Icons.notifications_none_rounded,
                          iconColor: const Color(0xFFEC4899),
                          title: 'Notifications',
                          subtitle: 'Manage order updates & promo alerts',
                          onTap: () {},
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 22),

            // Section 4: Support & Legal
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                'SUPPORT & LEGAL',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: isDark ? AppColors.darkSubtitle : AppColors.subtitle,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            Material(
              color: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.cardShadow.withValues(alpha: 0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildMenuItem(
                      context: context,
                      icon: Icons.help_outline_rounded,
                      iconColor: const Color(0xFF0D9488),
                      title: 'Help & Customer Support',
                      subtitle: '24/7 Instant assistance & FAQ',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Support available 24/7 at support@cartit.com'),
                            backgroundColor: AppColors.primary,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        );
                      },
                    ),
                    Divider(height: 1, indent: 62, color: borderColor),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.shield_outlined,
                      iconColor: const Color(0xFF475569),
                      title: 'Privacy & Terms',
                      subtitle: 'Security, privacy policy & terms of service',
                      onTap: () {},
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 28),

            // Logout Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      title: const Text(
                        'Logout',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                      content: const Text(
                        'Are you sure you want to log out of your CartIT account?',
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
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Logout'),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true && context.mounted) {
                    await authProvider.logout();
                    if (!context.mounted) return;
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      AppRoutes.login,
                      (route) => false,
                    );
                  }
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.error, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  backgroundColor: AppColors.error.withValues(alpha: 0.06),
                ),
                icon: const Icon(Icons.logout_rounded, color: AppColors.error, size: 20),
                label: const Text(
                  'Logout',
                  style: TextStyle(
                    color: AppColors.error,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 28),

            // Footer Version Info
            const Center(
              child: Column(
                children: [
                  Text(
                    'CartIT Store App • v1.0.0',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.subtitle,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Crafted for Instant E-Commerce',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.subtitle,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 14,
          color: isDark ? AppColors.darkTitle : AppColors.title,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: isDark ? AppColors.darkSubtitle : AppColors.subtitle,
          height: 1.2,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: isDark ? AppColors.darkSubtitle : AppColors.subtitle,
        size: 20,
      ),
      onTap: onTap,
    );
  }

  void _showEditProfileDialog(BuildContext context, AuthProvider authProvider, String currentName) {
    final controller = TextEditingController(text: currentName == 'CartIT Member' ? '' : currentName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Edit Profile', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter your full name to personalize your account:',
              style: TextStyle(fontSize: 12, color: AppColors.subtitle),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              textCapitalization: TextCapitalization.words,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Full Name',
                hintText: 'e.g. Dinesh Kumar',
                prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColors.primary),
                filled: true,
                fillColor: AppColors.background,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.8)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                await authProvider.updateProfile(name: newName);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Row(
                        children: [
                          Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                          SizedBox(width: 8),
                          Text('Profile name updated!'),
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
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showThemeSelectionModal(BuildContext context, ThemeProvider themeProvider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.palette_outlined, color: AppColors.primary, size: 24),
                const SizedBox(width: 10),
                const Text(
                  'Choose App Theme',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Select your visual appearance preference:',
              style: TextStyle(fontSize: 12, color: AppColors.subtitle),
            ),
            const SizedBox(height: 18),
            ListTile(
              leading: const Icon(Icons.brightness_auto_rounded, color: Color(0xFF6366F1)),
              title: const Text('System Auto', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Follow device system mode settings'),
              trailing: themeProvider.themeMode == ThemeMode.system
                  ? const Icon(Icons.check_circle_rounded, color: AppColors.primary)
                  : null,
              onTap: () {
                themeProvider.setThemeMode(ThemeMode.system);
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.dark_mode_rounded, color: Color(0xFF10B981)),
              title: const Text('Dark Aurora Theme', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Deep Emerald Aurora (Matched with Splash)'),
              trailing: themeProvider.themeMode == ThemeMode.dark
                  ? const Icon(Icons.check_circle_rounded, color: AppColors.primary)
                  : null,
              onTap: () {
                themeProvider.setThemeMode(ThemeMode.dark);
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.light_mode_rounded, color: Color(0xFFF59E0B)),
              title: const Text('Light Theme', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Clean white & emerald layout'),
              trailing: themeProvider.themeMode == ThemeMode.light
                  ? const Icon(Icons.check_circle_rounded, color: AppColors.primary)
                  : null,
              onTap: () {
                themeProvider.setThemeMode(ThemeMode.light);
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }
}
