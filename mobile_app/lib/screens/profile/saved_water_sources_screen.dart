import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_typography.dart';
import '../../providers/saved_sources_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/water_source_card.dart';
import '../water_source_details_screen.dart';

class SavedWaterSourcesScreen extends ConsumerWidget {
  const SavedWaterSourcesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedSources = ref.watch(savedWaterSourcesProvider);

    return Scaffold(
      backgroundColor: AppColors.mainBackground,
      appBar: AppBar(
        title: const Text('Saved Water Sources'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.primaryText,
      ),
      body: SafeArea(
        child: savedSources.isEmpty
            ? EmptyState(
                icon: Icons.bookmark_border_rounded,
                title: 'No Saved Sources',
                message: 'Bookmark critical water sources on the map or dashboard to monitor them here.',
                buttonText: 'Explore Map',
                onButtonPressed: () => Navigator.pop(context),
              )
            : SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${savedSources.length} Monitored Water Sources',
                      style: AppTypography.sectionHeading.copyWith(fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    ...savedSources.map((source) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Dismissible(
                          key: ValueKey(source.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            decoration: BoxDecoration(
                              color: AppColors.statusAttentionBg,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Icon(
                              Icons.bookmark_remove_rounded,
                              color: AppColors.statusAttention,
                            ),
                          ),
                          onDismissed: (_) {
                            ref
                                .read(savedSourceIdsProvider.notifier)
                                .toggleBookmark(source.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Removed ${source.name} from saved sources.'),
                              ),
                            );
                          },
                          child: WaterSourceCard(
                            source: source,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => WaterSourceDetailsScreen(
                                    waterSource: source,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
      ),
    );
  }
}
