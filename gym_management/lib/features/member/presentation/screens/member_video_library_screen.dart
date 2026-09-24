import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gym_management/core/theme/app_theme.dart';
import 'package:gym_management/features/member/providers/workout_provider.dart';
import 'package:gym_management/features/shared/video_player_screen.dart';

class MemberVideoLibraryScreen extends ConsumerStatefulWidget {
  const MemberVideoLibraryScreen({super.key});

  @override
  ConsumerState<MemberVideoLibraryScreen> createState() =>
      _MemberVideoLibraryScreenState();
}

class _MemberVideoLibraryScreenState
    extends ConsumerState<MemberVideoLibraryScreen> {
  String _search = '';
  final _searchCtrl = TextEditingController();

  final List<String> _muscleGroups = [
    'All',
    'Chest',
    'Back',
    'Legs',
    'Shoulders',
    'Arms',
    'Core',
    'Cardio',
    'Full Body',
  ];
  String _selectedGroup = 'All';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final libraryAsync = ref.watch(memberExerciseLibraryProvider);

    return Scaffold(
      backgroundColor: AppTheme.scaffoldDark,
      appBar: AppBar(
        title: const Text('Video Library'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                hintText: 'Search videos...',
                hintStyle: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                ),
                filled: true,
                fillColor: AppTheme.cardDark,
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppTheme.textSecondary,
                  size: 20,
                ),
                suffixIcon: _search.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Icons.clear_rounded,
                          color: AppTheme.textSecondary,
                          size: 18,
                        ),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _search = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.borderDark),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.borderDark),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppTheme.primaryColor,
                    width: 1.5,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
              ),
              onChanged: (v) => setState(() => _search = v.toLowerCase()),
            ),
          ),

          // Filter chips
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _muscleGroups.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final g = _muscleGroups[i];
                final isSelected = _selectedGroup == g;
                return ChoiceChip(
                  label: Text(g),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _selectedGroup = g),
                  backgroundColor: AppTheme.cardDark,
                  selectedColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                  labelStyle: TextStyle(
                    color: isSelected
                        ? AppTheme.primaryColor
                        : AppTheme.textSecondary,
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                  side: BorderSide(
                    color: isSelected
                        ? AppTheme.primaryColor
                        : AppTheme.borderDark,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          // Videos grid
          Expanded(
            child: libraryAsync.when(
              data: (exercises) {
                // Apply filters (only show videos with valid URL)
                final filtered = exercises.where((ex) {
                  final hasVideoUrl = ex['video_url'] != null &&
                      ex['video_url'].toString().isNotEmpty;
                  if (!hasVideoUrl) return false;

                  final matchGroup = _selectedGroup == 'All' ||
                      (ex['muscle_group'] ?? '') == _selectedGroup;
                  final matchSearch = _search.isEmpty ||
                      (ex['name'] ?? '').toString().toLowerCase().contains(
                            _search,
                          );
                  return matchGroup && matchSearch;
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.video_library_outlined,
                          size: 64,
                          color: AppTheme.textSecondary,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No videos found',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) => _buildVideoCard(filtered[i]),
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (e, _) => Center(
                child: Text(
                  'Error loading videos: $e',
                  style: const TextStyle(color: AppTheme.errorColor),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoCard(Map<String, dynamic> exercise) {
    final name = exercise['name'] ?? 'Video';
    final group = exercise['muscle_group'] ?? 'General';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VideoPlayerScreen(
              videoUrl: exercise['video_url'],
              title: name,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderDark),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Thumbnail
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      color: Colors.black12,
                      child: const Center(
                        child: Icon(
                          Icons.play_circle_filled_rounded,
                          size: 48,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          group,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                name,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
