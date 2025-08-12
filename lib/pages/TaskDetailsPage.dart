import 'package:to_do_list/main.dart';
import 'package:flutter/material.dart';
import 'package:to_do_list/models/task.dart';


class TaskDetailsPage extends StatelessWidget {
  final Task task;

  const TaskDetailsPage({Key? key, required this.task}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Task Details')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Text(
          task.title,
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}