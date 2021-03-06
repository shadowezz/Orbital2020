import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:form_field_validator/form_field_validator.dart';
import 'package:intl/intl.dart';
import 'package:orbital2020/DataContainers/Group.dart';
import 'package:orbital2020/DataContainers/Task.dart';
import 'package:orbital2020/DataContainers/TaskStatus.dart';
import 'package:orbital2020/DatabaseController.dart';
import 'package:orbital2020/LoadingDialog.dart';
import 'package:orbital2020/StudentStatusTile.dart';
import 'package:orbital2020/TaskProgressIndicator.dart';
import 'package:orbital2020/DataContainers/Student.dart';
import 'package:orbital2020/TeacherAppDrawer.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';
import 'DataContainers/StudentWithStatus.dart';
import 'Sort.dart';


class TeacherTaskView extends StatefulWidget {
  final Task task;
  final Group group;

  TeacherTaskView({Key key, @required this.task, @required this.group}) : super(key: key);

  @override
  _TeacherTaskViewState createState() => _TeacherTaskViewState();
}


class _TeacherTaskViewState extends State<TeacherTaskView> with SingleTickerProviderStateMixin{

  DatabaseController db;
  final _mainFormKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _dueDateController = TextEditingController();
  final _tagController = TextEditingController();


  Stream<List<Student>> _students;
  String _searchText;
  bool _searchBarActive;
  TabController _tabController;
  bool _canSearch;
  Sort _sortBy;
  List<DropdownMenuItem> _options = [
    DropdownMenuItem(child: Text("Name"), value: Sort.name,),
    DropdownMenuItem(child: Text("Completion Status"), value: Sort.status,),
  ];

