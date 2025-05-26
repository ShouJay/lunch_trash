class Member {
  final String name;
  final String group;

  Member({
    required this.name,
    required this.group,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'group': group,
      };

  factory Member.fromJson(Map<String, dynamic> json) => Member(
        name: json['name'] as String,
        group: json['group'] as String,
      );
}
