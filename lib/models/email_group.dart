class EmailGroup {
  final String name;
  final List<String> emails;

  EmailGroup({required this.name, required this.emails});

  factory EmailGroup.fromJson(Map<String, dynamic> json) {
    return EmailGroup(
      name: json['name'],
      emails: List<String>.from(json['emails']),
    );
  }
} 