  @override
  void initState() {
    super.initState();
    db = Provider.of<DatabaseController>(context, listen: false);
    _students = db.getStudentsWithTask(widget.task.id);
    _searchText = '';
    _searchBarActive = false;
    _tabController = TabController(length: 2, vsync: this, initialIndex: 0);
    _tabController.addListener(onTabChange);
    _canSearch = false;
    _descriptionController.text = widget.task.description;
    _dueDateController.text = widget.task.dueDate != null ?
    DateFormat('y-MM-dd').format(widget.task.dueDate) :
    "";
    _sortBy = Sort.name;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  bool filtered(String studentName) {
    return studentName.toLowerCase().startsWith(_searchText);
  }

  List<StudentWithStatus> sortAndFilter(List<StudentWithStatus> original) {
    List<StudentWithStatus> filteredStudent = original.where((student) => filtered(student.name)).toList();
    switch (_sortBy) {
      case Sort.name:
        filteredStudent.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        return filteredStudent;
      case Sort.status:
        filteredStudent.sort((a, b) => a.getStatus().compareTo(b.getStatus()));
        return filteredStudent;
      default:
        filteredStudent.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        return filteredStudent;
    }
  }

  Widget _buildStudentList(List<Student> students) {
    List<Stream<StudentWithStatus>> streamList = [];
    students.forEach((student) {
      streamList.add(db.getStudentWithStatus(student, widget.task.id));
    });
    return Expanded(
      child: StreamBuilder(
        stream: CombineLatestStream.list(streamList),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            List<StudentWithStatus> filteredStudents = sortAndFilter(snapshot.data);
            return ListView.builder(
              itemCount: filteredStudents.length,
              itemBuilder: (context, index) {
                StudentWithStatus student = filteredStudents[index];
                return StudentStatusTile(
                  student: student,
                  isStudent: false,//_user.accountType == "student",
                  updateComplete: (value) {
                    db.updateTaskCompletion(widget.task.id, student.id, value, true);
                  },
                  updateVerify: (value) {
                    db.updateTaskVerification(widget.task.id, student.id, value);
                  },
                  onFinish: () {},
                );
              },
            );
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }

  List<PopupMenuItem> _actionMenuBuilder(BuildContext context) {
    return [
      PopupMenuItem(
        value: 'delete',
        child: Text('Delete', style: TextStyle(color: Colors.red),),
      )
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
            title: Text('Are you sure you want to delete the task?'),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Text('This action is permanent! The task will also be deleted for all assigned students.'),
                ],
              ),
            ),
            actions: <Widget>[
              FlatButton(
                child: Text('YES'),
                onPressed: () {
                  Navigator.of(context).pop();
                  LoadingDialog loadingDialog = LoadingDialog(context: context, text: 'Deleting Task...');
                  loadingDialog.show();

                  db.teacherDeleteTask(task: widget.task, group: widget.group)
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
    if (_searchBarActive) {
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
      );
    } else {
      return AppBar(
        title: Text(widget.task.name),
        actions: <Widget>[
          _canSearch ? IconButton(
            icon: Icon(Icons.search),
            onPressed: _activateSearchBar,
          ) : Container(width: 0, height: 0,),
          PopupMenuButton(
            itemBuilder: _actionMenuBuilder,
            onSelected: _onActionMenuSelected,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: <Widget>[
            Tab(child: Text("Details"),),
            Tab(child: Text("Assigned"),),
          ],
        ),
      );
    }
  }

  void onTabChange() {
    setState(() {
      _canSearch = _tabController.index == 0 ? false : true;
      if(_mainFormKey.currentState != null) {
        submit();
      }
    });
  }

  Widget buildProgressIndicator(int completed, int total) {
    return AspectRatio(
      aspectRatio: 3 / 1.5,
      child: Container(
          padding: EdgeInsets.all(10),
          child: CustomPaint(
            foregroundPainter: TaskProgressIndicator(total > 0 ?
            completed / total
                : 0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text("$completed/$total",
                  style: TextStyle(fontSize: 24,
                      fontWeight: FontWeight.bold),),
                Text("Completed",
                  style: TextStyle(fontSize: 16),)
              ],
            ),
          )
      ),
    );
  }


  Widget buildAssignedTab() {
    return SafeArea(
        child: Column(
          children: <Widget>[
            StreamBuilder(
              stream: _students,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  int total= snapshot.data.length;
                  int completed = total;
                  if (total > 0) {
                    List<Stream<TaskStatus>> streamList = [];
                    snapshot.data.forEach((Student student) {
                      streamList.add(db.getStudentTaskStatus(
                          student.id, widget.task.id));
                    });

                    return StreamBuilder<List<TaskStatus>>(
                        stream: CombineLatestStream.list(streamList),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            completed = snapshot.data
                                .where((task) => task.completed)
                                .length;
                            return buildProgressIndicator(completed, total);
                          } else {
                            return Center(child: CircularProgressIndicator());
                          }
                        }
                    );
                  } else {
                    return buildProgressIndicator(completed, total);
                  }
                } else {
                  return Center(child: CircularProgressIndicator());
                }
              },
            ),
            Container(
                color: Colors.green,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: DropdownButtonFormField(
                    items: _options,
                    decoration: InputDecoration(
                        labelText: "Sort By: "
                    ),
                    onChanged: (value) => setState(() => _sortBy = value),
                    value: _sortBy,
                  )
              )
            ),
            StreamBuilder(
              stream: _students,
              builder: (context, snapshot) {
                if(snapshot.hasData) {
                  if(snapshot.data.length > 0) {
                    return _buildStudentList(snapshot.data);
                  } else {
                    return Padding(
                      padding: const EdgeInsets.only(top: 80),
                      child: Text('No students assigned!'),
                    );
                  }
                } else {
                  print('here');
                  return Expanded(child: Center(child: CircularProgressIndicator()));
                }
              },
            )
          ],
        ),
      );
  }

  Future<DateTime> setDueDate(BuildContext context) async {
    DateTime initialDate;
    if (widget.task.dueDate == null) {
      initialDate = DateTime.now();
    } else if (widget.task.dueDate.isAfter(DateTime.now())) {
      initialDate = widget.task.dueDate;
    } else {
      initialDate = DateTime.now();
    }
    return showDatePicker(
        context: context,
        initialDate: initialDate,
        firstDate: DateTime.now(),
        lastDate: DateTime(2101)
    );
  }

  List<Widget> getTagChips() {
    List<Widget> tagChips = <Widget>[];
    for(String tag in widget.task.tags) {
      tagChips.add(Chip(
        label: Text(tag),
        onDeleted: () {
          deleteTag(tag);
        },
      ));
    }
    return tagChips;
  }

  void deleteTag(String tag) {
    setState(() {
      widget.task.tags.remove(tag);
    });
  }

  void addTag(String tag) {
    setState(() {
      widget.task.tags.add(tag);
    });
  }


  String validateDueDate(String value) {
    if (value == "") {
      return null;
    }
    String checkFormat = DateValidator("y-MM-dd", errorText: "Invalid date format! Should be y-MM-dd.").call(value);
    if (checkFormat != null){
      return checkFormat;
    } else {
      return null;
    }
  }

  Future<bool> submit() {
    if (_mainFormKey.currentState.validate()) {
      _mainFormKey.currentState.save();
      return db.updateTaskDetails(task: widget.task).then((value) => true);
    }
    return Future.value(false);
  }

  Widget buildDetailsTab() {
    return SafeArea(
        child: Form(
            key: _mainFormKey,
            onWillPop: () => submit().then((value) => value),
            child: ListView(
                padding: EdgeInsets.symmetric(horizontal: 5),
                children: <Widget>[
                  AspectRatio(
                    aspectRatio: 3/2,
                    child: TextFormField(
                      key: Key('description'),
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        alignLabelWithHint: true,
                        labelText: 'Description',
                        border: InputBorder.none,
                        focusedBorder: UnderlineInputBorder(),
                      ),
                      textAlignVertical: TextAlignVertical.top,
                      expands: true,
                      minLines: null,
                      maxLines: null,
                      onSaved: (value) => widget.task.description = value,
                    ),
                  ),
                  Row(
                    children: <Widget>[
                      Expanded(
                          child: TextFormField(
                            key: Key('due'),
                            decoration: const InputDecoration(
                              labelText: 'Due',
                              suffixIcon: Icon(Icons.calendar_today),
                              border: InputBorder.none,
                              focusedBorder: UnderlineInputBorder(),
                            ),
                            onTap: () {
                              setDueDate(context).then((value) {
                                if(value != null) {
                                  _dueDateController.text =
                                      DateFormat('y-MM-dd').format(value);
                                }
                              });
                            },
                            onSaved: (value) {
                              print(value);
                              if (value != "") {
                                widget.task.dueDate = DateTime.parse(value);
                              } else {
                                widget.task.dueDate = null;
                              }
                            },
                            controller: _dueDateController,
                            validator: validateDueDate,
                          )
                      ),
                    ],
                  ),
                  TextFormField(
                    key: Key('tags'),
                    controller: _tagController,
                    decoration: InputDecoration(
                      labelText: "Add Tag",
                      suffixIcon: IconButton(
                        icon: Icon(Icons.check),
                        onPressed: () {
                          if(_tagController.text.isNotEmpty) {
                            addTag(_tagController.text);
                            _tagController.text = "";
                          }
                        },
                      ),
                    ),
                    //onFieldSubmitted: (text) => addTag(text),
                    onChanged: (text) {
                      if(text.contains("\n")) {
                        if(!text.startsWith("\n")) {
                          addTag(text.trim());
                        }
                        _tagController.text = "";
                      }
                    },
                    maxLines: 2,
                    minLines: 1,
                  ),
                  Wrap(
                    spacing: 8.0,
                    children: getTagChips(),
                  ),
                ]
            ),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(),
      drawer: TeacherAppDrawer(),
      body: TabBarView(
          controller: _tabController,
          children: <Widget>[
            buildDetailsTab(),
            buildAssignedTab(),
          ],
        ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        tooltip: 'Add Student',
        onPressed: () {
          Map<String, dynamic> arguments = {
            'task': widget.task,
            'group': widget.group
          };
          Navigator.of(context).pushNamed('teacher_assignStudent', arguments: arguments);
        },
      ),
    );
  }
}