import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../providers/auth_provider.dart';

class ProviderProfileTab extends ConsumerWidget {
  const ProviderProfileTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final provider = authState.currentProvider;

    if (provider == null) {
      return const Center(child: Text('Provider session not found.', style: TextStyle(color: Colors.white)));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Profile Avatar summary
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 46,
                  backgroundColor: AppColors.gold.withOpacity(0.12),
                  child: Text(
                    provider.name.substring(0, 1).toUpperCase(),
                    style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 36),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  provider.name,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                ),
                const SizedBox(height: 4),
                Text(
                  '${provider.category} — ${provider.skillLevel.toUpperCase()}',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        provider.approvalStatus.toUpperCase(),
                        style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 36),

          // Partner Statistics Grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.4,
            children: [
              _buildStatCard('Rating ⭐', '${provider.rating.toStringAsFixed(1)} / 5.0'),
              _buildStatCard('Jobs Completed ✅', '${provider.reviewCount} total'),
              _buildStatCard('On-Time Score ⏰', '${(provider.onTimeScore * 100).toStringAsFixed(0)}%'),
              _buildStatCard('Cancel Rate ❌', '${(provider.cancellationRate * 100).toStringAsFixed(0)}%'),
            ],
          ),
          const SizedBox(height: 36),

          // Actions List
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _buildActionRow(
                  icon: Icons.swap_horiz,
                  title: 'Switch to Customer Mode',
                  subtitle: 'Ghar ki services book karein',
                  onTap: () async {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Customer Mode switching triggered...')),
                    );
                    final success = await ref.read(authProvider.notifier).toggleUserMode();
                    if (success) {
                      context.go(AppRoutes.customerHome);
                    } else {
                      final error = ref.read(authProvider).error ?? 'Switching failed';
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed: $error'), backgroundColor: AppColors.error),
                      );
                    }
                  },
                ),
                const Divider(color: Colors.white10, height: 1),
                _buildActionRow(
                  icon: Icons.logout,
                  title: 'Logout Karo',
                  subtitle: 'Account se sign out karein',
                  titleColor: Colors.redAccent,
                  onTap: () async {
                    await ref.read(authProvider.notifier).logout();
                    context.go(AppRoutes.splash);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildActionRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color titleColor = Colors.white,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Icon(icon, color: titleColor == Colors.white ? AppColors.gold : titleColor),
      title: Text(title, style: TextStyle(color: titleColor, fontWeight: FontWeight.bold, fontSize: 14)),
      subtitle: Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
      trailing: const Icon(Icons.chevron_right, color: Colors.white24),
      onTap: onTap,
    );
  }
}
