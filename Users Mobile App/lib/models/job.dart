class JobPayment {
  final String workerId;
  final double amount;
  final DateTime date;
  final String? note;

  JobPayment({required this.workerId, required this.amount, required this.date, this.note});

  Map<String, dynamic> toMap() => {
    'workerId': workerId,
    'amount': amount,
    'date': date.toIso8601String(),
    'note': note,
  };

  factory JobPayment.fromMap(Map<dynamic, dynamic> map) => JobPayment(
    workerId: map['workerId'] ?? '',
    amount: (map['amount'] ?? 0).toDouble(),
    date: DateTime.parse(map['date'] ?? DateTime.now().toIso8601String()),
    note: map['note'],
  );
}

class Job {
  final String id;
  final String title;
  final String description;
  final String employerId;
  final String employerName;
  final String categoryId;
  final String categoryName;
  final String location;
  final String status; // 'open', 'in_progress', 'completed', 'cancelled'
  final List<String> appliedWorkerIds;
  final List<String> acceptedWorkerIds;
  final List<JobPayment> payments;
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
    List<String>? acceptedWorkerIds,
    List<JobPayment>? payments,
    List<String>? requiredSkillIds,
    DateTime? createdAt,
  })  : appliedWorkerIds = appliedWorkerIds ?? [],
        acceptedWorkerIds = acceptedWorkerIds ?? [],
        payments = payments ?? [],
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
    List<String>? acceptedWorkerIds,
    List<JobPayment>? payments,
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
      acceptedWorkerIds: acceptedWorkerIds ?? List.from(this.acceptedWorkerIds),
      payments: payments ?? List.from(this.payments),
      requiredSkillIds: requiredSkillIds ?? List.from(this.requiredSkillIds),
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
