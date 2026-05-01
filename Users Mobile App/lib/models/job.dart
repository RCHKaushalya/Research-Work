class Job {
  final String id;
  final String title;
  final String description;
  final String employerId;
  final String employerName;
  final String categoryId;
  final String categoryName;
  final String location;
  final String status;
  final List<String> appliedWorkerIds;
  final List<String> requiredSkillIds;
  final DateTime createdAt;

  Job({
    required this.id,
    required this.title,
    required this.description,
    required this.employerId,
    required this.employerName,
    required this.categoryId,
    required this.categoryName,
    required this.location,
    this.status = 'open',
    List<String>? appliedWorkerIds,
    List<String>? requiredSkillIds,
    DateTime? createdAt,
  })  : appliedWorkerIds = appliedWorkerIds ?? [],
        requiredSkillIds = requiredSkillIds ?? [],
        createdAt = createdAt ?? DateTime.now();

  Job copyWith({
    String? id,
    String? title,
    String? description,
    String? employerId,
    String? employerName,
    String? categoryId,
    String? categoryName,
    String? location,
    String? status,
    List<String>? appliedWorkerIds,
    List<String>? requiredSkillIds,
    DateTime? createdAt,
  }) {
    return Job(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      employerId: employerId ?? this.employerId,
      employerName: employerName ?? this.employerName,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      location: location ?? this.location,
      status: status ?? this.status,
      appliedWorkerIds: appliedWorkerIds ?? List.from(this.appliedWorkerIds),
      requiredSkillIds: requiredSkillIds ?? List.from(this.requiredSkillIds),
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
