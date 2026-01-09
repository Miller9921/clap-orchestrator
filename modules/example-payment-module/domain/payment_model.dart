// Example Domain Entity - PaymentModel
// Location: lib/paymentmodule/entities/payment_model.dart

import 'package:equatable/equatable.dart';

/// Payment transaction model representing a payment in the system.
/// 
/// This model follows CLAP conventions:
/// - Extends Equatable for value comparison
/// - Uses const constructor for immutability
/// - All fields are final
/// - Includes copyWith for immutable updates
/// - Overrides props for Equatable
class PaymentModel extends Equatable {
  /// Unique payment identifier
  final String id;
  
  /// Payment amount
  final double amount;
  
  /// Currency code (USD, EUR, GBP, etc.)
  final String currency;
  
  /// Payment status: pending, completed, failed, refunded
  final String status;
  
  /// Transaction creation timestamp
  final DateTime createdAt;
  
  /// Last update timestamp (nullable)
  final DateTime? updatedAt;
  
  /// ID of the user who made the payment
  final String userId;
  
  /// ID of the payment method used
  final String paymentMethodId;
  
  /// Optional payment description
  final String? description;

  const PaymentModel({
    required this.id,
    required this.amount,
    required this.currency,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    required this.userId,
    required this.paymentMethodId,
    this.description,
  });

  /// Creates a copy of this model with the given fields replaced with new values.
  /// 
  /// This method enables immutable updates following the Equatable pattern.
  PaymentModel copyWith({
    String? id,
    double? amount,
    String? currency,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? userId,
    String? paymentMethodId,
    String? description,
  }) {
    return PaymentModel(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userId: userId ?? this.userId,
      paymentMethodId: paymentMethodId ?? this.paymentMethodId,
      description: description ?? this.description,
    );
  }

  /// Equatable props for value comparison
  @override
  List<Object?> get props => [
        id,
        amount,
        currency,
        status,
        createdAt,
        updatedAt,
        userId,
        paymentMethodId,
        description,
      ];

  @override
  bool get stringify => true;
}
