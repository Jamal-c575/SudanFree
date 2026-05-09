import 'package:cloud_firestore/cloud_firestore.dart';

enum ProposalStatus { pending, accepted, rejected, withdrawn }

class ProposalModel {
  final String id;
  final String jobId;
  final String jobTitle;
  final String freelancerId;
  final String freelancerName;
  final String? freelancerImageUrl;
  final String clientId;
  final double proposedPrice;
  final String currency;
  final int deliveryDays;
  final String coverLetter;
  final ProposalStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProposalModel({
    required this.id,
    required this.jobId,
    required this.jobTitle,
    required this.freelancerId,
    required this.freelancerName,
    this.freelancerImageUrl,
    required this.clientId,
    required this.proposedPrice,
    this.currency = 'SDG',
    required this.deliveryDays,
    required this.coverLetter,
    this.status = ProposalStatus.pending,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProposalModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProposalModel(
      id: doc.id,
      jobId: data['jobId'] ?? '',
      jobTitle: data['jobTitle'] ?? '',
      freelancerId: data['freelancerId'] ?? '',
      freelancerName: data['freelancerName'] ?? '',
      freelancerImageUrl: data['freelancerImageUrl'],
      clientId: data['clientId'] ?? '',
      proposedPrice: (data['proposedPrice'] as num?)?.toDouble() ?? 0,
      currency: data['currency'] ?? 'SDG',
      deliveryDays: data['deliveryDays'] ?? 0,
      coverLetter: data['coverLetter'] ?? '',
      status: ProposalStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => ProposalStatus.pending,
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'jobId': jobId,
      'jobTitle': jobTitle,
      'freelancerId': freelancerId,
      'freelancerName': freelancerName,
      'freelancerImageUrl': freelancerImageUrl,
      'clientId': clientId,
      'proposedPrice': proposedPrice,
      'currency': currency,
      'deliveryDays': deliveryDays,
      'coverLetter': coverLetter,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  ProposalModel copyWith({
    String? id,
    String? jobId,
    String? jobTitle,
    String? freelancerId,
    String? freelancerName,
    String? freelancerImageUrl,
    String? clientId,
    double? proposedPrice,
    String? currency,
    int? deliveryDays,
    String? coverLetter,
    ProposalStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProposalModel(
      id: id ?? this.id,
      jobId: jobId ?? this.jobId,
      jobTitle: jobTitle ?? this.jobTitle,
      freelancerId: freelancerId ?? this.freelancerId,
      freelancerName: freelancerName ?? this.freelancerName,
      freelancerImageUrl: freelancerImageUrl ?? this.freelancerImageUrl,
      clientId: clientId ?? this.clientId,
      proposedPrice: proposedPrice ?? this.proposedPrice,
      currency: currency ?? this.currency,
      deliveryDays: deliveryDays ?? this.deliveryDays,
      coverLetter: coverLetter ?? this.coverLetter,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isPending => status == ProposalStatus.pending;
  bool get isAccepted => status == ProposalStatus.accepted;
  bool get isRejected => status == ProposalStatus.rejected;
}
