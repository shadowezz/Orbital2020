import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:orbital2020/DataContainers/Group.dart';
import 'package:orbital2020/DataContainers/Student.dart';
import 'package:orbital2020/DataContainers/Task.dart';
import 'package:orbital2020/DataContainers/User.dart';
import 'package:orbital2020/DatabaseController.dart';
import 'package:orbital2020/LoadingDialog.dart';
import 'package:orbital2020/TeacherAppDrawer.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';

import 'Sort.dart';

class TeacherGroupView extends StatefulWidget {
  final Group group;

  TeacherGroupView({Key key, @required this.group}) : super(key: key);

  @override
  _TeacherGroupViewState createState() => _TeacherGroupViewState();
}

class _TeacherGroupViewState extends State<TeacherGroupView> with SingleTickerProviderStateMixin{
  DatabaseController db;

  User _user;

  Stream<Set<String>> _tasks;
  Stream<Set<Student>> _students;
  TabController _tabController;
  String _searchText;
  bool _searchBarActive;
  Sort _sortTask;
  List<DropdownMenuItem> _options = [
    DropdownMenuItem(child: Text("Name"), value: Sort.name,),
    DropdownMenuItem(child: Text("Due Date"), value: Sort.dueDate,),
  ];

  @override
  void initState() {
    super.initState();
    db = Provider.of<DatabaseController>(context, listen: false);

    _user = Provider.of<User>(context, listen: false);

    _tabController = TabController(length: 2, vsync: this, initialIndex: 0);
    _searchText = '';
    _searchBarActive = false;
    _tasks = db.getGroupTaskSnapshots(
        teacherId: _user.id,
        groupId: widget.group.id,
    );
    _students = db.getGroupStudentSnapshots(
        teacherId: _user.id,
        groupId: widget.group.id,
    );
    _sortTask = Sort.name;
  }

  bool filtered(String listItem) {
    return listItem.toLowerCase().startsWith(_searchText);
  }

  List<Task> sortAndFilter(List<Task> originalTasks) {
    List<Task> filteredTasks = originalTasks.where((task) => filtered(task.name)).toList();
    switch (_sortTask) {
      case Sort.name:
        filteredTasks.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        return filteredTasks;
      case Sort.dueDate:
        filteredTasks.sort((a, b) {
          if (a.dueDate == null && b.dueDate == null) {
            return 0;
          } else if (a.dueDate == null) {
            return 1;
          } else if (b.dueDate == null) {
            return -1;
          } else {
            return a.dueDate.compareTo(b.dueDate);
          }
        });
        return filteredTasks;
      default:
        filteredTasks.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        return filteredTasks;
    }
  }

