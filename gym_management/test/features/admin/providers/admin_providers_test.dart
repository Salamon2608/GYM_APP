import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:gym_management/features/admin/providers/admin_providers.dart';
import 'package:gym_management/features/admin/data/admin_repository.dart';

class MockAdminRepository extends Mock implements AdminRepository {}

void main() {
  late MockAdminRepository mockAdminRepository;
  late ProviderContainer container;

  setUp(() {
    mockAdminRepository = MockAdminRepository();
    container = ProviderContainer(
      overrides: [
        adminRepositoryProvider.overrideWithValue(mockAdminRepository),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('Admin Providers Tests', () {
    test('allUsersProvider returns list of users from repository', () async {
      // Arrange
      final mockData = [
        {'id': '1', 'full_name': 'Test User 1'},
        {'id': '2', 'full_name': 'Test User 2'},
      ];

      when(
        () => mockAdminRepository.getAllUsers(),
      ).thenAnswer((_) async => mockData);

      // Act
      final result = await container.read(allUsersProvider.future);

      // Assert
      expect(result, isA<List>());
      expect(result.length, 2);
      expect(result[0]['full_name'], 'Test User 1');
      verify(() => mockAdminRepository.getAllUsers()).called(1);
    });

    test('adminDashboardStatsProvider returns correct map', () async {
      // Arrange
      final mockStats = {'total_users': 150, 'total_trainers': 10};
      when(
        () => mockAdminRepository.getDashboardStats(),
      ).thenAnswer((_) async => mockStats);

      // Act
      final result = await container.read(adminDashboardStatsProvider.future);

      // Assert
      expect(result['total_users'], 150);
      expect(result['total_trainers'], 10);
      verify(() => mockAdminRepository.getDashboardStats()).called(1);
    });
  });
}
