import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/animations/animations.dart';
import '../providers/home_tank_providers.dart';
import '../widgets/home_tank_card.dart';
import 'register_tank_screen.dart';

class MyHomeTanksScreen extends ConsumerStatefulWidget {
  const MyHomeTanksScreen({super.key});

  @override
  ConsumerState<MyHomeTanksScreen> createState() => _MyHomeTanksScreenState();
}

class _MyHomeTanksScreenState extends ConsumerState<MyHomeTanksScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tanksAsync = ref.watch(userHomeTanksStreamProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.mainBackground,
      appBar: AppBar(
        title: const Text('My Home Water Tanks', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
        backgroundColor: isDark ? AppColors.darkCardBackground : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Add Home Tank',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (ctx) => const RegisterTankScreen()),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryDeepOcean,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Home Tank', style: TextStyle(fontWeight: FontWeight.w700)),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (ctx) => const RegisterTankScreen()),
          );
        },
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Privacy Assurance Ribbon
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: const Color(0xFF0F766E).withValues(alpha: isDark ? 0.2 : 0.08),
              child: const Row(
                children: [
                  Icon(Icons.shield_rounded, size: 16, color: AppColors.teal),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'All tanks listed below are strictly private to your account and hidden from community maps.',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.teal,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Tanks List
            Expanded(
              child: tanksAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.teal),
                ),
                error: (e, _) => Center(
                  child: Text('Error loading home tanks: $e'),
                ),
                data: (allTanks) {
                  if (allTanks.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: AppColors.primaryAqua.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.water_drop_rounded,
                                size: 48,
                                color: AppColors.primaryDeepOcean,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No Home Tanks Registered',
                              style: (isDark ? AppTypography.darkCardTitle : AppTypography.cardTitle)
                                  .copyWith(fontSize: 17, fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Deploy the AquaGuard IoT sensor node in your overhead or underground water tank to privately monitor water quality.',
                              textAlign: TextAlign.center,
                              style: (isDark ? AppTypography.darkSecondary : AppTypography.secondary)
                                  .copyWith(fontSize: 13, height: 1.4),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.add_rounded),
                              label: const Text('Register First Home Tank'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryDeepOcean,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (ctx) => const RegisterTankScreen()),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return RefreshIndicator(
                    color: AppColors.teal,
                    onRefresh: () async {
                      ref.invalidate(userHomeTanksStreamProvider);
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.only(top: 8, bottom: 85),
                      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                      itemCount: allTanks.length,
                      itemBuilder: (context, index) {
                        final tank = allTanks[index];
                        return FadeSlideEntrance(
                          index: index,
                          child: HomeTankCard(
                            tank: tank,
                            onRefresh: () {
                              ref.invalidate(userHomeTanksStreamProvider);
                            },
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
