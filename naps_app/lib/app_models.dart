class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.branch,
    required this.phone,
    required this.organizationId,
  });
  final String id;
  final String name;
  final String email;
  final String role;
  final String branch;
  final String phone;
  final String organizationId;

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
    id: json['id'] as String? ?? json['_id'] as String? ?? '',
    name: json['name'] as String? ?? '',
    email: json['email'] as String? ?? '',
    role: json['role'] as String? ?? 'employee',
    branch: json['branch'] as String? ?? '',
    phone: json['phone'] as String? ?? '',
    organizationId:
        json['organizationId'] as String? ??
        json['organization'] as String? ??
        '',
  );
}

class WorkTask {
  const WorkTask({
    required this.id,
    required this.title,
    required this.details,
    required this.assigneeId,
    required this.assigneeName,
    required this.creatorName,
    required this.branch,
    required this.dueDate,
    required this.status,
  });
  final String id;
  final String title;
  final String details;
  final String assigneeId;
  final String assigneeName;
  final String creatorName;
  final String branch;
  final DateTime dueDate;
  final String status;
  bool get complete => status == 'complete';

  factory WorkTask.fromJson(Map<String, dynamic> json) {
    final assignedTo = json['assignedTo'] is Map
        ? Map<String, dynamic>.from(json['assignedTo'] as Map)
        : <String, dynamic>{};
    final createdBy = json['createdBy'] is Map
        ? Map<String, dynamic>.from(json['createdBy'] as Map)
        : <String, dynamic>{};
    return WorkTask(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      details: json['details'] as String? ?? '',
      assigneeId: assignedTo['_id'] as String? ?? '',
      assigneeName: assignedTo['name'] as String? ?? '',
      creatorName: createdBy['name'] as String? ?? '',
      branch: json['branch'] as String? ?? '',
      dueDate:
          DateTime.tryParse(json['dueDate'] as String? ?? '') ?? DateTime.now(),
      status: json['status'] as String? ?? 'open',
    );
  }
}

class SupportTicket {
  const SupportTicket({
    required this.id,
    required this.title,
    required this.details,
    required this.department,
    required this.status,
    required this.creatorId,
    required this.creatorName,
    required this.createdAt,
  });
  final String id;
  final String title;
  final String details;
  final String department;
  final String status;
  final String creatorId;
  final String creatorName;
  final DateTime createdAt;

  factory SupportTicket.fromJson(Map<String, dynamic> json) {
    final createdBy = json['createdBy'] is Map
        ? Map<String, dynamic>.from(json['createdBy'] as Map)
        : <String, dynamic>{};
    return SupportTicket(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      details: json['details'] as String? ?? '',
      department: json['department'] as String? ?? '',
      status: json['status'] as String? ?? 'open',
      creatorId: createdBy['_id'] as String? ?? '',
      creatorName: createdBy['name'] as String? ?? '',
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

class TeamAnnouncement {
  const TeamAnnouncement({
    required this.id,
    required this.title,
    required this.message,
    required this.creatorName,
    required this.createdAt,
    required this.acknowledgedUserIds,
  });
  final String id;
  final String title;
  final String message;
  final String creatorName;
  final DateTime createdAt;
  final List<String> acknowledgedUserIds;

  factory TeamAnnouncement.fromJson(Map<String, dynamic> json) {
    final createdBy = json['createdBy'] is Map
        ? Map<String, dynamic>.from(json['createdBy'] as Map)
        : <String, dynamic>{};
    final acknowledgements = (json['acknowledgedBy'] as List? ?? [])
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
    return TeamAnnouncement(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      creatorName: createdBy['name'] as String? ?? '',
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      acknowledgedUserIds: acknowledgements
          .map(
            (item) => item['user'] is Map
                ? (item['user'] as Map)['_id']?.toString() ?? ''
                : item['user']?.toString() ?? '',
          )
          .toList(),
    );
  }
}

class TeamMember {
  const TeamMember({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.branch,
    required this.phone,
  });
  final String id;
  final String name;
  final String email;
  final String role;
  final String branch;
  final String phone;

  factory TeamMember.fromJson(Map<String, dynamic> json) => TeamMember(
    id: json['_id'] as String? ?? json['id'] as String? ?? '',
    name: json['name'] as String? ?? '',
    email: json['email'] as String? ?? '',
    role: json['role'] as String? ?? 'employee',
    branch: json['branch'] as String? ?? '',
    phone: json['phone'] as String? ?? '',
  );
}
