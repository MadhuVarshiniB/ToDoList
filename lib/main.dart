import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/widgets.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/todos_model.dart';  // Your task provider
import 'models/task.dart';
import 'pages/TaskDetailsPage.dart';
import 'package:path_provider/path_provider.dart';

//final GlobalKey<_TasksPageState> tasksPageKey = GlobalKey<_TasksPageState>();

class NavigationProvider extends ChangeNotifier {
  static const String boxName = "settingsBox";
  static const String indexKey = "selectedIndex";

  late Box box;
  int _selectedIndex = 0;

  int get selectedIndex => _selectedIndex;

  // Remove the constructor call to _init()

  // Provide a public async init method
  Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    Hive.init(dir.path);
    box = await Hive.openBox(boxName);

    _selectedIndex = box.get(indexKey, defaultValue: 0);
    notifyListeners();
  }

  void updateIndex(int newIndex) {
    if (_selectedIndex !=
        newIndex) { // Only update if the index actually changes
      _selectedIndex = newIndex;
      box.put(indexKey, newIndex);
      notifyListeners();
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(TaskAdapter());
  await Hive.openBox<Task>('tasks');
  final navigationProvider = NavigationProvider();
  await navigationProvider.init();

  final todosModel = TodosModel();
  await todosModel.init();

  runApp(
    MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => todosModel),
          ChangeNotifierProvider.value(value: navigationProvider), // Use .value for pre-initialized providers
        ],
        child: MaterialApp(
          home: ToDoApp(),
        )
    ),
  );
}


class ToDoApp extends StatelessWidget {

  final List<Widget> _pages = [
    TasksPage(), // Your refactored page for tasks
    Center(child: Text('Upcoming')),
    Center(child: Text('Calendar')),
  ];

  String _getTitleForIndex(int index) {
    switch (index) {
      case 0:
        return 'Tasks';
      case 1:
        return 'Upcoming';
      case 2:
        return 'Calendar';
      default:
        return 'Tasks';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to NavigationProvider to get the current index
    final navigationProvider = Provider.of<NavigationProvider>(context);
    // No need to listen to todosModel here if TasksPage handles it

    return Scaffold(
        //appBar: AppBar(
          //title: Text(_getTitleForIndex(navigationProvider.selectedIndex)),
        //),
        body: _pages[navigationProvider.selectedIndex], // Display page based on provider's state
        bottomNavigationBar: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.list),
              label: 'Tasks',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.upcoming),
              label: 'Upcoming',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today),
              label: 'Calendar',
            ),
          ],
          currentIndex: navigationProvider.selectedIndex,
          onTap: (index) {
            // Update the index via the provider.
            // No need for Provider.of with listen: false if you're just calling a method.
            context.read<NavigationProvider>().updateIndex(index);
          },
        ),
              );
            }
            }

class TasksPage extends StatefulWidget{
  @override
  TasksPageState createState() => TasksPageState();
}

class TasksPageState extends State<TasksPage> {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();

  void _showAddTaskModal(BuildContext context) {
    final TextEditingController _taskController = TextEditingController();
    final FocusNode _taskFocusNode = FocusNode();


    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      // Allows modal to resize when keyboard appears
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          // Push up by keyboard height
          padding: EdgeInsets.only(
            bottom: MediaQuery
                .of(ctx)
                .viewInsets
                .bottom + 20,
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
                    _addTask(context, _taskController, _taskFocusNode,),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () =>
                    _addTask(context, _taskController, _taskFocusNode,),
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


  void addTaskWithAnimation(Task task,BuildContext context) {
    Provider.of<TodosModel>(context, listen: false).addTaskAt(0,task);
    _listKey.currentState?.insertItem(0, duration: const Duration(milliseconds: 500)); // Assuming added at the start
  }




/// Adds the task to the list and closes the modal
void _addTask(BuildContext context, TextEditingController controller,
    FocusNode focusNode) {
  final text = controller.text.trim();
  if (text.isNotEmpty) {
    final todosModel = Provider.of<TodosModel>(context, listen: false);
    //final newTask=Task(title: text);
    //todosModel.addTaskAt(0, Task(title: text));
    todosModel.addTask(Task(title: text));
    _listKey.currentState?.insertItem(0, duration: Duration(milliseconds: 500));
    //pageKey.currentState?.addTaskWithAnimation(newTask,context);
    controller.clear(); // Clear text
    focusNode.requestFocus();

    //Navigator.of(context).pop(); // Close the modal
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<TodosModel>(
        builder: (context, todosModel, child) {
          return AnimatedList(
            key: _listKey,
            initialItemCount: todosModel.tasks.length,
            itemBuilder: (context, index, animation) {
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
                              (context, animation) =>
                              SizeTransition(
                                sizeFactor: animation,
                                child: ListTile( // Or your actual list item widget
                                  title: Text(task.title),
                                  leading: InkWell( // Replicate the leading part for consistent animation
                                    customBorder: const CircleBorder(),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: Colors.black, width: 2),
                                      ),
                                      width: 24,
                                      height: 24,
                                      child: const Icon(Icons.check, size: 16,
                                          color: Colors.grey),
                                    ),
                                  ),
                                ),
                              ),
                          duration: Duration(milliseconds: 100),
                        );
                      },
                      customBorder: const CircleBorder(),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black, width: 2),
                        ),
                        width: 24,
                        height: 24,
                        child: const Icon(Icons.check, size: 16, color: Colors
                            .red),
                      )
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TaskDetailsPage(task: task),
                      ),
                    );
                  },
                ),
              );
            },

          );
        },

      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddTaskModal(context);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}









