import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/theme_provider.dart';
import '../../core/theme/theme_extensions.dart';

class ThemePickerDialog extends StatelessWidget {
  const ThemePickerDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: context.colors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.palette_outlined, color: context.colors.primary),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Chọn giao diện',
                    style: context.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildOption(
              context,
              title: 'Sáng',
              icon: Icons.light_mode_outlined,
              mode: ThemeMode.light,
              currentMode: themeProvider.themeMode,
            ),
            _buildOption(
              context,
              title: 'Tối',
              icon: Icons.dark_mode_outlined,
              mode: ThemeMode.dark,
              currentMode: themeProvider.themeMode,
            ),
            _buildOption(
              context,
              title: 'Theo hệ thống',
              icon: Icons.settings_brightness_outlined,
              mode: ThemeMode.system,
              currentMode: themeProvider.themeMode,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Đóng'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(
    BuildContext context, {
    required String title,
    required IconData icon,
    required ThemeMode mode,
    required ThemeMode currentMode,
  }) {
    final isSelected = mode == currentMode;
    
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      leading: Icon(
        icon,
        color: isSelected ? context.colors.primary : context.colors.onSurfaceVariant,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? context.colors.primary : context.colors.onSurface,
        ),
      ),
      trailing: isSelected 
        ? Icon(Icons.check_circle, color: context.colors.primary) 
        : null,
      onTap: () {
        context.read<ThemeProvider>().setThemeMode(mode);
        Navigator.pop(context);
      },
    );
  }
}
