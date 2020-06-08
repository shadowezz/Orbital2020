import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:orbital2020/DataContainers/Group.dart';
import 'package:orbital2020/DataContainers/Student.dart';
import 'package:orbital2020/DataContainers/User.dart';

import 'package:orbital2020/DatabaseController.dart';
import 'package:orbital2020/DataContainers/Task.dart';
import 'package:provider/provider.dart';

import 'DataContainers/TaskStatus.dart';

//View shown when teacher is assigning a task to a student
class TeacherAssignTask extends StatefulWidget {
  final Student student;
  final Group group;

  TeacherAssignTask({Key key, @required this.student, @required this.group}) : super(key: key);


  @override
  _TeacherAssignTaskState createState() => _TeacherAssignTaskState();
}

class _TeacherAssignTaskState extends State<TeacherAssignTask> {
  final DatabaseController db = DatabaseController();

  User _user;

//  Stream<Set<Task>> _allTasks;
//  Stream<Set<TaskStatus>> _alreadyAssigned;
//  Stream<Set<String>> _allTasks;
//  Stream<Set<String>> _alreadyAssigned;
  Set<Task> _tasks;
  String _searchText;


  @override
  void initState() {
    super.initState();
    _user = Provider.of<User>(context, listen: false);
//    _allTasks = db.getGroupTaskSnapshots(teacherId: _user.id, groupId: widget.group.id);
//    _alreadyAssigned = db.getStudentTaskDetailsSnapshots(studentId: widget.student.id);
//    _allTasks = db.getGroupTaskSnapshots(teacherId: _user.id, groupId: widget.group.id);
//    _alreadyAssigned = db.getStudentTaskDetailsSnapshots(studentId: widget.student.id).map((tasks) {
//      Set<String> set = Set();
//      for(TaskStatus task in tasks) {
//        set.add(task.id);
//      }
//      return set;
//    });
    _tasks = Set();
    _searchText = "";
  }

  List<Widget> buildChips() {
    List<Widget> taskChips = <Widget>[];
    for(Task task in _tasks) {
      taskChips.add(Chip(
        label: Text(task.name),
        onDeleted: () {
          deleteTask(task);
        },
      ));
    }
    return taskChips;
  }

  void deleteTask(Task task) {
    setState(() {
      _tasks.remove(task);
    });
  }

  void addTask(Task task) {
    setState(() {
      _tasks.add(task);
    });
  }

  bool filtered(Task task) {
    return task.name.startsWith(_searchText) && !_tasks.contains(task);
  }

  Widget buildSuggestions() {
    return StreamBuilder(
      stream: db.getUnassignedTasks(_user.id, widget.group.id, widget.student.id), //_allTasks,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
//      builder: (context, allTasksSnapshot) =>
//        StreamBuilder(
//          stream: _alreadyAssigned,
//          builder: (context, alreadyAssignedSnapshot) {
//            if (allTasksSnapshot.hasData && alreadyAssignedSnapshot.hasData) {
////              Set<Task> allTasks = allTasksSnapshot.data;
////              Set<Task> alreadyAssigned = alreadyAssignedSnapshot.data;
//              List<String> allTasks = allTasksSnapshot.data.toList();
//              Set<String> alreadyAssigned = alreadyAssignedSnapshot.data;
//              print("len here" + alreadyAssigned.length.toString());
//              print(allTasks.toString());
//              print(alreadyAssigned.toString());

//              for(Task task in allTasks) {
//                if(alreadyAssigned.contains(task)) {
//                  print(task.toString());
//                }
//              }

//              List<Task> suggestions = allTasks.where((element) =>
//              element.name.startsWith(_searchText)
//                  && !alreadyAssigned.contains(element)
//                  && !_tasks.contains(element)).toList();


//              return ListView.builder(
//                  itemCount: suggestions.length,
//                  itemBuilder: (context, index) {
//                    Task task = suggestions[index];
//                    return ListTile(
//                      title: Text(task.name),
//                      onTap: () {
//                        addTask(task);
//                      },
//                    );
//                  }
//              );
              return ListView.builder(
                  itemCount: snapshot.data.length,
                  itemBuilder: (context, index) {
                    String taskId = snapshot.data.elementAt(index);
                    return StreamBuilder<Task>(
                      stream: db.getTask(taskId),
                      builder: (context, snapshot) {
                        if (snapshot.hasData && filtered(snapshot.data)) {
                          return ListTile(
                            title: Text(snapshot.data.name),
                            onTap: () {
                              addTask(snapshot.data);
                            },
                          );
                        } else if (snapshot.hasData) {
                          return Container(width: 0.0, height: 0.0,);
                        } else {
                          return CircularProgressIndicator();
                        }
                      }
                    );
                  }
              );
            } else {
              return CircularProgressIndicator();
            }
          }
        );
  }

  Future<void> submitAssignment() {
    return db.teacherAssignTasksToStudent(_tasks, widget.student);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assign Task'),
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            TextField(
              decoration: const InputDecoration(
                labelText: 'Assign Tasks',
              ),
              onChanged: (value) {
                setState(() {
                  _searchText = value;
                });
              },
            ),
            Wrap(
              children: buildChips(),
            ),
            Expanded(
              child: buildSuggestions(),
            ),
            RaisedButton(
              child: const Text('Add New Task'),
              onPressed: () {

              },
            )
          ],
        )
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.check),
        tooltip: 'Assign Task',
        onPressed: () {
          submitAssignment()
              .then((value) => Navigator.pop(context));
        },
      ),
    );
  }
}