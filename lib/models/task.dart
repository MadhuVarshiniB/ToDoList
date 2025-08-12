import 'package:hive/hive.dart';

part 'task.g.dart'; // Needed for code generation

@HiveType(typeId: 0)
class Task extends HiveObject {
  @HiveField(0)
  String title;

  @HiveField(1)
  bool isCompleted;

  @HiveField(2)
  DateTime? completedAt;

  Task({
    required this.title,
    this.isCompleted = false,
    this.completedAt
  });
}