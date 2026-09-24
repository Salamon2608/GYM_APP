import 'package:intl/intl.dart';

enum LeadStatus {
  new_('new'),
  contacted('contacted'),
  interested('interested'),
  trial('trial'),
  joined('joined'),
  lost('lost');

  final String value;
  const LeadStatus(this.value);

  static LeadStatus fromString(String value) {
    return LeadStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => LeadStatus.new_,
    );
  }
}

class LeadModel {
  final String? id;
  final String fullName;
  final String phone;
  final String? email;
  final String? source;
  final LeadStatus status;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? gymId;

  LeadModel({
    this.id,
    required this.fullName,
    required this.phone,
    this.email,
    this.source,
    this.status = LeadStatus.new_,
    this.notes,
    this.createdAt,
    this.updatedAt,
    this.gymId,
  });

  factory LeadModel.fromJson(Map<String, dynamic> json) {
    return LeadModel(
      id: json['id'] as String?,
      fullName: json['full_name'] as String? ?? 'Unknown',
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String?,
      source: json['source'] as String?,
      status: LeadStatus.fromString(json['status'] as String? ?? 'new'),
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
      gymId: json['gym_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'full_name': fullName,
      'phone': phone,
      'email': email,
      'source': source,
      'status': status.value,
      'notes': notes,
      'gym_id': gymId,
    };
  }

  LeadModel copyWith({
    String? id,
    String? fullName,
    String? phone,
    String? email,
    String? source,
    LeadStatus? status,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? gymId,
  }) {
    return LeadModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      source: source ?? this.source,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      gymId: gymId ?? this.gymId,
    );
  }

  String get formattedDate {
    if (createdAt == null) return '';
    return DateFormat('dd MMM yyyy, hh:mm a').format(createdAt!);
  }
}
