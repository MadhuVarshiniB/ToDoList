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

class TasksPage extends StatefulWidget {
  @override
  TasksPageState createState() => TasksPageState();
}

class TasksPageState extends State<TasksPage> {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  final List<Task> _items = [];

  @override
  void initState() {
    super.initState();
    final todosModel = Provider.of<TodosModel>(context, listen: false);

    // Load existing tasks (newest first)
    _items.addAll(todosModel.tasks);

    // Listen for item changes and animate
    todosModel.addListener(() {
      final updatedList = todosModel.tasks;
      // If new task added at top
      if (updatedList.length > _items.length) {
        final newTask = updatedList.first;
        _items.insert(0, newTask);
        _listKey.currentState?.insertItem(0, duration: Duration(milliseconds: 300));
      }
    });
  }

  void _showAddTaskModal(BuildContext context) {
    final TextEditingController _taskController = TextEditingController();
    final FocusNode _taskFocusNode = FocusNode();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _taskController,
                focusNode: _taskFocusNode,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Enter new task',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) => _addTask(context, _taskController, _taskFocusNode),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => _addTask(context, _taskController, _taskFocusNode),
                child: const Text("Add Task"),
              ),
            ],
          ),
        );
      },
    ).whenComplete(() {
      _taskController.dispose();
      _taskFocusNode.dispose();
    });
  }

  void _addTask(BuildContext context, TextEditingController controller, FocusNode focusNode) {
    final text = controller.text.trim();
    if (text.isNotEmpty) {
      Provider.of<TodosModel>(context, listen: false).addTask(Task(title: text));
      controller.clear();
      focusNode.requestFocus();
    }
  }

  void _removeTask(int index, Task task) {
    Provider.of<TodosModel>(context, listen: false).deleteTask(task);
    final removedItem = _items.removeAt(index);
    _listKey.currentState?.removeItem(
      index,
          (context, animation) => _buildItem(removedItem, animation),
      duration: Duration(milliseconds: 300),
    );
  }

  Widget _buildItem(Task task, Animation<double> animation, {int? index}) {
    return FadeTransition(
      opacity: animation,
      child: SizeTransition(
        sizeFactor: animation,
        child:Container(
          margin: const EdgeInsets.symmetric(vertical: 4.0),
          decoration: BoxDecoration(
            color: Color(0xFFCBB7CB), // ✅ background color#D8BFD8
            border: Border.all(color: Color(0xFFAF80AF), width: 2), // ✅ border
            borderRadius: BorderRadius.circular(10), // ✅ rounded corners
          ),
          child: ListTile(
            title: Text(task.title),
            leading: InkWell(
              onTap: () {
                if (index != null) {
                  task.isCompleted = true;

                }
                Future.delayed(const Duration(milliseconds: 200), () {
                  _removeTask(index!, task);
                });
              },
              customBorder: const CircleBorder(),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all( color: task.isCompleted ? Colors.black12 : Colors.black,
                    width: 2,),
                  color: task.isCompleted ? Colors.purple.withOpacity(0.2) : Colors.transparent,
                ),

                width: 24,
                height: 24,
                child: task.isCompleted
                    ? const Icon(Icons.check, size: 16, color: Colors.deepPurple)
                    : null,
              ),
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
          ),
        )
      );

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Align(
          alignment: Alignment.centerLeft,
          child: Text('Tasks'),
        ),              // Optional: center the title
        //backgroundColor: Colors.blue,   // Optional: change background color

      ),
      drawer: Drawer(  // <-- The side navigation panel
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.purple,
                gradient: LinearGradient(
                  colors: [Colors.purple, Colors.blue],
                ),
              ),
              child: Text(
                'TO DO APP',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.calendar_month_rounded),
              title: Text('Habit Tracker'),
              onTap: () {
                // Navigate to home or close drawer
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.timer),
              title: Text('Time Tracker'),
              onTap: () {
                // Navigate to settings or close drawer
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text('Settings'),
              onTap: () {
                // Navigate to settings or close drawer
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      body: AnimatedList(
        key: _listKey,
        initialItemCount: _items.length,
        itemBuilder: (context, index, animation) {
          final task = _items[index];
          return _buildItem(task, animation, index: index);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTaskModal(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
