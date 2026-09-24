import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_management/features/admin/presentation/theme/admin_theme.dart';
import 'package:gym_management/features/admin/providers/admin_providers.dart';
import 'package:gym_management/features/shared/video_player_screen.dart';

const _muscleGroups = [
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

const _difficulties = ['beginner', 'intermediate', 'advanced'];

class VideoLibraryScreen extends ConsumerStatefulWidget {
  const VideoLibraryScreen({super.key});

  @override
  ConsumerState<VideoLibraryScreen> createState() => _VideoLibraryScreenState();
}

class _VideoLibraryScreenState extends ConsumerState<VideoLibraryScreen> {
  String _selectedGroup = 'All';
  String _search = '';
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final libraryAsync = ref.watch(exerciseLibraryProvider);

    return Scaffold(
      backgroundColor: AdminTheme.scaffold,
      appBar: AppBar(
        backgroundColor: AdminTheme.scaffold,
        title: Text('Video Library', style: AdminTheme.headingMedium),
        iconTheme: const IconThemeData(color: AdminTheme.textPrimary),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.refresh_rounded,
              color: AdminTheme.textPrimary,
            ),
            onPressed: () => ref.invalidate(exerciseLibraryProvider),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AdminTheme.orange,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_rounded, size: 28),
        onPressed: () => _openAddEditDialog(context),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              controller: _searchCtrl,
              style: const TextStyle(
                color: AdminTheme.textPrimary,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                hintText: 'Search exercises...',
                hintStyle: const TextStyle(
                  color: AdminTheme.textMuted,
                  fontSize: 13,
                ),
                filled: true,
                fillColor: AdminTheme.card,
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AdminTheme.textMuted,
                  size: 20,
                ),
                suffixIcon: _search.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Icons.clear_rounded,
                          color: AdminTheme.textMuted,
                          size: 18,
                        ),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _search = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
                  borderSide: const BorderSide(color: AdminTheme.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
                  borderSide: const BorderSide(color: AdminTheme.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
                  borderSide: const BorderSide(
                    color: AdminTheme.orange,
                    width: 1.5,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 12,
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
                  backgroundColor: AdminTheme.card,
                  selectedColor: AdminTheme.orange,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AdminTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                  side: BorderSide(
                    color: isSelected ? AdminTheme.orange : AdminTheme.border,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
                  ),
                );
              },
            ),
          ),

          // Video grid
          Expanded(
            child: libraryAsync.when(
              data: (exercises) {
                // Apply filters
                final filtered = exercises.where((ex) {
                  final matchGroup =
                      _selectedGroup == 'All' ||
                      (ex['muscle_group'] ?? '') == _selectedGroup;
                  final matchSearch =
                      _search.isEmpty ||
                      (ex['name'] ?? '').toString().toLowerCase().contains(
                        _search,
                      );
                  return matchGroup && matchSearch;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.video_library_rounded,
                          size: 56,
                          color: AdminTheme.textMuted,
                        ),
                        const SizedBox(height: 12),
                        Text('No exercises found', style: AdminTheme.bodySmall),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.82,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) => _buildVideoCard(context, filtered[i]),
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: AdminTheme.orange),
              ),
              error: (e, _) => Center(
                child: Text(
                  'Error: $e',
                  style: const TextStyle(color: AdminTheme.error),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openAddEditDialog(
    BuildContext context, [
    Map<String, dynamic>? existing,
  ]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AdminTheme.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AdminTheme.radiusXl),
        ),
      ),
      builder: (ctx) => _AddEditVideoSheet(
        existing: existing,
        onSaved: () => ref.invalidate(exerciseLibraryProvider),
      ),
    );
  }

  Widget _buildVideoCard(BuildContext context, Map<String, dynamic> exercise) {
    final hasVideo =
        exercise['video_url'] != null &&
        exercise['video_url'].toString().isNotEmpty;
    final muscleGroup = exercise['muscle_group'] ?? 'General';
    final isPending = exercise['is_approved'] == false;
    final uploaderName = (exercise['uploader'] as Map?)?['full_name'];
    final difficulty = exercise['difficulty'] ?? 'intermediate';

    Color diffColor = AdminTheme.orange;
    if (difficulty == 'beginner') diffColor = AdminTheme.success;
    if (difficulty == 'advanced') diffColor = AdminTheme.error;

    return GestureDetector(
      onTap: () => _showDetailSheet(context, exercise),
      onLongPress: () => _confirmDelete(context, exercise),
      child: Container(
        decoration: BoxDecoration(
          color: AdminTheme.card,
          borderRadius: BorderRadius.circular(AdminTheme.radiusLg),
          border: Border.all(
            color: isPending
                ? AdminTheme.warning.withValues(alpha: 0.6)
                : AdminTheme.border,
            width: isPending ? 1.5 : 1,
          ),
          boxShadow: AdminTheme.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Thumbnail area
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AdminTheme.radiusLg),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      color: AdminTheme.surface,
                      child: Center(
                        child: Icon(
                          hasVideo
                              ? Icons.play_circle_filled_rounded
                              : Icons.fitness_center_rounded,
                          size: 44,
                          color: hasVideo
                              ? AdminTheme.orange
                              : AdminTheme.textMuted,
                        ),
                      ),
                    ),

                    // Pending badge
                    if (isPending)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AdminTheme.warning,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'PENDING',
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),

                    // Muscle group badge (top-right)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AdminTheme.orange.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          muscleGroup,
                          style: AdminTheme.badgeText.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                    // Difficulty chip (bottom-left)
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: diffColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: diffColor.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Text(
                          difficulty,
                          style: AdminTheme.badgeText.copyWith(
                            color: diffColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Info section
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercise['name'] ?? 'Unknown',
                    style: AdminTheme.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (uploaderName != null)
                    Text(
                      'by $uploaderName',
                      style: AdminTheme.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )
                  else if (exercise['description'] != null)
                    Text(
                      exercise['description'],
                      style: AdminTheme.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetailSheet(BuildContext context, Map<String, dynamic> exercise) {
    final isPending = exercise['is_approved'] == false;
    showModalBottomSheet(
      context: context,
      backgroundColor: AdminTheme.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AdminTheme.radiusXl),
        ),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AdminTheme.orange.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.play_circle_filled_rounded,
                      color: AdminTheme.orange,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exercise['name'] ?? 'Unknown',
                          style: AdminTheme.headingSmall,
                        ),
                        Text(
                          '${exercise['muscle_group'] ?? 'General'} • ${exercise['difficulty'] ?? 'intermediate'}',
                          style: AdminTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (exercise['description'] != null &&
                  exercise['description'].toString().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    exercise['description'],
                    style: AdminTheme.bodySmall,
                  ),
                ),
              if (exercise['video_url'] != null &&
                  exercise['video_url'].toString().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => VideoPlayerScreen(
                            videoUrl: exercise['video_url'],
                            title: exercise['name'] ?? 'Video',
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AdminTheme.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AdminTheme.orange.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.play_circle_filled_rounded,
                            color: AdminTheme.orange,
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Play Video',
                              style: AdminTheme.bodyLarge.copyWith(
                                color: AdminTheme.orange,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.open_in_new_rounded,
                            color: AdminTheme.orange,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              const Divider(color: AdminTheme.border, height: 24),

              // Action buttons
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  // Edit
                  _actionBtn(
                    ctx,
                    Icons.edit_rounded,
                    'Edit',
                    AdminTheme.orange,
                    () {
                      Navigator.pop(ctx);
                      _openAddEditDialog(context, exercise);
                    },
                  ),

                  // Approve (only for pending)
                  if (isPending)
                    _actionBtn(
                      ctx,
                      Icons.check_circle_rounded,
                      'Approve',
                      AdminTheme.success,
                      () async {
                        Navigator.pop(ctx);
                        final repo = ref.read(adminRepositoryProvider);
                        await repo.approveExercise(exercise['id']);
                        ref.invalidate(exerciseLibraryProvider);
                      },
                    ),

                  // Delete
                  _actionBtn(
                    ctx,
                    Icons.delete_outline_rounded,
                    'Delete',
                    AdminTheme.error,
                    () {
                      Navigator.pop(ctx);
                      _confirmDelete(context, exercise);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionBtn(
    BuildContext ctx,
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withValues(alpha: 0.5)),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
        ),
      ),
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      onPressed: onTap,
    );
  }

  void _confirmDelete(BuildContext context, Map<String, dynamic> exercise) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AdminTheme.card,
        title: Text('Delete Exercise?', style: AdminTheme.headingSmall),
        content: Text(
          '"${exercise['name']}" will be permanently deleted.',
          style: AdminTheme.bodySmall,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(color: AdminTheme.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AdminTheme.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
              ),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final repo = ref.read(adminRepositoryProvider);
              await repo.deleteExercise(exercise['id']);
              ref.invalidate(exerciseLibraryProvider);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════
// ADD / EDIT VIDEO BOTTOM SHEET
// ══════════════════════════════════════════════════════

class _AddEditVideoSheet extends ConsumerStatefulWidget {
  const _AddEditVideoSheet({this.existing, required this.onSaved});
  final Map<String, dynamic>? existing;
  final VoidCallback onSaved;

  @override
  ConsumerState<_AddEditVideoSheet> createState() => _AddEditVideoSheetState();
}

class _AddEditVideoSheetState extends ConsumerState<_AddEditVideoSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _urlCtrl;
  late String _muscleGroup;
  late String _difficulty;
  bool _loading = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final ex = widget.existing;
    _nameCtrl = TextEditingController(text: ex?['name'] ?? '');
    _descCtrl = TextEditingController(text: ex?['description'] ?? '');
    _urlCtrl = TextEditingController(text: ex?['video_url'] ?? '');
    _muscleGroup = ex?['muscle_group'] ?? _muscleGroups[1]; // skip 'All'
    _difficulty = ex?['difficulty'] ?? 'intermediate';
    // Ensure muscle group is valid
    if (!_muscleGroups.contains(_muscleGroup) || _muscleGroup == 'All') {
      _muscleGroup = _muscleGroups[1];
    }
    if (!_difficulties.contains(_difficulty)) {
      _difficulty = 'intermediate';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _urlCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AdminTheme.textMuted,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _isEdit ? 'Edit Exercise' : 'Add New Exercise',
                style: AdminTheme.headingMedium,
              ),
              const SizedBox(height: 20),

              _label('Exercise Name *'),
              _field(
                _nameCtrl,
                'e.g. Barbell Squat',
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 14),

              _label('Muscle Group'),
              _dropdown(
                _muscleGroup,
                _muscleGroups.skip(1).toList(),
                (v) => setState(() => _muscleGroup = v!),
              ),
              const SizedBox(height: 14),

              _label('Difficulty'),
              _dropdown(
                _difficulty,
                _difficulties,
                (v) => setState(() => _difficulty = v!),
              ),
              const SizedBox(height: 14),

              _label('Description (optional)'),
              _field(_descCtrl, 'Short description...', maxLines: 2),
              const SizedBox(height: 14),

              _label('Video URL (YouTube, Vimeo, etc.)'),
              _field(
                _urlCtrl,
                'https://youtube.com/watch?v=...',
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AdminTheme.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
                    ),
                  ),
                  onPressed: _loading ? null : _save,
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          _isEdit ? 'Save Changes' : 'Add Exercise',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(text, style: AdminTheme.label),
  );

  Widget _field(
    TextEditingController ctrl,
    String hint, {
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(color: AdminTheme.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AdminTheme.textMuted, fontSize: 13),
        filled: true,
        fillColor: AdminTheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
          borderSide: const BorderSide(color: AdminTheme.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
          borderSide: const BorderSide(color: AdminTheme.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
          borderSide: const BorderSide(color: AdminTheme.orange, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
          borderSide: const BorderSide(color: AdminTheme.error),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
      ),
    );
  }

  Widget _dropdown(
    String value,
    List<String> items,
    void Function(String?) onChanged,
  ) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      dropdownColor: AdminTheme.surface,
      style: const TextStyle(color: AdminTheme.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        filled: true,
        fillColor: AdminTheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
          borderSide: const BorderSide(color: AdminTheme.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
          borderSide: const BorderSide(color: AdminTheme.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
          borderSide: const BorderSide(color: AdminTheme.orange, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
      ),
      items: items
          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
          .toList(),
      onChanged: onChanged,
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final repo = ref.read(adminRepositoryProvider);
      if (_isEdit) {
        await repo.updateExercise(widget.existing!['id'], {
          'name': _nameCtrl.text.trim(),
          'muscle_group': _muscleGroup,
          'difficulty': _difficulty,
          'description': _descCtrl.text.trim().isEmpty
              ? null
              : _descCtrl.text.trim(),
          'video_url': _urlCtrl.text.trim().isEmpty
              ? null
              : _urlCtrl.text.trim(),
        });
      } else {
        await repo.addExercise(
          name: _nameCtrl.text.trim(),
          muscleGroup: _muscleGroup,
          difficulty: _difficulty,
          description: _descCtrl.text.trim(),
          videoUrl: _urlCtrl.text.trim(),
        );
      }
      if (mounted) {
        Navigator.pop(context);
        widget.onSaved();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AdminTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
