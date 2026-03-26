import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final bool isDarkMode;

  const SettingsScreen({
    super.key,
    required this.onToggleTheme,
    required this.isDarkMode,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _enableReminders = true;
  bool _enableSmartMemory = true;
  bool _alarmAllowed = true;
  bool _calendarAllowed = false;

  User? get _user => FirebaseAuth.instance.currentUser;

  Future<void> _signOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Sign out?',
            style: TextStyle(color: _textPrimary, fontWeight: FontWeight.w700)),
        content: Text('You will be returned to the login screen.',
            style: TextStyle(color: _textSecondary, height: 1.4)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: _textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _accentBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await AuthService.signOut();
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  bool get _isDark => widget.isDarkMode;
  Color get _bgColor =>
      _isDark ? const Color(0xFF0F0F14) : AppColors.lightBackground;
  Color get _surfaceColor =>
      _isDark ? const Color(0xFF1A1A24) : AppColors.lightSurface;
  Color get _cardColor =>
      _isDark ? const Color(0xFF1E1E2A) : AppColors.lightCard;
  Color get _borderColor =>
      _isDark ? const Color(0xFF2A2A3A) : AppColors.lightBorder;
  Color get _textPrimary =>
      _isDark ? const Color(0xFFE8E8F0) : AppColors.lightText;
  Color get _textSecondary =>
      _isDark ? const Color(0xFF9090A8) : AppColors.lightSubtext;
  Color get _sectionLabel =>
      _isDark ? const Color(0xFF6060A0) : AppColors.primaryBlue;
  Color get _accentBlue =>
      _isDark ? const Color(0xFF3D7FFF) : AppColors.primaryBlue;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            _buildProfileCard(),
            const SizedBox(height: 28),
_buildSectionLabel('INTELLIGENCE PREFERENCES'),
            const SizedBox(height: 10),
            _buildPreferenceToggles(),
            const SizedBox(height: 28),
            _buildSectionLabel('UPCOMING REMINDERS'),
            const SizedBox(height: 10),
            _buildReminders(),
            const SizedBox(height: 28),
            _buildSectionLabel('IMPORTANT SAVED NOTES'),
            const SizedBox(height: 10),
            _buildSavedNotes(),
            const SizedBox(height: 28),
            _buildSectionLabel('SYSTEM PERMISSIONS'),
            const SizedBox(height: 10),
            _buildPermissions(),
            const SizedBox(height: 32),
            _buildDangerZone(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _bgColor,
      leading: IconButton(
        onPressed: () => Navigator.of(context).pop(),
        icon: Icon(Icons.arrow_back_ios_new_rounded,
            color: _textPrimary, size: 20),
      ),
      title: Text(
        'Assistant Settings',
        style: TextStyle(
            color: _textPrimary, fontSize: 18, fontWeight: FontWeight.w600),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          onPressed: () => _showOptionsMenu(context),
          icon: Icon(Icons.more_vert_rounded, color: _textSecondary, size: 22),
        ),
        const SizedBox(width: 4),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(height: 1, color: _borderColor),
      ),
    );
  }

  Widget _buildProfileCard() {
    final displayName = _user?.displayName ?? 'User';
    final email = _user?.email ?? '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _accentBlue, width: 2.5),
              color: _surfaceColor,
            ),
            child: _user?.photoURL != null
                ? ClipOval(
                    child: Image.network(
                      _user!.photoURL!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) =>
                          Icon(Icons.person_rounded, color: _accentBlue, size: 28),
                    ),
                  )
                : Icon(Icons.person_rounded, color: _accentBlue, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: TextStyle(
                    color: _textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  email,
                  style: TextStyle(color: _textSecondary, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _signOut,
            icon: Icon(Icons.logout_rounded, color: _textSecondary, size: 20),
            tooltip: 'Sign out',
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: _accentBlue,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: _sectionLabel,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildPreferenceToggles() {
    return Column(
      children: [
        _buildToggleTile(
          icon: Icons.notifications_active_outlined,
          iconColor: _accentBlue,
          title: 'Enable reminders',
          subtitle:
              'Allow the assistant to notify you about upcoming events and pending tasks.',
          value: _enableReminders,
          onChanged: (v) => setState(() => _enableReminders = v),
        ),
        const SizedBox(height: 10),
        _buildToggleTile(
          icon: Icons.psychology_outlined,
          iconColor: const Color(0xFFB06BFF),
          title: 'Enable smart memory',
          subtitle:
              'Assistant learns your preferences over time to provide better context.',
          value: _enableSmartMemory,
          onChanged: (v) => setState(() => _enableSmartMemory = v),
        ),
      ],
    );
  }

  Widget _buildToggleTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _borderColor, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        color: _textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 3),
                Text(subtitle,
                    style: TextStyle(
                        color: _textSecondary, fontSize: 12.5, height: 1.4)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: _accentBlue,
            inactiveThumbColor: _textSecondary,
            inactiveTrackColor: _borderColor,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }

  Widget _buildReminders() {
    return Column(
      children: [
        _buildReminderTile(
          icon: Icons.group_rounded,
          iconColor: const Color(0xFF4CA3FF),
          title: 'Weekly Sync',
          subtitle: 'Monday, 10:00 AM',
        ),
        const SizedBox(height: 10),
        _buildReminderTile(
          icon: Icons.restaurant_menu_rounded,
          iconColor: const Color(0xFFFF9044),
          title: 'Lunch with Alex',
          subtitle: 'Today, 12:30 PM',
        ),
      ],
    );
  }

  Widget _buildReminderTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _borderColor, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        color: _textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: TextStyle(color: _textSecondary, fontSize: 13)),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: _textSecondary, size: 20),
        ],
      ),
    );
  }

  Widget _buildSavedNotes() {
    return Column(
      children: [
        _buildNoteTile(
          title: 'Project X Goals',
          body: 'Finish the wireframes for the new settings dashboard and sync with the dev team about...',
          badge: 'HIGH PRIORITY',
          badgeColor: AppColors.dangerRed,
        ),
        const SizedBox(height: 10),
        _buildNoteTile(
          title: 'Gift ideas for Sarah',
          body: 'Consider that mechanical keyboard she mentioned last month or a subscription to that...',
          badge: 'PERSONAL',
          badgeColor: _textSecondary,
        ),
      ],
    );
  }

  Widget _buildNoteTile({
    required String title,
    required String body,
    required String badge,
    required Color badgeColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(title,
                    style: TextStyle(
                        color: _textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600)),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                      color: badgeColor.withValues(alpha: 0.4), width: 1),
                ),
                child: Text(badge,
                    style: TextStyle(
                        color: badgeColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(body,
              style: TextStyle(
                  color: _textSecondary, fontSize: 13, height: 1.45),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildPermissions() {
    return Column(
      children: [
        _buildPermissionTile(
          icon: Icons.alarm_rounded,
          iconColor: const Color(0xFFFF9044),
          title: 'Alarm',
          subtitle: 'System clock access',
          allowed: _alarmAllowed,
          onTap: () => setState(() => _alarmAllowed = !_alarmAllowed),
        ),
        const SizedBox(height: 10),
        _buildPermissionTile(
          icon: Icons.calendar_month_rounded,
          iconColor: _accentBlue,
          title: 'Calendar',
          subtitle: 'Events & scheduling',
          allowed: _calendarAllowed,
          onTap: () => setState(() => _calendarAllowed = !_calendarAllowed),
        ),
      ],
    );
  }

  Widget _buildPermissionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool allowed,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _borderColor, width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          color: _textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style:
                          TextStyle(color: _textSecondary, fontSize: 13)),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: allowed
                    ? AppColors.successGreen.withValues(alpha: 0.15)
                    : _surfaceColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: allowed
                      ? AppColors.successGreen.withValues(alpha: 0.4)
                      : _borderColor,
                  width: 1,
                ),
              ),
              child: Text(
                allowed ? 'Allowed' : 'Not Allowed',
                style: TextStyle(
                    color: allowed
                        ? AppColors.successGreen
                        : _textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDangerZone() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.dangerRed.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppColors.dangerRed.withValues(alpha: 0.25), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded,
                  color: AppColors.dangerRed.withValues(alpha: 0.8), size: 20),
              const SizedBox(width: 8),
              Text('Danger Zone',
                  style: TextStyle(
                      color: _textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Removing your data is permanent and cannot be undone. This includes conversation history, preferences, and smart memory.',
            style: TextStyle(
                color: _textSecondary, fontSize: 13, height: 1.45),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () => _showDeleteConfirmation(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.dangerRed,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.delete_outline_rounded, size: 18),
              label: const Text('Delete all data',
                  style:
                      TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  void _showOptionsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: _borderColor,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.dark_mode_rounded, color: _textSecondary),
              title: Text(
                widget.isDarkMode
                    ? 'Switch to Light Mode'
                    : 'Switch to Dark Mode',
                style: TextStyle(color: _textPrimary),
              ),
              onTap: () {
                Navigator.pop(context);
                widget.onToggleTheme();
              },
            ),
            ListTile(
              leading: Icon(Icons.share_rounded, color: _textSecondary),
              title:
                  Text('Export data', style: TextStyle(color: _textPrimary)),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading:
                  Icon(Icons.help_outline_rounded, color: _textSecondary),
              title: Text('Help & Support',
                  style: TextStyle(color: _textPrimary)),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: Icon(Icons.logout_rounded,
                  color: AppColors.dangerRed.withValues(alpha: 0.8)),
              title: Text('Sign Out',
                  style: TextStyle(
                      color: AppColors.dangerRed.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(context);
                _signOut();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _cardColor,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete all data?',
            style: TextStyle(
                color: _textPrimary, fontWeight: FontWeight.w700)),
        content: Text(
          'This action cannot be undone. All conversations, preferences, and memory will be permanently removed.',
          style: TextStyle(color: _textSecondary, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: TextStyle(color: _textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.dangerRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
