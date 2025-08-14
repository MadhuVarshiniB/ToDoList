import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'task.dart';

class TodosModel extends ChangeNotifier {
  late Box<Task> _taskBox;

  List<Task> get tasks => _taskBox.values.toList();

  // Initialize Hive box
  Future<void> init() async {
    _taskBox = await Hive.openBox<Task>('tasks');
    notifyListeners();
  }

  Future<void> addTaskAt(int index, Task task) async {
    // ... Hive saving logic ...
    await Hive.box<Task>('tasks').add(task); // Or put with a key
    tasks.insert(index, task);
    notifyListeners();
  }

  void addTask(Task task)async {
    await Hive.box<Task>('tasks').add(task);
    tasks.insert(0, task);
    notifyListeners();
  }

  void toggleTaskCompletion(Task task) {
    task.isCompleted = !task.isCompleted;
    task.save();
    notifyListeners();
  }

  void deleteTask(Task task) {
    task.delete();
    notifyListeners();
  }

  void completeTask(Task task) {
    task.isCompleted = true;
    task.completedAt = DateTime.now();
    notifyListeners();
  }

  int countCompletedToday() {
    DateTime today = DateTime.now();
    return tasks.where((task) =>
    task.isCompleted &&
        task.completedAt != null &&
        task.completedAt!.year == today.year &&
        task.completedAt!.month == today.month &&
        task.completedAt!.day == today.day
    ).length;
  }

}