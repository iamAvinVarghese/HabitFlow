import 'package:hive/hive.dart';

part 'journal_model.g.dart';

@HiveType(typeId: 6)
class JournalEntry extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late DateTime date;

  @HiveField(2)
  late String title;

  @HiveField(3)
  late String content;

  @HiveField(4)
  late List<String> tags;

  @HiveField(5)
  late DateTime createdAt;

  @HiveField(6)
  late DateTime? updatedAt;

  @HiveField(7)
  late int wordCount;

  JournalEntry({
    required this.id,
    required this.date,
    required this.title,
    required this.content,
    List<String>? tags,
    DateTime? createdAt,
    this.updatedAt,
    int? wordCount,
  })  : tags = tags ?? [],
        createdAt = createdAt ?? DateTime.now(),
        wordCount = wordCount ?? content.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;

  void updateContent(String newTitle, String newContent) {
    title = newTitle;
    content = newContent;
    updatedAt = DateTime.now();
    wordCount = newContent.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date.toIso8601String(),
    'title': title,
    'content': content,
    'tags': tags,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
    'wordCount': wordCount,
  };
}
