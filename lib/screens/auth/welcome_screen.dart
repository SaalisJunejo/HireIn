import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(height: 20),
              
              // App Logo and Branding
              Column(
                children: [
                  const Icon(
                    Icons.work_outline,
                    size: 80,
                    color: AppColors.gold,
                  ).animate().scale(delay: 200.ms, duration: 600.ms, curve: Curves.easeOutBack),
                  const SizedBox(height: 16),
                  const Text(
                    'HireIn',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      color: AppColors.gold,
                      letterSpacing: 1.5,
                    ),
                  ).animate().fadeIn(delay: 300.ms, duration: 500.ms),
                  const SizedBox(height: 8),
                  const Text(
                    'Pakistan ka Smart Service App',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ).animate().fadeIn(delay: 550.ms, duration: 500.ms),
                ],
              ),

              // Onboarding Mode Selection Card
              Column(
                children: [
                  const Text(
                    'Aap kis tarah join karna chahte hain?',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ).animate().fadeIn(delay: 700.ms),
                  const SizedBox(height: 20),
                  
                  // Customer Option
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      foregroundColor: AppColors.primary,
                      minimumSize: const Size(double.infinity, 60),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 6,
                    ),
                    onPressed: () => context.push(AppRoutes.customerLogin),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search, size: 24),
                        SizedBox(width: 12),
                        Text(
                          'Mujhe Service Chahiye',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ).animate().slideY(begin: 0.3, delay: 800.ms, curve: Curves.easeOutQuad).fadeIn(),
                  const SizedBox(height: 16),
                  
                  // Provider Option
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.gold,
                      side: const BorderSide(color: AppColors.gold, width: 2),
                      minimumSize: const Size(double.infinity, 60),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () => context.push(AppRoutes.providerLogin),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.handyman, size: 24),
                        SizedBox(width: 12),
                        Text(
                          'Main Service Provider Hoon',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ).animate().slideY(begin: 0.4, delay: 900.ms, curve: Curves.easeOutQuad).fadeIn(),
                ],
              ),

              // Bottom Admin Link
              GestureDetector(
                onTap: () => context.push(AppRoutes.adminLogin),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.0),
                  child: Text(
                    'Admin Login',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 1100.ms),
            ],
          ),
        ),
      ),
    );
  }
}
