import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:orbital2020/DatabaseController.dart';
import 'package:orbital2020/DataContainers/TaskWithStatus.dart';
import 'package:orbital2020/GameWidget.dart';
import 'package:orbital2020/TaskStatusTile.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';
import 'dart:async';
import 'AppDrawer.dart';
import 'DataContainers/Task.dart';
import 'DataContainers/TaskStatus.dart';
import 'DataContainers/User.dart';
import 'Sort.dart';


class StudentMain extends StatefulWidget {
  StudentMain({Key key}) : super(key: key);

  @override
  _StudentMainState createState() => _StudentMainState();
}

class _StudentMainState extends State<StudentMain> {
  final DatabaseController db = DatabaseController();
  User _user;
  Stream<Set<TaskStatus>> _tasks;
  String _searchText;
  bool _searchBarActive;
  Sort _sortBy;
  List<DropdownMenuItem> _options = [
    DropdownMenuItem(child: Text("Name"), value: Sort.name,),
    DropdownMenuItem(child: Text("Due Date"), value: Sort.dueDate,),
    DropdownMenuItem(child: Text("Created By"), value: Sort.createdBy,),
    DropdownMenuItem(child: Text("Completion Status"), value: Sort.status,),
  ];

  @override
  void initState() {
    super.initState();
    _user = Provider.of<User>(context, listen: false);
    _tasks = db.getStudentTaskDetailsSnapshots(studentId: _user.id);
    _searchText = "";
    _searchBarActive = false;
    _sortBy = Sort.name;
  }

  void _activateSearchBar() {
    setState(() {
      _searchBarActive = true;
    });
  }

  void _deactivateSearchBar() {
    setState(() {
      _searchBarActive = false;
      _searchText = "";
    });
  }

  bool filteredTask(TaskWithStatus task) {
    return task.name.toLowerCase().startsWith(_searchText) ||
        (task.createdByName?.toLowerCase()?.startsWith(_searchText) ?? false) ||
        task.tags.where((tag) => tag.toLowerCase().startsWith(_searchText)).length > 0;
  }

  List<TaskWithStatus> sortAndFilter(List<TaskWithStatus> originalTasks) {
    List<TaskWithStatus> filtered = originalTasks.where((task) => filteredTask(task)).toList();
    switch (_sortBy) {
      case Sort.name:
        filtered.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        return filtered;
      case Sort.dueDate:
        filtered.sort((a, b) => a.dueDate.compareTo(b.dueDate));
        return filtered;
      case Sort.createdBy:
        filtered.sort((a, b) => a.createdByName.toLowerCase().compareTo(b.createdByName.toLowerCase()));
        return filtered;
      case Sort.status:
        filtered.sort((a, b) => a.getStatus().compareTo(b.getStatus()));
        return filtered;
    }
  }

  Widget _buildTaskList(Set<TaskStatus> tasks) {
    List<Stream<TaskWithStatus>> streamList = [];
    tasks.forEach((status) {
      streamList.add(db.getTaskWithStatus(status));
    });
    return StreamBuilder<List<TaskWithStatus>>(
      stream: CombineLatestStream.list(streamList),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          List<TaskWithStatus> filteredTasks = sortAndFilter(snapshot.data);
          return ListView.builder(
            itemCount: filteredTasks.length,
            itemBuilder: (context, index) {
              TaskWithStatus task = filteredTasks[index];
              return TaskStatusTile(
                task: task,
                isStudent: _user.accountType == "student",
                updateComplete: (value) {
                  db.updateTaskCompletion(task.id, _user.id, value);
                },
                updateVerify: (value) {},
                onFinish: () {},
              );
            },
          );
        } else {
          return CircularProgressIndicator();
        }
      },
    );
  }

  Widget buildAppBar() {
    if (_searchBarActive) {
      return AppBar(
        title: TextField(
          decoration: const InputDecoration(
            hintText: 'Search by name or tags',
          ),
          onChanged: (value) {
            setState(() {
              _searchText = value.toLowerCase();
            });
          },
          autofocus: true,
        ),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.cancel),
            tooltip: 'Cancel',
            onPressed: _deactivateSearchBar,
          )
        ],
      );
    } else {
      return AppBar(
        title: Text('Welcome ${_user.name}'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search',
            onPressed: _activateSearchBar,
          ),
        ],
      );
    }
  }

  Future<Null> refresh() async {
    await Future.microtask(() => setState(() {
      _tasks = db.getStudentTaskDetailsSnapshots(studentId: _user.id);
    }));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(),
      drawer: AppDrawer(),
      body: SafeArea(
            child: Column(
              children: <Widget>[
                AspectRatio(
                  aspectRatio: 3/2,
                  child: GameWidget(),
                ),
                Container(
                  color: Colors.green,
                  child: DropdownButtonFormField(
                          items: _options,
                          decoration: InputDecoration(
                            labelText: "Sort By: "
                          ),
                          onChanged: (value) => setState(() => _sortBy = value),
                          value: _sortBy,
                      )
                  ),
                Expanded(
                  child: Scrollbar(
                    child: RefreshIndicator(
                      onRefresh: refresh,
                      child: StreamBuilder<Set<TaskStatus>>(
                        stream: _tasks,
                        builder: (context, snapshot) {
                          if(snapshot.hasData) {
                            print(snapshot.data);
                            if(snapshot.data.length > 0) {
                              return _buildTaskList(snapshot.data);
                            } else {
                              return Text('No tasks!');
                            }
                          } else {
                            return CircularProgressIndicator();
                          }
                        },
                      )
                    ),
                  ),
                ),
              ],
            )
        ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        tooltip: 'Add',
        onPressed: () {
          Navigator.of(context).pushNamed('student_addTask');
        },
      ),
    );
  }
}