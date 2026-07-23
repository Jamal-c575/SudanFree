import 'package:cloud_firestore/cloud_firestore.dart';

class BankAccountModel {
  final String id;
  final String bankName;
  final String accountNumber;
  final String accountHolderName;

  BankAccountModel({
    required this.id,
    required this.bankName,
    required this.accountNumber,
    required this.accountHolderName,
  });

  factory BankAccountModel.fromMap(Map<String, dynamic> map) {
    return BankAccountModel(
      id: map['id'] ?? '',
      bankName: map['bankName'] ?? '',
      accountNumber: map['accountNumber'] ?? '',
      accountHolderName: map['accountHolderName'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bankName': bankName,
      'accountNumber': accountNumber,
      'accountHolderName': accountHolderName,
    };
  }

  BankAccountModel copyWith({
    String? id,
    String? bankName,
    String? accountNumber,
    String? accountHolderName,
  }) {
    return BankAccountModel(
      id: id ?? this.id,
      bankName: bankName ?? this.bankName,
      accountNumber: accountNumber ?? this.accountNumber,
      accountHolderName: accountHolderName ?? this.accountHolderName,
    );
  }
}
