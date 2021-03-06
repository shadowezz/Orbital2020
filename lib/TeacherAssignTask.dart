import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:orbital2020/DataContainers/Group.dart';
import 'package:orbital2020/DataContainers/Student.dart';
import 'package:orbital2020/DataContainers/User.dart';

import 'package:orbital2020/DatabaseController.dart';
import 'package:orbital2020/DataContainers/Task.dart';
import 'package:orbital2020/LoadingDialog.dart';
import 'package:provider/provider.dart';

//View shown when teacher is assigning tasks to a student
class TeacherAssignTask extends StatefulWidget {
  final Student student;
  final Group group;

  TeacherAssignTask({Key key, @required this.student, @required this.group}) : super(key: key);


  @override
  _TeacherAssignTaskState createState() => _TeacherAssignTaskState();
}

class _TeacherAssignTaskState extends State<TeacherAssignTask> {
  DatabaseController db;

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
    db = Provider.of<DatabaseController>(context, listen: false);
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
      stream: db.getUnassignedTasks(_user.id, widget.group.id, widget.student.id),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data.length > 0) {
            return Expanded(
              child: ListView.builder(
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
                            return Center(child: CircularProgressIndicator());
                          }
                        }
                    );
                  }
              ),
            );
          } else if (snapshot.hasData) {
            return Expanded(child: Center(child: Text("No tasks to assign.")));
          } else {
            return Expanded(child: Center(child: CircularProgressIndicator()));
          }
      });
  }

  Future<bool> submitAssignment() {
    if (_tasks.isEmpty) {
      showDialog(
        context: context,
        builder: (context) =>
            AlertDialog(
              title: Text("Error"),
              content: Text("No tasks selected."),
              actions: <Widget>[
                FlatButton(
                  child: Text('Ok'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
      );
      return Future.value(false);
    } else {
      LoadingDialog loadingDialog = LoadingDialog(
          context: context, text: 'Assigning...');
      loadingDialog.show();

      return db.teacherAssignTasksToStudent(_tasks, widget.student).then((
          value) {
        loadingDialog.close();
        return true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: BackButtonIcon(),
          onPressed: Navigator.of(context).maybePop,
          tooltip: 'Back',
        ),
        title: const Text('Assign Task To Student'),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 5.0),
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
            buildSuggestions(),
          ],
        )
      ),
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.check),
        tooltip: 'Assign Task',
        onPressed: () {
          submitAssignment()
              .then((value) {
                if (value) {
                  Navigator.pop(context);
                }
              });
        },
      ),
    );
  }
}