import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'task.dart';
import 'dart:collection';

class TodosModel extends ChangeNotifier {
  late Box<Task> _taskBox;
  List<Task> _internalTasks = [];



  // Initialize Hive box
  Future<void> init() async {
    _taskBox = await Hive.openBox<Task>('tasks');
    _loadTasksFromHive();
    //notifyListeners();
  }
  void _loadTasksFromHive(){
  _internalTasks = _taskBox.values.toList().reversed.toList();
  notifyListeners();
  }

  List<Task> get tasks => UnmodifiableListView(_internalTasks);


  Future<void> addTaskToTop(int index, Task task) async {
    // ... Hive saving logic ...
    await Hive.box<Task>('tasks').add(task); // Or put with a key
    _internalTasks.insert(0, task);
    notifyListeners();
  }

  void addTask(Task task)async {
    await Hive.box<Task>('tasks').add(task);
    _internalTasks.insert(0, task);
    notifyListeners();
  }

  void toggleTaskCompletion(Task task) {
    task.isCompleted = !task.isCompleted;
    task.save();
    notifyListeners();
  }

  void deleteTask(Task task) {
    task.delete();
    _internalTasks.remove(task);
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

