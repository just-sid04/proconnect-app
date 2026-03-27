import 'user_model.dart';

class ServiceProvider {
  final String id;
  final String userId;
  final String categoryId;
  final List<String> skills;
  final int experience;
  final double hourlyRate;
  final String description;
  final Availability availability;
  final int serviceArea;
  final bool isVerified;
  final String verificationStatus;
  final double rating;
  final int totalReviews;
  final int totalBookings;
  final List<String> portfolio;
  final List<String> documents;
  final DateTime createdAt;
  final DateTime updatedAt;
  final User? user;
  final Category? category;
  final double? distance;
  final bool isOnline;
  final DateTime lastActiveAt;
  final bool isAvailableNow;

  ServiceProvider({
    required this.id,
    required this.userId,
    required this.categoryId,
    required this.skills,
    required this.experience,
    required this.hourlyRate,
    required this.description,
    required this.availability,
    required this.serviceArea,
    required this.isVerified,
    required this.verificationStatus,
    required this.rating,
    required this.totalReviews,
    required this.totalBookings,
    required this.portfolio,
    required this.documents,
    required this.createdAt,
    required this.updatedAt,
    this.user,
    this.category,
    this.distance,
    this.isOnline = true,
    required this.lastActiveAt,
    this.isAvailableNow = false,
  });

  factory ServiceProvider.fromJson(Map<String, dynamic> json) {
    return ServiceProvider(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      categoryId: json['categoryId'] ?? '',
      skills: List<String>.from(json['skills'] ?? []),
      experience: (json['experience'] as num?)?.toInt() ?? 0,
      hourlyRate: (json['hourlyRate'] as num?)?.toDouble() ?? 0.0,
      description: json['description'] ?? '',
      availability: Availability.fromJson(json['availability'] ?? {}),
      serviceArea: (json['serviceArea'] as num?)?.toInt() ?? 10,
      isVerified: json['isVerified'] ?? false,
      verificationStatus: json['verificationStatus'] ?? 'pending',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      totalReviews: (json['totalReviews'] as num?)?.toInt() ?? 0,
      totalBookings: (json['totalBookings'] as num?)?.toInt() ?? 0,
      portfolio: List<String>.from(json['portfolio'] ?? []),
      documents: List<String>.from(json['documents'] ?? []),
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      category: json['category'] != null ? Category.fromJson(json['category']) : null,
      distance: (json['distance'] as num?)?.toDouble() ?? (json['distance_km'] as num?)?.toDouble(),
      isOnline: json['isOnline'] ?? true,
      lastActiveAt: DateTime.tryParse(json['lastActiveAt'] ?? '') ?? DateTime.now(),
      isAvailableNow: json['isAvailableNow'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'categoryId': categoryId,
      'skills': skills,
      'experience': experience,
      'hourlyRate': hourlyRate,
      'description': description,
      'availability': availability.toJson(),
      'serviceArea': serviceArea,
      'isVerified': isVerified,
      'verificationStatus': verificationStatus,
      'rating': rating,
      'totalReviews': totalReviews,
      'totalBookings': totalBookings,
      'portfolio': portfolio,
      'documents': documents,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      if (distance != null) 'distance': distance,
      'is_online': isOnline,
      'last_active_at': lastActiveAt.toIso8601String(),
    };
  }

  String get displayName => user?.name ?? 'Unknown Provider';
  String get profileImage => user?.profilePhoto ?? '';
}

class Availability {
  final DayAvailability monday;
  final DayAvailability tuesday;
  final DayAvailability wednesday;
  final DayAvailability thursday;
  final DayAvailability friday;
  final DayAvailability saturday;
  final DayAvailability sunday;

  Availability({
    required this.monday,
    required this.tuesday,
    required this.wednesday,
    required this.thursday,
    required this.friday,
    required this.saturday,
    required this.sunday,
  });

  factory Availability.fromJson(Map<String, dynamic> json) {
    return Availability(
      monday: DayAvailability.fromJson(json['monday'] ?? {}),
      tuesday: DayAvailability.fromJson(json['tuesday'] ?? {}),
      wednesday: DayAvailability.fromJson(json['wednesday'] ?? {}),
      thursday: DayAvailability.fromJson(json['thursday'] ?? {}),
      friday: DayAvailability.fromJson(json['friday'] ?? {}),
      saturday: DayAvailability.fromJson(json['saturday'] ?? {}),
      sunday: DayAvailability.fromJson(json['sunday'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'monday': monday.toJson(),
      'tuesday': tuesday.toJson(),
      'wednesday': wednesday.toJson(),
      'thursday': thursday.toJson(),
      'friday': friday.toJson(),
      'saturday': saturday.toJson(),
      'sunday': sunday.toJson(),
    };
  }
}

class DayAvailability {
  final bool available;
  final String startTime;
  final String endTime;

  DayAvailability({
    required this.available,
    required this.startTime,
    required this.endTime,
  });

  factory DayAvailability.fromJson(Map<String, dynamic> json) {
    return DayAvailability(
      available: json['available'] ?? false,
      startTime: json['startTime'] ?? '09:00',
      endTime: json['endTime'] ?? '17:00',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'available': available,
      'startTime': startTime,
      'endTime': endTime,
    };
  }
}

class Category {
  final String id;
  final String name;
  final String description;
  final String icon;
  final String color;
  final List<String> services;
  final double averageRate;
  final int totalProviders;
  final bool isActive;

  Category({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.services,
    required this.averageRate,
    required this.totalProviders,
    required this.isActive,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      icon: json['icon'] ?? 'default',
      color: json['color'] ?? '#2196F3',
      services: List<String>.from(json['services'] ?? []),
      averageRate: (json['averageRate'] as num?)?.toDouble() ?? 0.0,
      totalProviders: (json['totalProviders'] as num?)?.toInt() ?? 0,
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': icon,
      'color': color,
      'services': services,
      'averageRate': averageRate,
      'totalProviders': totalProviders,
      'isActive': isActive,
    };
  }
}
