import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_management/features/auth/providers/auth_provider.dart';
import 'package:gym_management/features/trainer/providers/trainer_provider.dart';
import 'package:gym_management/features/shared/video_player_screen.dart';

const _muscleGroups = [
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

class TrainerVideoScreen extends ConsumerStatefulWidget {
  const TrainerVideoScreen({super.key});

  @override
  ConsumerState<TrainerVideoScreen> createState() => _TrainerVideoScreenState();
}

class _TrainerVideoScreenState extends ConsumerState<TrainerVideoScreen> {
  String? _trainerId;

  @override
  void initState() {
    super.initState();
    _trainerId = ref.read(authProvider).user?.id;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    if (_trainerId == null) {
      return const Scaffold(body: Center(child: Text('Not logged in')));
    }

    final videosAsync = ref.watch(myVideosProvider(_trainerId!));

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C1C1C),
        foregroundColor: Colors.white,
        title: Text(
          'My Exercise Videos',
          style: tt.titleMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: () => ref.invalidate(myVideosProvider(_trainerId!)),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFFF6B00),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.video_call_rounded),
        label: const Text('Submit Video'),
        onPressed: () => _openSubmitForm(context),
      ),
      body: videosAsync.when(
        data: (videos) {
          if (videos.isEmpty) {
            return _buildEmptyState(context);
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: videos.length,
            itemBuilder: (_, i) => _buildVideoTile(context, videos[i]),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFFFF6B00)),
        ),
        error: (e, _) => Center(
          child: Text('Error: $e', style: const TextStyle(color: Colors.red)),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.video_library_outlined,
            size: 64,
            color: Color(0xFF616161),
          ),
          const SizedBox(height: 16),
          Text(
            'No videos submitted yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the + button to add an exercise video.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.white54),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B00),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.video_call_rounded),
            label: const Text('Submit First Video'),
            onPressed: () => _openSubmitForm(context),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoTile(BuildContext context, Map<String, dynamic> video) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1C),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2E2E2E)),
      ),
      child: GestureDetector(
        onTap: () {
          final url = video['video_url']?.toString() ?? '';
          if (url.isNotEmpty) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => VideoPlayerScreen(
                  videoUrl: url,
                  title: video['name'] ?? 'Video',
                ),
              ),
            );
          }
        },
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 10,
          ),
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B00).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.play_circle_fill_rounded,
              color: Color(0xFFFF6B00),
              size: 26,
            ),
          ),
          title: Text(
            video['name'] ?? 'Unknown',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '${video['muscle_group'] ?? ''} • ${video['difficulty'] ?? ''}',
              style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 12),
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.edit_outlined,
                  color: Color(0xFFFF6B00),
                  size: 22,
                ),
                onPressed: () => _openEditForm(context, video),
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Color(0xFFFF5252),
                  size: 22,
                ),
                onPressed: () => _confirmDelete(context, video),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openEditForm(BuildContext context, Map<String, dynamic> video) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1C1C1C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _EditVideoForm(
        trainerId: _trainerId!,
        video: video,
        onUpdated: () {
          ref.invalidate(myVideosProvider(_trainerId!));
        },
      ),
    );
  }

  void _openSubmitForm(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1C1C1C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _SubmitVideoForm(
        trainerId: _trainerId!,
        onSubmitted: () {
          ref.invalidate(myVideosProvider(_trainerId!));
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, Map<String, dynamic> video) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1C),
        title: const Text(
          'Delete Video?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          '"${video['name']}" will be permanently deleted.',
          style: const TextStyle(color: Color(0xFF9E9E9E)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF9E9E9E)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF5252),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final repo = ref.read(trainerRepositoryProvider);
              await repo.deleteMyVideo(video['id']);
              ref.invalidate(myVideosProvider(_trainerId!));
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════
// SUBMIT VIDEO FORM
// ══════════════════════════════════════════════════════

class _SubmitVideoForm extends ConsumerStatefulWidget {
  const _SubmitVideoForm({required this.trainerId, required this.onSubmitted});
  final String trainerId;
  final VoidCallback onSubmitted;

  @override
  ConsumerState<_SubmitVideoForm> createState() => _SubmitVideoFormState();
}

class _SubmitVideoFormState extends ConsumerState<_SubmitVideoForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _urlCtrl = TextEditingController();
  String _muscleGroup = _muscleGroups.first;
  String _difficulty = 'intermediate';
  bool _loading = false;

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
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF616161),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Submit Exercise Video',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Add a new exercise video for your members.',
                style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 12),
              ),
              const SizedBox(height: 20),

              // Name
              _buildLabel('Exercise Name *'),
              _buildTextField(
                controller: _nameCtrl,
                hint: 'e.g. Barbell Squat',
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 14),

              // Muscle Group
              _buildLabel('Muscle Group'),
              _buildDropdown<String>(
                value: _muscleGroup,
                items: _muscleGroups,
                onChanged: (v) => setState(() => _muscleGroup = v!),
              ),
              const SizedBox(height: 14),

              // Difficulty
              _buildLabel('Difficulty'),
              _buildDropdown<String>(
                value: _difficulty,
                items: _difficulties,
                onChanged: (v) => setState(() => _difficulty = v!),
              ),
              const SizedBox(height: 14),

              // Description
              _buildLabel('Description (optional)'),
              _buildTextField(
                controller: _descCtrl,
                hint: 'Short description of this exercise...',
                maxLines: 2,
              ),
              const SizedBox(height: 14),

              // Video URL
              _buildLabel('Video URL (YouTube / link) *'),
              _buildTextField(
                controller: _urlCtrl,
                hint: 'https://www.youtube.com/watch?v=...',
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  final uri = Uri.tryParse(v.trim());
                  if (uri == null || !uri.hasScheme) return 'Enter a valid URL';
                  return null;
                },
              ),
              const SizedBox(height: 28),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B00),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Submit for Review',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
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

  Widget _buildLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      text,
      style: const TextStyle(
        color: Color(0xFF9E9E9E),
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    ),
  );

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF616161), fontSize: 13),
        filled: true,
        fillColor: const Color(0xFF252525),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2E2E2E)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2E2E2E)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFFF6B00), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFFF5252)),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required T value,
    required List<T> items,
    required void Function(T?) onChanged,
  }) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      dropdownColor: const Color(0xFF252525),
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFF252525),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2E2E2E)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2E2E2E)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFFF6B00), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
      ),
      items: items
          .map((e) => DropdownMenuItem(value: e, child: Text(e.toString())))
          .toList(),
      onChanged: onChanged,
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final repo = ref.read(trainerRepositoryProvider);

      await repo.submitVideo(
        trainerId: widget.trainerId,
        name: _nameCtrl.text.trim(),
        muscleGroup: _muscleGroup,
        difficulty: _difficulty,
        description: _descCtrl.text.trim(),
        videoUrl: _urlCtrl.text.trim(),
      );
      if (mounted) {
        Navigator.pop(context);
        widget.onSubmitted();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Video added successfully!',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Color(0xFF1C1C1C),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: const Color(0xFFFF5252),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

// ══════════════════════════════════════════════════════
// EDIT VIDEO FORM
// ══════════════════════════════════════════════════════

class _EditVideoForm extends ConsumerStatefulWidget {
  final String trainerId;
  final Map<String, dynamic> video;
  final VoidCallback onUpdated;

  const _EditVideoForm({
    required this.trainerId,
    required this.video,
    required this.onUpdated,
  });

  @override
  ConsumerState<_EditVideoForm> createState() => _EditVideoFormState();
}

class _EditVideoFormState extends ConsumerState<_EditVideoForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _urlCtrl;
  late String _muscleGroup;
  late String _difficulty;
  bool _loading = false;

  static const _muscleGroups = [
    'Chest',
    'Back',
    'Shoulders',
    'Arms',
    'Legs',
    'Core',
    'Full Body',
    'Cardio',
  ];
  static const _difficulties = ['beginner', 'intermediate', 'advanced'];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.video['name'] ?? '');
    _descCtrl = TextEditingController(text: widget.video['description'] ?? '');
    _urlCtrl = TextEditingController(text: widget.video['video_url'] ?? '');
    _muscleGroup = _muscleGroups.contains(widget.video['muscle_group'])
        ? widget.video['muscle_group']
        : _muscleGroups.first;
    _difficulty = _difficulties.contains(widget.video['difficulty'])
        ? widget.video['difficulty']
        : 'intermediate';
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
                    color: const Color(0xFF616161),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Edit Exercise Video',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 20),

              _label('Exercise Name *'),
              _textField(
                controller: _nameCtrl,
                hint: 'e.g. Barbell Squat',
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 14),

              _label('Muscle Group'),
              _dropdown<String>(
                value: _muscleGroup,
                items: _muscleGroups,
                onChanged: (v) => setState(() => _muscleGroup = v!),
              ),
              const SizedBox(height: 14),

              _label('Difficulty'),
              _dropdown<String>(
                value: _difficulty,
                items: _difficulties,
                onChanged: (v) => setState(() => _difficulty = v!),
              ),
              const SizedBox(height: 14),

              _label('Description (optional)'),
              _textField(
                controller: _descCtrl,
                hint: 'Short description...',
                maxLines: 2,
              ),
              const SizedBox(height: 14),

              _label('Video URL *'),
              _textField(
                controller: _urlCtrl,
                hint: 'https://www.youtube.com/watch?v=...',
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  final uri = Uri.tryParse(v.trim());
                  if (uri == null || !uri.hasScheme) return 'Enter a valid URL';
                  return null;
                },
              ),
              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B00),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
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
                      : const Text(
                          'Save Changes',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
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
    child: Text(
      text,
      style: const TextStyle(
        color: Color(0xFF9E9E9E),
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    ),
  );

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF616161), fontSize: 13),
        filled: true,
        fillColor: const Color(0xFF252525),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2E2E2E)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2E2E2E)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFFF6B00), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
      ),
    );
  }

  Widget _dropdown<T>({
    required T value,
    required List<T> items,
    required void Function(T?) onChanged,
  }) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      items: items
          .map((e) => DropdownMenuItem(value: e, child: Text('$e')))
          .toList(),
      onChanged: onChanged,
      dropdownColor: const Color(0xFF252525),
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFF252525),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2E2E2E)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2E2E2E)),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final repo = ref.read(trainerRepositoryProvider);
      await repo.updateVideo(
        videoId: widget.video['id'],
        name: _nameCtrl.text.trim(),
        muscleGroup: _muscleGroup,
        difficulty: _difficulty,
        description: _descCtrl.text.trim(),
        videoUrl: _urlCtrl.text.trim(),
      );
      if (mounted) {
        Navigator.pop(context);
        widget.onUpdated();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Video updated!',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Color(0xFF1C1C1C),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: const Color(0xFFFF5252),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