  Widget _buildTaskList(Set<String> tasks) {
    List<Stream<Task>> streamList = [];
    tasks.forEach((taskId) {
      streamList.add(db.getTask(taskId));
    });

    return StreamBuilder<List<Task>>(
      stream: CombineLatestStream.list(streamList),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          List<Task> filteredTasks = sortAndFilter(snapshot.data);
          return ListView.builder(
              itemCount: filteredTasks.length,
              itemBuilder: (context, index) {
                Task task = filteredTasks[index];
                return ListTile(
                  title: Text(task.name),
                  subtitle: task.dueDate != null
                      ? Text("Due: " + DateFormat('y-MM-dd').format(task.dueDate))
                      : Container(width: 0, height: 0,),
                  onTap: () {
                    Map<String, dynamic> arguments = {
                      'task': task,
                      'group': widget.group
                    };
                    Navigator.of(context).pushNamed(
                        'teacher_taskView', arguments: arguments);
                  },
                );
              }
          );
        } else {
          return Center(child: CircularProgressIndicator());
        }
      },
    );
  }

  Widget _buildStudentList(Set<Student> students) {

    return ListView.builder(
        itemCount: students.length,
        itemBuilder: (context, index) {
          Student student = students.elementAt(index);
          if (filtered(student.name)) {
            return ListTile(
              title: Text(student.name),
              onTap: () {
                Map<String, dynamic> arguments = {
                  'student': student,
                  'group': widget.group
                };
                Navigator.of(context).pushNamed(
                    'teacher_studentView', arguments: arguments);
              },
            );
          } else {
            return Container(width: 0.0, height: 0.0,);
          }
        });
  }

  Widget _buildTasksTabView() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: DropdownButtonFormField(
            items: _options,
            decoration: InputDecoration(
                labelText: "Sort By: "
            ),
            onChanged: (value) => setState(() => _sortTask = value),
            value: _sortTask,
          ),
        ),
        StreamBuilder(
            stream: _tasks,
            builder: (context, snapshot) {
              if(snapshot.hasData) {
                if(snapshot.data.length > 0) {
                  return Expanded(child: _buildTaskList(snapshot.data));
                } else {
                  return Expanded(child: Center(child: Text('No tasks assigned!')));
                }
              } else {
                return Expanded(child: Center(child: CircularProgressIndicator()));
              }
            },
        ),

      ]
    );
  }

  Widget _buildStudentsTabView() {
     return StreamBuilder<Set<Student>>(
        stream: _students,
        builder: (context, snapshot) {
          if(snapshot.hasData) {
            if(snapshot.data.length > 0) {
              return _buildStudentList(snapshot.data);
            } else {
              return Center(child: Text('No students assigned!'));
            }
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
     );

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

  Widget buildAppBar() {
    if(_searchBarActive) {
      return AppBar(
        title: TextField(
          decoration: const InputDecoration(
            hintText: 'Search',
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
        bottom: TabBar(
          controller: _tabController,
          tabs: <Widget>[
            Tab(child: Text('Tasks'),),
            Tab(child: Text('Students'),),
          ],
        ),
      );
    } else {
      return AppBar(
        title: Text(widget.group.name),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search',
            onPressed: _activateSearchBar,
          ),
          PopupMenuButton(
            itemBuilder: _actionMenuBuilder,
            onSelected: _onActionMenuSelected,
          )
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: <Widget>[
            Tab(child: Text('Tasks'),),
            Tab(child: Text('Students'),),
          ],
        ),
      );
    }
  }

  List<PopupMenuItem> _actionMenuBuilder(BuildContext context) {
    return [
      PopupMenuItem(
        value: 'delete',
        child: Text('Delete', style: TextStyle(color: Colors.red),),
      ),
    ];
  }

  void _onActionMenuSelected(dynamic value) {
    switch(value) {
      case 'delete':
        _onDelete();
        break;
      default:
        print(value.toString() + " Not Implemented");
    }
  }

  Future<void> _onDelete() {
    BuildContext viewContext = context;
    return showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Are you sure you want to delete the group?'),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Text('This action is permanent!'),
                ],
              ),
            ),
            actions: <Widget>[
              FlatButton(
                child: Text('YES'),
                onPressed: () {
                  Navigator.of(context).pop();
                  LoadingDialog loadingDialog = LoadingDialog(context: context, text: 'Deleting Group...');
                  loadingDialog.show();

                  db.teacherDeleteGroup(teacherId: _user.id, group: widget.group)
                      .then((value) {
                    loadingDialog.close();
                    Navigator.of(viewContext).pop();
                  });
                },
              ),
              FlatButton(
                child: Text('NO'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        }
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(),
      drawer: TeacherAppDrawer(),
      body: TabBarView(
        controller: _tabController,
        children: <Widget>[
          _buildTasksTabView(),
          _buildStudentsTabView(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        tooltip: 'Assign Task',
        onPressed: () {
          if(_tabController.index == 0) {
            Navigator.of(context).pushNamed('teacher_addTask', arguments: widget.group);
          } else if(_tabController.index == 1) {
            Navigator.of(context).pushNamed('teacher_addStudentToGroup', arguments: widget.group);
          }
        },
      ),
    );
  }
}