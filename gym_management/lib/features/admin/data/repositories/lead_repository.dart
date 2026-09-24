import 'package:gym_management/core/services/api_service.dart';
import 'package:gym_management/features/admin/data/models/lead_model.dart';
import 'package:gym_management/features/admin/data/admin_repository.dart';

class LeadRepository {
  final String? gymId;
  final AdminRepository _adminRepo;

  LeadRepository({this.gymId}) : _adminRepo = AdminRepository(gymId: gymId);

  Future<List<LeadModel>> fetchLeads() async {
    try {
      final response = await ApiService.get('/admin/leads');
      return (response.data as List)
          .map((data) => LeadModel.fromJson(data as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<LeadModel> addLead(LeadModel lead) async {
    try {
      final response = await ApiService.post(
        '/admin/leads',
        data: lead.copyWith(gymId: gymId).toJson(),
      );
      return LeadModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  Future<LeadModel> updateLead(LeadModel lead) async {
    if (lead.id == null) throw Exception('Lead ID is required for update');
    try {
      final response = await ApiService.put(
        '/admin/leads/${lead.id}',
        data: lead.toJson(),
      );
      return LeadModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteLead(String id) async {
    try {
      await ApiService.delete('/admin/leads/$id');
    } catch (e) {
      rethrow;
    }
  }

  Future<void> convertToMember({
    required LeadModel lead,
    required String password,
    required Map<String, dynamic> selectedPlan,
  }) async {
    try {
      // 1. Create a member account using the existing AdminRepository logic
      await _adminRepo.createMemberAccount(
        email: lead.email ?? '${lead.phone}@gym.com', // fallback if email is missing
        password: password,
        fullName: lead.fullName,
        phone: lead.phone,
        selectedPlan: selectedPlan,
      );

      // 2. Update lead status to 'joined'
      await updateLead(lead.copyWith(status: LeadStatus.joined));
    } catch (e) {
      rethrow;
    }
  }
}
