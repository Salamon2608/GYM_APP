import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:gym_management/core/constants/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:gym_management/features/admin/presentation/theme/admin_theme.dart';
import 'package:gym_management/features/admin/providers/admin_providers.dart';

class ManageAdvertisementsScreen extends ConsumerStatefulWidget {
  const ManageAdvertisementsScreen({super.key});

  @override
  ConsumerState<ManageAdvertisementsScreen> createState() =>
      _ManageAdvertisementsScreenState();
}

class _ManageAdvertisementsScreenState
    extends ConsumerState<ManageAdvertisementsScreen> {
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.refresh(allAdvertisementsProvider));
  }

  Future<void> _showAdForm([Map<String, dynamic>? existingAd]) async {
    final isEditing = existingAd != null;
    final titleController = TextEditingController(text: existingAd?['title']);
    final redirectUrlController = TextEditingController(
      text: existingAd?['redirect_url'],
    );

    String selectedSegment = existingAd?['target_segment'] ?? 'ALL';
    String selectedRedirectType = existingAd?['redirect_type'] ?? 'PT';
    DateTime selectedStartDate = existingAd != null
        ? DateTime.parse(existingAd['start_date'])
        : DateTime.now();
    DateTime selectedEndDate = existingAd != null
        ? DateTime.parse(existingAd['end_date'])
        : DateTime.now().add(const Duration(days: 7));
    bool isActive = existingAd == null ||
        existingAd['is_active'] == true ||
        existingAd['is_active'] == 1 ||
        existingAd['is_active'] == '1';
    XFile? selectedImage;
    String? existingImageUrl = existingAd?['image_url'];

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AdminTheme.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEditing ? 'Edit Campaign' : 'New Campaign',
                      style: AdminTheme.headingMedium,
                    ),
                    const SizedBox(height: 20),
                    // Image Picker
                    GestureDetector(
                      onTap: () async {
                        final picked = await _picker.pickImage(
                          source: ImageSource.gallery,
                        );
                        if (picked != null) {
                          setModalState(() {
                            selectedImage = picked;
                          });
                        }
                      },
                      child: Container(
                        height: 150,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AdminTheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AdminTheme.border),
                        ),
                        child: selectedImage != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: kIsWeb
                                    ? Image.network(
                                        selectedImage!.path,
                                        fit: BoxFit.cover,
                                      )
                                    : Image.file(
                                        File(selectedImage!.path),
                                        fit: BoxFit.cover,
                                      ),
                              )
                            : existingImageUrl != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  AppConstants.getFullImageUrl(existingImageUrl),
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: AdminTheme.surface,
                                    child: const Center(
                                      child: Icon(Icons.broken_image, color: AdminTheme.textMuted),
                                    ),
                                  ),
                                ),
                              )
                            : const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_photo_alternate_outlined,
                                    size: 40,
                                    color: AdminTheme.textMuted,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Upload Banner Image',
                                    style: TextStyle(
                                      color: AdminTheme.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: titleController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Campaign Title',
                        labelStyle: const TextStyle(
                          color: AdminTheme.textSecondary,
                        ),
                        filled: true,
                        fillColor: AdminTheme.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: selectedSegment,
                            dropdownColor: AdminTheme.surface,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Target Segment',
                              labelStyle: const TextStyle(
                                color: AdminTheme.textSecondary,
                              ),
                              filled: true,
                              fillColor: AdminTheme.surface,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            items: ['ALL', 'EXPIRING', 'INACTIVE', 'PREMIUM', 'EXPIRED']
                                .map(
                                  (s) => DropdownMenuItem(
                                    value: s,
                                    child: Text(s),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) =>
                                setModalState(() => selectedSegment = val!),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: selectedRedirectType,
                            dropdownColor: AdminTheme.surface,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Redirect Type',
                              labelStyle: const TextStyle(
                                color: AdminTheme.textSecondary,
                              ),
                              filled: true,
                              fillColor: AdminTheme.surface,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            items: ['PT', 'RENEWAL', 'UPGRADE', 'EXTERNAL']
                                .map(
                                  (s) => DropdownMenuItem(
                                    value: s,
                                    child: Text(s),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) => setModalState(
                              () => selectedRedirectType = val!,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (selectedRedirectType == 'EXTERNAL') ...[
                      const SizedBox(height: 16),
                      TextField(
                        controller: redirectUrlController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'External URL',
                          labelStyle: const TextStyle(
                            color: AdminTheme.textSecondary,
                          ),
                          filled: true,
                          fillColor: AdminTheme.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final d = await showDatePicker(
                                context: context,
                                initialDate: selectedStartDate,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2030),
                              );
                              if (d != null) {
                                setModalState(() => selectedStartDate = d);
                              }
                            },
                            icon: const Icon(Icons.calendar_today, size: 16),
                            label: Text(
                              'Start: ${selectedStartDate.toLocal().toString().split(' ')[0]}',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AdminTheme.surface,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final d = await showDatePicker(
                                context: context,
                                initialDate: selectedEndDate,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2030),
                              );
                              if (d != null) {
                                setModalState(() => selectedEndDate = d);
                              }
                            },
                            icon: const Icon(Icons.event, size: 16),
                            label: Text(
                              'End: ${selectedEndDate.toLocal().toString().split(' ')[0]}',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AdminTheme.surface,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text(
                        'Active Status',
                        style: TextStyle(color: Colors.white),
                      ),
                      value: isActive,
                      activeThumbColor: AdminTheme.orange,
                      onChanged: (val) => setModalState(() => isActive = val),
                      contentPadding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AdminTheme.orange,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () async {
                          if (titleController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Title is required'),
                              ),
                            );
                            return;
                          }
                          if (!isEditing && selectedImage == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Image is required for new ad'),
                              ),
                            );
                            return;
                          }

                          try {
                            final repo = ref.read(adminRepositoryProvider);
                            String finalImageUrl = existingImageUrl ?? '';

                            if (selectedImage != null) {
                              final uploadUrl = await repo.uploadAdvertisementImage(selectedImage!);
                              if (uploadUrl == null) {
                                throw Exception('Failed to upload ad image');
                              }
                              finalImageUrl = uploadUrl;
                            }

                            if (isEditing) {
                              await repo.updateAdvertisement(existingAd['id'], {
                                'title': titleController.text,
                                'image_url': finalImageUrl,
                                'target_segment': selectedSegment,
                                'redirect_type': selectedRedirectType,
                                'redirect_url': redirectUrlController.text,
                                'start_date': selectedStartDate
                                    .toUtc()
                                    .toIso8601String(),
                                'end_date': selectedEndDate
                                    .toUtc()
                                    .toIso8601String(),
                                'is_active': isActive,
                              });
                            } else {
                              await repo.createAdvertisement(
                                title: titleController.text,
                                imageUrl: finalImageUrl,
                                targetSegment: selectedSegment,
                                redirectType: selectedRedirectType,
                                redirectUrl: redirectUrlController.text,
                                startDate: selectedStartDate,
                                endDate: selectedEndDate,
                                isActive: isActive,
                              );
                            }

                            if (context.mounted) {
                              Navigator.pop(context);
                              ref.invalidate(allAdvertisementsProvider);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    isEditing
                                        ? 'Campaign updated'
                                        : 'Campaign created',
                                  ),
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e')),
                              );
                            }
                          }
                        },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Text('Save Campaign'),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _viewInteractions(String adId, String adTitle) async {
    try {
      final repo = ref.read(adminRepositoryProvider);
      final stats = await repo.getAdvertisementPerformance(adId);

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AdminTheme.card,
          title: Text(
            'Performance: $adTitle',
            style: const TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total Views: ${stats['views']}',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 8),
              Text(
                'Total Clicks: ${stats['clicks']}',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 8),
              Text(
                'CTR (Click-Through Rate): ${stats['ctr'].toStringAsFixed(2)}%',
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'Close',
                style: TextStyle(color: AdminTheme.orange),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Status fetch failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final adsAsync = ref.watch(allAdvertisementsProvider);

    return Scaffold(
      backgroundColor: AdminTheme.scaffold,
      appBar: AppBar(
        title: const Text('Internal Ads Engine'),
        backgroundColor: AdminTheme.card,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AdminTheme.orange,
        onPressed: () => _showAdForm(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: adsAsync.when(
        data: (ads) {
          if (ads.isEmpty) {
            return const Center(
              child: Text(
                'No campaigns found.',
                style: TextStyle(color: AdminTheme.textMuted),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: ads.length,
            itemBuilder: (context, index) {
              final ad = ads[index];
              final isActive = ad['is_active'] == true || ad['is_active'] == 1 || ad['is_active'] == '1';
              return Card(
                color: AdminTheme.card,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Banner Image
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      child: Image.network(
                        AppConstants.getFullImageUrl(ad['image_url']?.toString()),
                        height: 140,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          height: 140,
                          color: AdminTheme.surface,
                          child: const Icon(
                            Icons.image_not_supported,
                            color: AdminTheme.textMuted,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  ad['title'] ?? 'Untitled',
                                  style: AdminTheme.headingSmall,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? Colors.green.withValues(alpha: 0.2)
                                      : Colors.red.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  isActive ? 'Active' : 'Inactive',
                                  style: TextStyle(
                                    color: isActive ? Colors.green : Colors.red,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Target: ${ad['target_segment']} • Redirect: ${ad['redirect_type']}',
                            style: const TextStyle(
                              color: AdminTheme.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton.icon(
                                onPressed: () => _viewInteractions(
                                  ad['id'].toString(),
                                  ad['title'],
                                ),
                                icon: const Icon(Icons.bar_chart, size: 16),
                                label: const Text('Stats'),
                                style: TextButton.styleFrom(
                                  foregroundColor: AdminTheme.orange,
                                ),
                              ),
                              TextButton.icon(
                                onPressed: () => _showAdForm(ad),
                                icon: const Icon(Icons.edit, size: 16),
                                label: const Text('Edit'),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AdminTheme.orange),
        ),
        error: (e, st) => Center(
          child: Text(
            'Error: $e',
            style: const TextStyle(color: AdminTheme.error),
          ),
        ),
      ),
    );
  }
}
