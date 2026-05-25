class TrustedAppContact {
  final String userId;
  final String name;
  final String phone;

  /// 'pending_sent' | 'pending_incoming' | 'accepted'
  final String status;

  const TrustedAppContact({
    required this.userId,
    required this.name,
    required this.phone,
    required this.status,
  });

  factory TrustedAppContact.fromJson(Map<String, dynamic> json) {
    return TrustedAppContact(
      userId: json['userId']?.toString() ?? '',
      name: (json['name'] as String?) ?? '',
      phone: (json['phone'] as String?) ?? '',
      status: (json['status'] as String?) ?? 'pending_sent',
    );
  }

  bool get isAccepted => status == 'accepted';
  bool get isPendingSent => status == 'pending_sent';
  bool get isPendingIncoming => status == 'pending_incoming';
}
