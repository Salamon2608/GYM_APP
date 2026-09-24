import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_management/features/member/providers/profile_provider.dart';
import 'package:gym_management/core/theme/app_theme.dart';
import 'package:gym_management/features/admin/providers/admin_providers.dart';
import 'package:intl/intl.dart';
import 'package:gym_management/features/auth/providers/auth_provider.dart';

class TrainerRatingScreen extends ConsumerStatefulWidget {
  const TrainerRatingScreen({super.key});

  @override
  ConsumerState<TrainerRatingScreen> createState() =>
      _TrainerRatingScreenState();
}

class _TrainerRatingScreenState extends ConsumerState<TrainerRatingScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Trainer Feedback'),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: AppTheme.primaryColor,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: theme.disabledColor,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          tabs: const [
            Tab(text: 'Rate Trainer'),
            Tab(text: 'Complaint'),
            Tab(text: 'My Complaints'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [_RateTrainerTab(), _ComplaintTab(), _MyComplaintsTab()],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// TAB 1: RATE TRAINER
// ═══════════════════════════════════════════════════════

class _RateTrainerTab extends ConsumerStatefulWidget {
  @override
  ConsumerState<_RateTrainerTab> createState() => _RateTrainerTabState();
}

class _RateTrainerTabState extends ConsumerState<_RateTrainerTab> {
  int _rating = 0;
  final _commentCtrl = TextEditingController();
  bool _submitting = false;
  String? _trainerId;
  String? _trainerName;

  @override
  void initState() {
    super.initState();
    _loadAssignedTrainer();
  }

  Future<void> _loadAssignedTrainer() async {
    try {
      final repo = ref.read(profileRepositoryProvider);
      final trainer = await repo.getAssignedTrainer();
      if (trainer != null && mounted) {
        setState(() {
          _trainerId = trainer['id'] as String;
          _trainerName = trainer['full_name'] as String? ?? 'Your Trainer';
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_trainerId == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_off_rounded,
              size: 56,
              color: theme.disabledColor,
            ),
            const SizedBox(height: 12),
            Text(
              'No trainer assigned yet',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.disabledColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Ask admin to assign a trainer to you',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.disabledColor,
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 16),

          // Trainer avatar & name
          CircleAvatar(
            radius: 36,
            backgroundColor: AppTheme.primaryColor,
            child: Text(
              _getInitials(_trainerName ?? '?'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _trainerName ?? 'Trainer',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'How was your experience?',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.disabledColor,
            ),
          ),
          const SizedBox(height: 32),

          // Star rating
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final starIndex = i + 1;
              return GestureDetector(
                onTap: () => setState(() => _rating = starIndex),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: AnimatedScale(
                    scale: _rating >= starIndex ? 1.2 : 1.0,
                    duration: const Duration(milliseconds: 150),
                    child: Icon(
                      _rating >= starIndex
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      size: 44,
                      color: _rating >= starIndex
                          ? Colors.amber
                          : theme.disabledColor,
                    ),
                  ),
                ),
              );
            }),
          ),
          if (_rating > 0)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _ratingLabel(_rating),
                style: TextStyle(
                  color: Colors.amber.shade700,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          const SizedBox(height: 24),

          // Comment
          TextField(
            controller: _commentCtrl,
            maxLines: 3,
            style: theme.textTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Share your feedback (optional)',
              hintStyle: TextStyle(color: theme.disabledColor),
              filled: true,
              fillColor: theme.cardColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: theme.dividerColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: theme.dividerColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: AppTheme.primaryColor,
                  width: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Submit
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                disabledBackgroundColor: theme.disabledColor,
              ),
              onPressed: _rating == 0 || _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Submit Rating',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      final userId = ref.read(authProvider).user!.id;
      final repo = ref.read(adminRepositoryProvider);
      await repo.submitTrainerFeedback(
        userId: userId,
        trainerId: _trainerId!,
        rating: _rating,
        comment: _commentCtrl.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Rating submitted! Thank you'),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        setState(() {
          _rating = 0;
          _commentCtrl.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _ratingLabel(int r) {
    switch (r) {
      case 1:
        return 'Poor 😞';
      case 2:
        return 'Below Average 😕';
      case 3:
        return 'Average 🙂';
      case 4:
        return 'Good 😊';
      case 5:
        return 'Excellent! 🌟';
      default:
        return '';
    }
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return '?';
  }
}

// ═══════════════════════════════════════════════════════
// TAB 2: COMPLAINT ABOUT TRAINER
// ═══════════════════════════════════════════════════════

class _ComplaintTab extends ConsumerStatefulWidget {
  @override
  ConsumerState<_ComplaintTab> createState() => _ComplaintTabState();
}

class _ComplaintTabState extends ConsumerState<_ComplaintTab> {
  final _subjectCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _submitting = false;
  String? _trainerId;
  String? _trainerName;

  @override
  void initState() {
    super.initState();
    _loadAssignedTrainer();
  }

  Future<void> _loadAssignedTrainer() async {
    try {
      final repo = ref.read(profileRepositoryProvider);
      final trainer = await repo.getAssignedTrainer();
      if (trainer != null && mounted) {
        setState(() {
          _trainerId = trainer['id'] as String;
          _trainerName = trainer['full_name'] as String? ?? 'Your Trainer';
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_trainerId == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_off_rounded,
              size: 56,
              color: theme.disabledColor,
            ),
            const SizedBox(height: 12),
            Text(
              'No trainer assigned yet',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.disabledColor,
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // About trainer badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.errorColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.errorColor.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.sports_rounded,
                  color: AppTheme.errorColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Complaint about: $_trainerName',
                  style: TextStyle(
                    color: AppTheme.errorColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Subject
          Text(
            'Subject',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _subjectCtrl,
            style: theme.textTheme.bodyMedium,
            decoration: _inputDeco(context, 'e.g. Late to sessions'),
          ),
          const SizedBox(height: 16),

          // Description
          Text(
            'Description',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _descCtrl,
            maxLines: 5,
            style: theme.textTheme.bodyMedium,
            decoration: _inputDeco(context, 'Describe your issue in detail...'),
          ),
          const SizedBox(height: 28),

          // Submit
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: _submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.send_rounded, size: 18),
              label: Text(
                _submitting ? 'Submitting...' : 'Submit Complaint',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              onPressed: _submitting ? null : _submit,
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDeco(BuildContext context, String hint) {
    final theme = Theme.of(context);
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: theme.disabledColor),
      filled: true,
      fillColor: theme.cardColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: theme.dividerColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: theme.dividerColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppTheme.primaryColor, width: 1.5),
      ),
    );
  }

  Future<void> _submit() async {
    if (_subjectCtrl.text.trim().isEmpty || _descCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in subject and description')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final userId = ref.read(authProvider).user!.id;
      final repo = ref.read(adminRepositoryProvider);
      await repo.submitComplaintAboutTrainer(
        userId: userId,
        subject: _subjectCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        trainerId: _trainerId,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Complaint submitted to admin'),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        _subjectCtrl.clear();
        _descCtrl.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}

// ═══════════════════════════════════════════════════════
// TAB 3: MY COMPLAINTS
// ═══════════════════════════════════════════════════════

class _MyComplaintsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final complaintsAsync = ref.watch(myComplaintsProvider);
    final theme = Theme.of(context);

    return complaintsAsync.when(
      data: (complaints) {
        if (complaints.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.chat_bubble_outline, size: 64, color: theme.disabledColor),
                const SizedBox(height: 16),
                Text('No complaints found', style: theme.textTheme.titleMedium?.copyWith(color: theme.disabledColor)),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => ref.refresh(myComplaintsProvider.future),
          color: AppTheme.primaryColor,
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: complaints.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) => _buildComplaintCard(context, complaints[i]),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
      error: (e, _) => Center(
        child: Text('Error loading complaints:\n$e', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.errorColor)),
      ),
    );
  }

  Widget _buildComplaintCard(BuildContext context, Map<String, dynamic> complaint) {
    final theme = Theme.of(context);
    final status = (complaint['status'] as String?)?.toLowerCase() ?? 'pending';
    
    Color statusColor;
    switch (status) {
      case 'resolved':
        statusColor = AppTheme.successColor;
        break;
      case 'rejected':
        statusColor = AppTheme.errorColor;
        break;
      case 'pending':
      default:
        statusColor = AppTheme.primaryColor;
    }

    String dateStr = '';
    if (complaint['created_at'] != null) {
      try {
        final parsed = DateTime.parse(complaint['created_at']).toLocal();
        dateStr = DateFormat('MMM d, yyyy • h:mm a').format(parsed);
      } catch (_) {}
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  complaint['subject'] ?? 'No Subject',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (dateStr.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              dateStr,
              style: TextStyle(fontSize: 12, color: theme.disabledColor),
            ),
          ],
          if (complaint['description'] != null) ...[
            const SizedBox(height: 12),
            Text(
              complaint['description'],
              style: TextStyle(fontSize: 14, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8)),
            ),
          ],
        ],
      ),
    );
  }
}
