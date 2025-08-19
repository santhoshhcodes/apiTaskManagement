import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final taskName = TextEditingController();
  List<String> tasks = [];

  Future<void> saveTask() async {
    final url = Uri.parse(
      "https://taskmanagement-3efe7-default-rtdb.firebaseio.com/tasks.json",
    );

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json; charset=utf-8"
        },
      body: jsonEncode({
        'task': taskName.text.trim(),
        'completed': false, 
      }),
    );
  }

  Future<List<Map<String, dynamic>>> fetchTasks() async {
  
    final response = await http.get(Uri.parse(
      "https://taskmanagement-3efe7-default-rtdb.firebaseio.com/tasks.json",
    ));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>?;
      if (data == null)
       return [];
      List<Map<String, dynamic>> loadedTasks = [];
      data.forEach((key, value) {
        loadedTasks.add({
          'id': key,
          'task': value['task'],
          'completed': value['completed'] ?? false, 
        });
      });
      return loadedTasks;
    } else {
      throw Exception(" Error fetching tasks");
    }
  }

  Future<void> Completed(String id) async {
    final url = Uri.parse(
      "https://taskmanagement-3efe7-default-rtdb.firebaseio.com/tasks/$id.json",
    );

    final response = await http.patch(
      url,
      headers: {
        "Content-Type": "application/json; charset=utf-8"
        },
      body: jsonEncode({'completed': true}), 
    );

    if (response.statusCode == 200) {
      print("Task marked as completed");
    } else {
      print("Failed to update task: ${response.body}");
    }
  }

  /// Add new task dialog
  void addTaskDialog() {
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Add Task"),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: taskName,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: "Enter the Task",
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return "Please enter a task";
              }
              return null;
            },
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                await saveTask();
                taskName.clear();
                Navigator.pop(context);
                setState(() {

                }); // reload tasks
              }
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  /// Remove task locally (for demo)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Task Management")),
      body: FutureBuilder(
        future: fetchTasks(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                "No tasks yet. Add some with (+)",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            );
          }

          final pendingTasks = snapshot.data!
              .where((t) => t['completed'] == false).toList();
          final completedTasks = snapshot.data!
              .where((t) => t['completed'] == true).toList();

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    "Pending Tasks",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                ...pendingTasks.map(
                  (task) => Card(
                    child: ListTile(
                      title: Text(task['task']),
                      trailing: TextButton(
                        onPressed: () async {
                          await Completed(task['id']);
                          setState(() {});
                        },
                        child: Text(
                          "Complete",
                          style: TextStyle(color: Colors.green[700]),
                        ),
                      ),
                    ),
                  ),
                ),

                /// Completed Section
                /// Completed Section
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    "Completed Tasks",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                ...completedTasks.map(
                  (task) => Card(
                    color: Colors.grey[200],
                    child: ListTile(
                      title: Text(
                        task['task'],
                        style: const TextStyle(
                          decoration: TextDecoration.lineThrough,
                          color: Colors.grey,
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          final url = Uri.parse(
                            "https://taskmanagement-3efe7-default-rtdb.firebaseio.com/tasks/${task['id']}.json",
                          );

                          final response = await http.delete(url);

                          if (response.statusCode == 200) {
                            print("Task deleted");
                            setState(() {}); // refresh UI
                          } else {
                            print("Failed to delete: ${response.body}");
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: addTaskDialog,
      ),
    );
  }
}
