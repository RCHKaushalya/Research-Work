class Review {
  final String authorName;
  final String comment;
  final double rating;
  final DateTime date;

  Review({required this.authorName, required this.comment, required this.rating, required this.date});

  Map<String, dynamic> toMap() => {
    'authorName': authorName,
    'comment': comment,
    'rating': rating,
    'date': date.toIso8601String(),
  };

  factory Review.fromMap(Map<dynamic, dynamic> map) => Review(
    authorName: map['authorName'] ?? '',
    comment: map['comment'] ?? '',
    rating: (map['rating'] ?? 0).toDouble(),
    date: DateTime.parse(map['date'] ?? DateTime.now().toIso8601String()),
  );
}

class AppUser {
  const AppUser({
    required this.nic,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.pin,
    this.districtId,
    this.districtName,
    this.dsAreaId,
    this.dsAreaName,
    this.jobCategoryIds = const [],
    this.jobCategoryNames = const [],
    this.skillIds = const [],
    this.skillNames = const [],
    this.profilePhotoPath,
    this.rating = 4.5,
    this.completedJobsCount = 0,
    this.abandonedJobsCount = 0,
    this.portfolioPhotos = const [],
    this.reviews = const [],
  });

  final String nic;
  final String firstName;
  final String lastName;
  final String phone;
  final String pin;
  final String? districtId;
  final String? districtName;
  final String? dsAreaId;
  final String? dsAreaName;
  final List<String> jobCategoryIds;
  final List<String> jobCategoryNames;
  final List<String> skillIds;
  final List<String> skillNames;
  final String? profilePhotoPath;
  final double rating;
  final int completedJobsCount;
  final int abandonedJobsCount;
  final List<String> portfolioPhotos;
  final List<Review> reviews;

  String get fullName => '$firstName $lastName'.trim();

  AppUser copyWith({
    String? nic,
    String? firstName,
    String? lastName,
    String? phone,
    String? pin,
    String? districtId,
    String? districtName,
    String? dsAreaId,
    String? dsAreaName,
    List<String>? jobCategoryIds,
    List<String>? jobCategoryNames,
    List<String>? skillIds,
    List<String>? skillNames,
    String? profilePhotoPath,
    double? rating,
    int? completedJobsCount,
    int? abandonedJobsCount,
    List<String>? portfolioPhotos,
    List<Review>? reviews,
  }) {
    return AppUser(
      nic: nic ?? this.nic,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      pin: pin ?? this.pin,
      districtId: districtId ?? this.districtId,
      districtName: districtName ?? this.districtName,
      dsAreaId: dsAreaId ?? this.dsAreaId,
      dsAreaName: dsAreaName ?? this.dsAreaName,
      jobCategoryIds: jobCategoryIds ?? this.jobCategoryIds,
      jobCategoryNames: jobCategoryNames ?? this.jobCategoryNames,
      skillIds: skillIds ?? this.skillIds,
      skillNames: skillNames ?? this.skillNames,
      profilePhotoPath: profilePhotoPath ?? this.profilePhotoPath,
      rating: rating ?? this.rating,
      completedJobsCount: completedJobsCount ?? this.completedJobsCount,
      abandonedJobsCount: abandonedJobsCount ?? this.abandonedJobsCount,
      portfolioPhotos: portfolioPhotos ?? this.portfolioPhotos,
      reviews: reviews ?? this.reviews,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nic': nic,
      'firstName': firstName,
      'lastName': lastName,
      'phone': phone,
      'pin': pin,
      'districtId': districtId,
      'districtName': districtName,
      'dsAreaId': dsAreaId,
      'dsAreaName': dsAreaName,
      'jobCategoryIds': jobCategoryIds,
      'jobCategoryNames': jobCategoryNames,
      'skillIds': skillIds,
      'skillNames': skillNames,
      'profilePhotoPath': profilePhotoPath,
      'rating': rating,
      'completedJobsCount': completedJobsCount,
      'abandonedJobsCount': abandonedJobsCount,
      'portfolioPhotos': portfolioPhotos,
      'reviews': reviews.map((r) => r.toMap()).toList(),
    };
  }

  factory AppUser.fromMap(Map<dynamic, dynamic> map) {
    return AppUser(
      nic: (map['nic'] ?? '').toString(),
      firstName: (map['firstName'] ?? '').toString(),
      lastName: (map['lastName'] ?? '').toString(),
      phone: (map['phone'] ?? '').toString(),
      pin: (map['pin'] ?? '').toString(),
      districtId: map['districtId']?.toString(),
      districtName: map['districtName']?.toString(),
      dsAreaId: map['dsAreaId']?.toString(),
      dsAreaName: map['dsAreaName']?.toString(),
      jobCategoryIds: _stringList(map['jobCategoryIds']),
      jobCategoryNames: _stringList(map['jobCategoryNames']),
      skillIds: _stringList(map['skillIds']),
      skillNames: _stringList(map['skillNames']),
      profilePhotoPath: map['profilePhotoPath']?.toString(),
      rating: (map['rating'] ?? 4.5).toDouble(),
      completedJobsCount: (map['completedJobsCount'] ?? 0).toInt(),
      abandonedJobsCount: (map['abandonedJobsCount'] ?? 0).toInt(),
      portfolioPhotos: _stringList(map['portfolioPhotos']),
      reviews: (map['reviews'] as List? ?? []).map((r) => Review.fromMap(r)).toList(),
    );
  }

  static List<String> _stringList(dynamic value) {
    if (value is List) {
      return value.map((item) => item.toString()).toList();
    }
    return const [];
  }
}
