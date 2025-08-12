import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/todos_model.dart';  // Your task provider
import 'models/task.dart';
import 'pages/TaskDetailsPage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(TaskAdapter());
  await Hive.openBox<Task>('tasks');

  final todosModel = TodosModel();
  await todosModel.init();

  runApp(
    ChangeNotifierProvider(
      create: (_) => todosModel,  // <-- Use the initialized object here
      child: MaterialApp(
        home: ToDoApp(),
      ),
    ),
  );
}



class ToDoApp extends StatelessWidget{
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();


  @override
    Widget build(BuildContext context) {
      final todosModel = Provider.of<TodosModel>(context);
      return Scaffold(
        appBar: AppBar(title: Text('Tasks'),),
        body: Consumer<TodosModel>(
          builder: (context,todosModel,child){
            return AnimatedList(
              key: _listKey,
              initialItemCount: todosModel.tasks.length,
              itemBuilder: (context, index, animation){
                final task = todosModel.tasks[index];
                return FadeTransition(
                  opacity: animation,
                  child: ListTile(

                    title: Text(task.title),
                    leading: InkWell(
                      onTap: () {
                        todosModel.deleteTask(task);
                        _listKey.currentState?.removeItem(
                          index,
                              (context, animation) => SizeTransition(
                            sizeFactor: animation,
                          ),
                        );

                        // Delete on circle tap
                      },
                      customBorder: const CircleBorder(),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black, width: 2),
                        ),
                        width: 24,
                        height: 24,
                        child: const Icon(Icons.check, size: 16, color: Colors.red),
                      ),
                    ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TaskDetailsPage(task: task),
                          ),
                        );
                      }
                  ),
                );
              }
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          child: Icon(Icons.add),
          onPressed: () => _showAddTaskModal(context),
        ),


      );


    }

  void _showAddTaskModal(BuildContext context) {
    final TextEditingController _taskController = TextEditingController();
    final FocusNode _taskFocusNode = FocusNode();


    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allows modal to resize when keyboard appears
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          // Push up by keyboard height
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min, // Fit height to content
            children: [
              TextField(
                controller: _taskController,
                focusNode: _taskFocusNode,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Enter new task',
                  border: OutlineInputBorder(),
                ),
                // Pressing enter adds the task immediately
                onSubmitted: (_) =>
                    _addTask(context, _taskController,_taskFocusNode),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => _addTask(context, _taskController,_taskFocusNode),
                child: const Text("Add Task"),
              ),
            ],
          ),
        );
      },
    ).whenComplete(() {
      // Dispose controllers/focus nodes when modal closes
      _taskController.dispose();
      _taskFocusNode.dispose();
    });
  }

  /// Adds the task to the list and closes the modal
  void _addTask(BuildContext context, TextEditingController controller,FocusNode focusNode) {
    final text = controller.text.trim();
    if (text.isNotEmpty) {
      final todosModel = Provider.of<TodosModel>(context, listen: false);
      todosModel.addTask(Task(title: text));
      _listKey.currentState?.insertItem(0);
      controller.clear();           // Clear text
      focusNode.requestFocus();

      //Navigator.of(context).pop(); // Close the modal
    }
}

}

