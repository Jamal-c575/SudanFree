class PaymentMethodModel {
  final String bankName;
  final String accountName;
  final String accountNumber;

  PaymentMethodModel({
    required this.bankName,
    required this.accountName,
    required this.accountNumber,
  });

  factory PaymentMethodModel.fromMap(Map<String, dynamic> map) {
    return PaymentMethodModel(
      bankName: map['bankName'] ?? '',
      accountName: map['accountName'] ?? '',
      accountNumber: map['accountNumber'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'bankName': bankName,
      'accountName': accountName,
      'accountNumber': accountNumber,
    };
  }
}
