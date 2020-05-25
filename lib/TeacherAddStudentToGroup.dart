import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:orbital2020/DataContainers/Group.dart';
import 'package:orbital2020/DataContainers/Student.dart';
import 'package:orbital2020/DataContainers/User.dart';

import 'package:orbital2020/DatabaseController.dart';
import 'package:provider/provider.dart';

//View shown when teacher is assigning a task to a student
class TeacherAddStudentToGroup extends StatefulWidget {
  final Group group;

  TeacherAddStudentToGroup({Key key, @required this.group}) : super(key: key);


  @override
  _TeacherAddStudentToGroupState createState() => _TeacherAddStudentToGroupState();
}

class _TeacherAddStudentToGroupState extends State<TeacherAddStudentToGroup> {
  final DatabaseController db = DatabaseController();

  User _user;
  Stream<List<Student>> _allStudents;
  Set<Student> _studentsToAdd;
  String _searchText;


  @override
  void initState() {
    super.initState();
    _user = Provider.of<User>(context, listen: false);
    _allStudents = db.getAllStudentsSnapshots();
    _studentsToAdd = Set();
    _searchText = "";
  }

  List<Widget> buildChips() {
    List<Widget> studentChips = <Widget>[];
    for(Student student in _studentsToAdd) {
      studentChips.add(Chip(
        label: Text(student.name),
        onDeleted: () {
          deleteStudent(student);
        },
      ));
    }
    return studentChips;
  }

  void deleteStudent(Student student) {
    setState(() {
      _studentsToAdd.remove(student);
    });
  }

  void addStudent(Student student) {
    setState(() {
      _studentsToAdd.add(student);
    });
  }

  Widget buildSuggestions() {
    return StreamBuilder(
      stream: _allStudents,
      builder: (context, snapshot) {
        if(snapshot.hasData) {
          List<Student> allStudents = snapshot.data;
          List<Student> suggestions = allStudents.where((element) =>
              element.name.startsWith(_searchText)
                  && !widget.group.students.contains(element)
                  && !_studentsToAdd.contains(element)).toList();
          return ListView.builder(
              itemCount: suggestions.length,
              itemBuilder: (context, index) {
                Student student = suggestions[index];
                return ListTile(
                  title: Text(student.name),
                  onTap: () {
                    addStudent(student);
                  },
                );
              }
          );
        } else {
          return CircularProgressIndicator();
        }
      },
    );
  }

  Future<void> submitAdd() {
    return db.teacherAddStudentsToGroup(teacherId: _user.id,
        group: widget.group,
        students: _studentsToAdd);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Students'),
      ),
      body: SafeArea(
          child: Column(
            children: <Widget>[
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Add Students',
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
            ],
          )
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.check),
        tooltip: 'Add Students',
        onPressed: () {
          submitAdd()
              .then((value) => Navigator.pop(context));
        },
      ),
    );
  }
}