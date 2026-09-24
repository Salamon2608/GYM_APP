import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gym_management/core/router/app_router.dart';
import 'package:gym_management/core/theme/app_theme.dart';
import 'package:gym_management/features/auth/providers/auth_provider.dart';
import 'package:gym_management/features/onboarding/providers/onboarding_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with TickerProviderStateMixin {
  final _pageController = PageController();

  // Step 1 controllers
  final _ageController = TextEditingController();
  String _selectedGender = '';
  double _height = 170;
  double _weight = 70;

  // Step 2 controllers
  String _selectedBloodGroup = '';
  final _medicalController = TextEditingController();
  final _allergiesController = TextEditingController();

  // Step 3
  String _selectedGoal = '';
  String _selectedExperience = '';

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final _bloodGroups = ['A+', 'A−', 'B+', 'B−', 'AB+', 'AB−', 'O+', 'O−'];

  final _goals = [
    {
      'id': 'fat_loss',
      'label': 'Fat Loss',
      'icon': Icons.local_fire_department_rounded,
      'color': 0xFFEF476F,
    },
    {
      'id': 'muscle_gain',
      'label': 'Muscle Gain',
      'icon': Icons.fitness_center_rounded,
      'color': 0xFFFF6B35,
    },
    {
      'id': 'general_fitness',
      'label': 'General Fitness',
      'icon': Icons.favorite_rounded,
      'color': 0xFF06D6A0,
    },
    {
      'id': 'flexibility',
      'label': 'Flexibility',
      'icon': Icons.self_improvement_rounded,
      'color': 0xFF2EC4B6,
    },
    {
      'id': 'endurance',
      'label': 'Endurance',
      'icon': Icons.directions_run_rounded,
      'color': 0xFFFFD166,
    },
    {
      'id': 'sports',
      'label': 'Sports Performance',
      'icon': Icons.sports_martial_arts_rounded,
      'color': 0xFF118AB2,
    },
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _ageController.dispose();
    _medicalController.dispose();
    _allergiesController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _goToStep(int step) {
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
    ref.read(onboardingProvider.notifier).goToStep(step);
  }

  Future<void> _handleSubmit() async {
    final userId = ref.read(authProvider).user?.id;
    if (userId == null) return;

    // Update all data before submit
    ref
        .read(onboardingProvider.notifier)
        .updateBodyMeasurements(
          age: int.tryParse(_ageController.text),
          gender: _selectedGender,
          heightCm: _height,
          weightKg: _weight,
        );
    ref
        .read(onboardingProvider.notifier)
        .updateHealthInfo(
          bloodGroup: _selectedBloodGroup.isEmpty ? null : _selectedBloodGroup,
          medicalConditions: _medicalController.text.trim().isEmpty
              ? null
              : _medicalController.text.trim(),
          allergies: _allergiesController.text.trim().isEmpty
              ? null
              : _allergiesController.text.trim(),
        );
    ref
        .read(onboardingProvider.notifier)
        .updateFitnessGoals(
          goal: _selectedGoal,
          experienceLevel: _selectedExperience,
        );

    final success = await ref
        .read(onboardingProvider.notifier)
        .submitOnboarding(userId);

    if (success && mounted) {
      context.go(AppRoutes.memberDashboard);
    }
  }

  bool _validateStep1() {
    return _ageController.text.isNotEmpty &&
        _selectedGender.isNotEmpty &&
        (int.tryParse(_ageController.text) ?? 0) > 0;
  }

  bool _validateStep3() {
    return _selectedGoal.isNotEmpty && _selectedExperience.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final onboardingState = ref.watch(onboardingProvider);
    final theme = Theme.of(context);

    ref.listen<OnboardingState>(onboardingProvider, (prev, next) {
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              // Header
              _buildHeader(onboardingState.currentStep, theme),
              // Progress indicator
              _buildProgressBar(onboardingState.currentStep),
              // Pages
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (index) {
                    ref.read(onboardingProvider.notifier).goToStep(index);
                  },
                  children: [
                    _buildStep1BodyMeasurements(theme),
                    _buildStep2HealthInfo(theme),
                    _buildStep3FitnessGoals(theme),
                  ],
                ),
              ),
              // Bottom navigation
              _buildBottomNav(onboardingState, theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(int step, ThemeData theme) {
    final titles = ['Body Measurements', 'Health Information', 'Fitness Goals'];
    final subtitles = [
      'Let\'s get to know your body',
      'Help us keep you safe',
      'What do you want to achieve?',
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primaryColor, AppTheme.primaryDark],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Step ${step + 1} of 3',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              titles[step],
              key: ValueKey(titles[step]),
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 4),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              subtitles[step],
              key: ValueKey(subtitles[step]),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(int step) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: List.generate(3, (index) {
          final isActive = index <= step;
          final isCurrent = index == step;
          return Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
              height: isCurrent ? 6 : 4,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                gradient: isActive
                    ? const LinearGradient(
                        colors: [AppTheme.primaryColor, AppTheme.primaryDark],
                      )
                    : null,
                color: isActive ? null : AppTheme.surfaceDark,
                boxShadow: isCurrent
                    ? [
                        BoxShadow(
                          color: AppTheme.primaryColor.withValues(alpha: 0.4),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
            ),
          );
        }),
      ),
    );
  }

  // ========================
  // STEP 1: Body Measurements
  // ========================
  Widget _buildStep1BodyMeasurements(ThemeData theme) {
    final heightM = _height / 100;
    final bmi = _weight / (heightM * heightM);
    final bmiCategory = _getBmiCategory(bmi);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),

          // Age
          Text('Age', style: _labelStyle(theme)),
          const SizedBox(height: 8),
          TextFormField(
            controller: _ageController,
            keyboardType: TextInputType.number,
            style: TextStyle(color: theme.textTheme.bodyLarge?.color),
            decoration: InputDecoration(
              hintText: 'Enter your age',
              prefixIcon: const Icon(
                Icons.cake_rounded,
                color: AppTheme.primaryColor,
              ),
              suffixText: 'years',
              suffixStyle: TextStyle(color: AppTheme.textSecondary),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 20),

          // Gender
          Text('Gender', style: _labelStyle(theme)),
          const SizedBox(height: 8),
          Row(
            children: ['male', 'female', 'other'].map((gender) {
              final isSelected = _selectedGender == gender;
              final icons = {
                'male': Icons.male_rounded,
                'female': Icons.female_rounded,
                'other': Icons.transgender_rounded,
              };
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedGender = gender),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primaryColor.withValues(alpha: 0.15)
                          : AppTheme.surfaceDark,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.primaryColor
                            : AppTheme.borderDark,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          icons[gender],
                          color: isSelected
                              ? AppTheme.primaryColor
                              : AppTheme.textSecondary,
                          size: 28,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          gender[0].toUpperCase() + gender.substring(1),
                          style: TextStyle(
                            color: isSelected
                                ? AppTheme.primaryColor
                                : AppTheme.textSecondary,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Height slider
          _buildSliderCard(
            theme: theme,
            label: 'Height',
            value: _height,
            min: 100,
            max: 220,
            unit: 'cm',
            icon: Icons.height_rounded,
            color: AppTheme.secondaryColor,
            onChanged: (v) => setState(() => _height = v),
          ),
          const SizedBox(height: 16),

          // Weight slider
          _buildSliderCard(
            theme: theme,
            label: 'Weight',
            value: _weight,
            min: 30,
            max: 200,
            unit: 'kg',
            icon: Icons.monitor_weight_rounded,
            color: AppTheme.accentColor,
            onChanged: (v) => setState(() => _weight = v),
          ),
          const SizedBox(height: 20),

          // BMI preview card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(bmiCategory['color'] as int).withValues(alpha: 0.15),
                  Color(bmiCategory['color'] as int).withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Color(
                  bmiCategory['color'] as int,
                ).withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Color(
                      bmiCategory['color'] as int,
                    ).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      bmi.toStringAsFixed(1),
                      style: TextStyle(
                        color: Color(bmiCategory['color'] as int),
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your BMI',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        bmiCategory['label'] as String,
                        style: TextStyle(
                          color: Color(bmiCategory['color'] as int),
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  bmiCategory['icon'] as IconData,
                  color: Color(bmiCategory['color'] as int),
                  size: 32,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSliderCard({
    required ThemeData theme,
    required String label,
    required double value,
    required double min,
    required double max,
    required String unit,
    required IconData icon,
    required Color color,
    required ValueChanged<double> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderDark),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 22),
                  const SizedBox(width: 8),
                  Text(label, style: _labelStyle(theme)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${value.round()} $unit',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: color,
              inactiveTrackColor: color.withValues(alpha: 0.2),
              thumbColor: color,
              overlayColor: color.withValues(alpha: 0.1),
              trackHeight: 4,
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: (max - min).round(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  // ========================
  // STEP 2: Health Information
  // ========================
  Widget _buildStep2HealthInfo(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),

          // Info banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.secondaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.secondaryColor.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  color: AppTheme.secondaryColor,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'This information helps your trainer create a safe workout plan. All fields are optional.',
                    style: TextStyle(
                      color: AppTheme.secondaryColor,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Blood Group
          Text('Blood Group', style: _labelStyle(theme)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _bloodGroups.map((bg) {
              final isSelected = _selectedBloodGroup == bg;
              return GestureDetector(
                onTap: () => setState(() {
                  _selectedBloodGroup = isSelected ? '' : bg;
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primaryColor.withValues(alpha: 0.15)
                        : AppTheme.surfaceDark,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.primaryColor
                          : AppTheme.borderDark,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Text(
                    bg,
                    style: TextStyle(
                      color: isSelected
                          ? AppTheme.primaryColor
                          : AppTheme.textPrimary,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      fontSize: 15,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Medical Conditions
          Text('Medical Conditions', style: _labelStyle(theme)),
          const SizedBox(height: 8),
          TextFormField(
            controller: _medicalController,
            maxLines: 3,
            style: TextStyle(color: theme.textTheme.bodyLarge?.color),
            decoration: const InputDecoration(
              hintText: 'e.g., Asthma, Diabetes, Heart condition...',
              prefixIcon: Padding(
                padding: EdgeInsets.only(bottom: 40),
                child: Icon(
                  Icons.medical_information_rounded,
                  color: AppTheme.errorColor,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Allergies
          Text('Allergies', style: _labelStyle(theme)),
          const SizedBox(height: 8),
          TextFormField(
            controller: _allergiesController,
            maxLines: 3,
            style: TextStyle(color: theme.textTheme.bodyLarge?.color),
            decoration: const InputDecoration(
              hintText: 'e.g., Lactose, Gluten, Peanuts...',
              prefixIcon: Padding(
                padding: EdgeInsets.only(bottom: 40),
                child: Icon(
                  Icons.warning_amber_rounded,
                  color: AppTheme.accentColor,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ========================
  // STEP 3: Fitness Goals
  // ========================
  Widget _buildStep3FitnessGoals(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),

          // Goal selection
          Text('Choose Your Fitness Goal', style: _labelStyle(theme)),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.3,
            ),
            itemCount: _goals.length,
            itemBuilder: (context, index) {
              final goal = _goals[index];
              final isSelected = _selectedGoal == goal['id'];
              final color = Color(goal['color'] as int);

              return GestureDetector(
                onTap: () =>
                    setState(() => _selectedGoal = goal['id'] as String),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? color.withValues(alpha: 0.15)
                        : AppTheme.cardDark,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? color : AppTheme.borderDark,
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: color.withValues(alpha: 0.2),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: color.withValues(
                            alpha: isSelected ? 0.3 : 0.1,
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          goal['icon'] as IconData,
                          color: color,
                          size: 26,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        goal['label'] as String,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isSelected ? color : AppTheme.textPrimary,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 28),

          // Experience Level
          Text('Experience Level', style: _labelStyle(theme)),
          const SizedBox(height: 12),
          Row(
            children:
                [
                  {
                    'id': 'beginner',
                    'label': 'Beginner',
                    'icon': Icons.star_border_rounded,
                  },
                  {
                    'id': 'intermediate',
                    'label': 'Intermediate',
                    'icon': Icons.star_half_rounded,
                  },
                  {
                    'id': 'advanced',
                    'label': 'Advanced',
                    'icon': Icons.star_rounded,
                  },
                ].map((level) {
                  final isSelected = _selectedExperience == level['id'];
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(
                        () => _selectedExperience = level['id'] as String,
                      ),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.accentColor.withValues(alpha: 0.15)
                              : AppTheme.cardDark,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.accentColor
                                : AppTheme.borderDark,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              level['icon'] as IconData,
                              color: isSelected
                                  ? AppTheme.accentColor
                                  : AppTheme.textSecondary,
                              size: 26,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              level['label'] as String,
                              style: TextStyle(
                                color: isSelected
                                    ? AppTheme.accentColor
                                    : AppTheme.textSecondary,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ========================
  // Bottom Navigation
  // ========================
  Widget _buildBottomNav(OnboardingState onboardingState, ThemeData theme) {
    final isLastStep = onboardingState.currentStep == 2;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: const Border(top: BorderSide(color: AppTheme.borderDark)),
      ),
      child: Row(
        children: [
          // Back button
          if (onboardingState.currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: () => _goToStep(onboardingState.currentStep - 1),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: AppTheme.borderDark),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Back',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          if (onboardingState.currentStep > 0) const SizedBox(width: 12),

          // Next / Finish button
          Expanded(
            flex: onboardingState.currentStep > 0 ? 2 : 1,
            child: ElevatedButton(
              onPressed: onboardingState.isLoading
                  ? null
                  : () {
                      if (isLastStep) {
                        if (!_validateStep3()) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Please select a goal and experience level',
                              ),
                              backgroundColor: AppTheme.errorColor,
                            ),
                          );
                          return;
                        }
                        _handleSubmit();
                      } else {
                        if (onboardingState.currentStep == 0 &&
                            !_validateStep1()) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Please enter your age and select gender',
                              ),
                              backgroundColor: AppTheme.errorColor,
                            ),
                          );
                          return;
                        }
                        _goToStep(onboardingState.currentStep + 1);
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: isLastStep
                    ? AppTheme.successColor
                    : AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: onboardingState.isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          isLastStep ? 'Complete Setup' : 'Continue',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          isLastStep
                              ? Icons.check_circle_rounded
                              : Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ========================
  // Helpers
  // ========================
  TextStyle _labelStyle(ThemeData theme) {
    return TextStyle(
      color: theme.textTheme.bodyLarge?.color,
      fontWeight: FontWeight.w600,
      fontSize: 15,
    );
  }

  Map<String, dynamic> _getBmiCategory(double bmi) {
    if (bmi < 18.5) {
      return {
        'label': 'Underweight',
        'color': 0xFF42A5F5,
        'icon': Icons.trending_down_rounded,
      };
    }
    if (bmi < 25) {
      return {
        'label': 'Normal',
        'color': 0xFF66BB6A,
        'icon': Icons.check_circle_rounded,
      };
    }
    if (bmi < 30) {
      return {
        'label': 'Overweight',
        'color': 0xFFFFA726,
        'icon': Icons.trending_up_rounded,
      };
    }
    return {
      'label': 'Obese',
      'color': 0xFFEF5350,
      'icon': Icons.warning_rounded,
    };
  }
}
