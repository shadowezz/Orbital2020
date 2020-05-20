import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:orbital2020/DataContainers/Group.dart';
import 'package:orbital2020/DataContainers/Student.dart';
import 'package:orbital2020/DataContainers/Task.dart';
import 'package:orbital2020/DatabaseController.dart';
import 'package:orbital2020/TeacherStudentView.dart';
import 'package:orbital2020/TeacherTaskView.dart';

import 'AppDrawer.dart';


class TeacherGroupView extends StatefulWidget {
  final String userId;
  final Group group;

  TeacherGroupView({Key key, this.userId, this.group}) : super(key: key);

  @override
  _TeacherGroupViewState createState() => _TeacherGroupViewState();
}

class _TeacherGroupViewState extends State<TeacherGroupView> {
  final DatabaseController db = DatabaseController();

  Stream<List<Task>> _tasks;
  Stream<List<Student>> _students;

  @override
  void initState() {
    super.initState();
    _tasks = db.getGroupTaskSnapshots(
        teacherId: widget.userId,
        groupId: widget.group.id,
    );
    _students = db.getGroupStudentSnapshots(
        teacherId: widget.userId,
        groupId: widget.group.id,
    );
  }

  Widget _buildTaskList(List<Task> tasks) {
    return ListView.builder(
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          Task task = tasks[index];
          return ListTile(
            title: Text(task.name),
            subtitle: Text("Due: " + DateFormat('dd/MM/y').format(task.dueDate)),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => TeacherTaskView(userId: widget.userId, task: task,)),
              );
            },
          );
        }
    );
  }

  Widget _buildStudentList(List<Student> students) {
    return ListView.builder(
        itemCount: students.length,
        itemBuilder: (context, index) {
          Student student = students[index];
          return ListTile(
            title: Text(student.name),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => TeacherStudentView(userId: widget.userId, student: student,)),
              );
            },
          );
        }
    );
  }

  Widget _buildTasksTabView() {
    return Scrollbar(
      child: RefreshIndicator(
          onRefresh: _refreshTasks,
          child: StreamBuilder(
            stream: _tasks,
            builder: (context, snapshot) {
              if(snapshot.hasData) {
                if(snapshot.data.length > 0) {
                  return _buildTaskList(snapshot.data);
                } else {
                  return Text('No tasks assigned!');
                }
              } else {
                return CircularProgressIndicator();
              }
            },
          )
      ),
    );
  }

  Widget _buildStudentsTabView() {
    return Scrollbar(
      child: RefreshIndicator(
          onRefresh: _refreshStudents,
          child: StreamBuilder(
            stream: _students,
            builder: (context, snapshot) {
              if(snapshot.hasData) {
                if(snapshot.data.length > 0) {
                  return _buildStudentList(snapshot.data);
                } else {
                  return Text('No students assigned!');
                }
              } else {
                return CircularProgressIndicator();
              }
            },
          )
      ),
    );
  }

  Future<Null> _refreshTasks() async {
    await Future.microtask(() => setState(() {
      _tasks = db.getGroupTaskSnapshots(
        teacherId: widget.userId,
        groupId: widget.group.id,
      );
    }));
  }

  Future<Null> _refreshStudents() async {
    await Future.microtask(() => setState(() {
      _students = db.getGroupStudentSnapshots(
        teacherId: widget.userId,
        groupId: widget.group.id,
      );
    }));
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.group.name),
          actions: <Widget>[
            IconButton(
              icon: const Icon(Icons.search),
              tooltip: 'Search',
              onPressed: () {

              },
            ),
          ],
          bottom: TabBar(
            tabs: <Widget>[
              Tab(child: Text('Tasks'),),
              Tab(child: Text('Students'),),
            ],
          ),
        ),
        drawer: AppDrawer(),
        body: TabBarView(
          children: <Widget>[
            _buildTasksTabView(),
            _buildStudentsTabView(),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          child: const Icon(Icons.add),
          tooltip: 'Assign Task',
          onPressed: () {

          },
        ),
      ),
    );
  }
}