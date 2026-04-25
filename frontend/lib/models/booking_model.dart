import 'package:flutter/material.dart';
import 'user_model.dart';
import 'provider_model.dart';
class Booking {
  final String id;
  final String customerId;
  final String providerId;
  final String categoryId;
  final String status;
  final String description;
  final Location serviceLocation;
  final String scheduledDate;
  final String scheduledTime;
  final int estimatedDuration;
  final Price price;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? acceptedAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final String? cancellationReason;
  final bool advancePaid;
  final bool finalPaid;
  final User? customer;
  final ServiceProvider? provider;

  Booking({
    required this.id,
    required this.customerId,
    required this.providerId,
    required this.categoryId,
    required this.status,
    required this.description,
    required this.serviceLocation,
    required this.scheduledDate,
    required this.scheduledTime,
    required this.estimatedDuration,
    required this.price,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.acceptedAt,
    this.startedAt,
    this.completedAt,
    this.cancelledAt,
    this.cancellationReason,
    this.advancePaid = false,
    this.finalPaid = false,
    this.customer,
    this.provider,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'] ?? '',
      customerId: json['customerId'] ?? '',
      providerId: json['providerId'] ?? '',
      categoryId: json['categoryId'] ?? '',
      status: json['status'] ?? 'pending',
      description: json['description'] ?? '',
      serviceLocation: Location.fromJson(json['serviceLocation'] ?? {}),
      scheduledDate: json['scheduledDate'] ?? '',
      scheduledTime: json['scheduledTime'] ?? '',
      estimatedDuration: (json['estimatedDuration'] as num?)?.toInt() ?? 2,
      price: Price.fromJson(json['price'] ?? {}),
      notes: json['notes'] ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
      acceptedAt: json['acceptedAt'] != null
          ? DateTime.tryParse(json['acceptedAt'])
          : null,
      startedAt:
          json['startedAt'] != null ? DateTime.tryParse(json['startedAt']) : null,
      completedAt: json['completedAt'] != null
          ? DateTime.tryParse(json['completedAt'])
          : null,
      cancelledAt: json['cancelledAt'] != null
          ? DateTime.tryParse(json['cancelledAt'])
          : null,
      cancellationReason: json['cancellationReason'],
      advancePaid: json['advancePaid'] ?? false,
      finalPaid: json['finalPaid'] ?? false,
      customer:
          json['customer'] != null ? User.fromJson(json['customer']) : null,
      provider: json['provider'] != null
          ? ServiceProvider.fromJson(json['provider'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerId': customerId,
      'providerId': providerId,
      'categoryId': categoryId,
      'status': status,
      'description': description,
      'serviceLocation': serviceLocation.toJson(),
      'scheduledDate': scheduledDate,
      'scheduledTime': scheduledTime,
      'estimatedDuration': estimatedDuration,
      'price': price.toJson(),
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'acceptedAt': acceptedAt?.toIso8601String(),
      'startedAt': startedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'cancelledAt': cancelledAt?.toIso8601String(),
      'cancellationReason': cancellationReason,
      'advancePaid': advancePaid,
      'finalPaid': finalPaid,
    };
  }

  Booking copyWith({
    String? id,
    String? customerId,
    String? providerId,
    String? categoryId,
    String? status,
    String? description,
    Location? serviceLocation,
    String? scheduledDate,
    String? scheduledTime,
    int? estimatedDuration,
    Price? price,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? acceptedAt,
    DateTime? startedAt,
    DateTime? completedAt,
    DateTime? cancelledAt,
    String? cancellationReason,
    bool? advancePaid,
    bool? finalPaid,
    User? customer,
    ServiceProvider? provider,
  }) {
    return Booking(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      providerId: providerId ?? this.providerId,
      categoryId: categoryId ?? this.categoryId,
      status: status ?? this.status,
      description: description ?? this.description,
      serviceLocation: serviceLocation ?? this.serviceLocation,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      price: price ?? this.price,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      advancePaid: advancePaid ?? this.advancePaid,
      finalPaid: finalPaid ?? this.finalPaid,
      customer: customer ?? this.customer,
      provider: provider ?? this.provider,
    );
  }

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isInProgress => status == 'in-progress';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';
  bool get isActive => !isCompleted && !isCancelled;

  String get statusDisplay {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'accepted':
        return 'Accepted';
      case 'in-progress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Unknown';
    }
  }

  Color get statusColor {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.blue;
      case 'in-progress':
        return Colors.purple;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

class Location {
  final String address;
  final String city;
  final String state;
  final String zipCode;
  final double? latitude;
  final double? longitude;

  Location({
    required this.address,
    required this.city,
    required this.state,
    required this.zipCode,
    this.latitude,
    this.longitude,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      address: json['address'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      zipCode: json['zipCode'] ?? '',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'address': address,
      'city': city,
      'state': state,
      'zipCode': zipCode,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  String get fullAddress => '$address, $city, $state $zipCode';
}

class Price {
  final double hourlyRate;
  final int estimatedHours;
  final double totalAmount;
  final double materialsCost;

  Price({
    required this.hourlyRate,
    required this.estimatedHours,
    required this.totalAmount,
    required this.materialsCost,
  });

  factory Price.fromJson(Map<String, dynamic> json) {
    return Price(
      hourlyRate: (json['hourlyRate'] as num?)?.toDouble() ?? 0.0,
      estimatedHours: (json['estimatedHours'] as num?)?.toInt() ?? 0,
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      materialsCost: (json['materialsCost'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hourlyRate': hourlyRate,
      'estimatedHours': estimatedHours,
      'totalAmount': totalAmount,
      'materialsCost': materialsCost,
    };
  }

  double get grandTotal => totalAmount + materialsCost;
}