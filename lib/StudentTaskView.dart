import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:form_field_validator/form_field_validator.dart';
import 'package:intl/intl.dart';
import 'package:orbital2020/DataContainers/TaskWithStatus.dart';
import 'package:orbital2020/DataContainers/User.dart';
import 'package:orbital2020/DatabaseController.dart';
import 'package:provider/provider.dart';

class StudentTaskView extends StatefulWidget {
  final TaskWithStatus task;

  StudentTaskView({Key key, @required this.task}) : super(key: key);

  @override
  _StudentTaskViewState createState() => _StudentTaskViewState();
}

class _StudentTaskViewState extends State<StudentTaskView> {
  final DatabaseController db = DatabaseController();
  final _mainFormKey = GlobalKey<FormState>();
  final _createdByController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _dueDateController = TextEditingController();
  final _tagController = TextEditingController();



  User _user;
  bool editable;

  @override
  void initState() {
    super.initState();
    _user = Provider.of<User>(context, listen: false);
    editable = _user.id == widget.task.createdById;
    _createdByController.text = editable ? "Me" : widget.task.createdByName;
    _descriptionController.text = widget.task.description;
    _dueDateController.text = widget.task.dueDate != null ?
        DateFormat('y-MM-dd').format(widget.task.dueDate) :
        "";
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
    for (String tag in widget.task.tags) {
      tagChips.add(Chip(
        label: Text(tag),
        onDeleted: editable ? () {
            deleteTag(tag);
          } : null,
      ));
    }
    return tagChips;
  }

  void deleteTag(String tag) {
    setState(() {
      widget.task.tags.remove(tag);
      print(widget.task.tags);
    });
  }

  void addTag(String tag) {
    setState(() {
      widget.task.tags.add(tag);
    });
  }

  Widget buildCompletedButton() {
    if(!widget.task.completed) {
      //Not conpleted
      return RaisedButton(
        child: const Text('Complete'),
        onPressed: () {
          if(widget.task.createdById == _user.id) {
            _onDelete();
          } else {
            db.updateTaskCompletion(widget.task.id, _user.id, true, false)
                .then((value) =>
                setState(() {
                  widget.task.completed = true;
                })
            );
          }
        },
      );
    } else if (!widget.task.verified) {
      return RaisedButton(
          child: const Text('Verifying...'),
          onPressed: () {
            db.updateTaskCompletion(widget.task.id, _user.id, false, false)
              .then((value) =>
              setState(() {
                widget.task.completed = false;
              })
            );
          },
        );
    } else {
      return Text("");
    }
  }

  String validateDueDate(String value) {
    if (value == "") {
      return null;
    }
    String checkFormat = DateValidator("y-MM-dd", errorText: "Invalid date format! Should be y-MM-dd.").call(value);
    if (checkFormat != null) {
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
            title: Text('Do you want to delete the task?'),
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
                  _deleteTask().then((value) {
                    Navigator.of(context).pop();
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

  Future<void> _deleteTask() {
    return db.studentDeleteTask(task: widget.task, studentId: _user.id);
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
        title: Text(widget.task.name),
        actions: <Widget>[
          editable ? PopupMenuButton(
            itemBuilder: _actionMenuBuilder,
            onSelected: _onActionMenuSelected,
          ) : Container(width: 0, height: 0,)
        ],
      ),
      body: SafeArea(
        child: Form(
            key: _mainFormKey,
            onWillPop: () async {
              return editable ? submit().then((value) => value) : true;
            },
            child: ListView(
                padding: EdgeInsets.symmetric(horizontal: 5),
                children: <Widget>[
                  TextFormField(
                    key: Key('created-by'),
                    decoration: const InputDecoration(
                      labelText: 'Created By',
                      border: InputBorder.none,
                      focusedBorder: UnderlineInputBorder(),
                    ),
                    controller: _createdByController,
                    enabled: false,
                  ),
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
                      enabled: editable,
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
                            enabled: editable,
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
                    enabled: editable,
                  ),
                  Wrap(
                    spacing: 8.0,
                    children: getTagChips(),
                  ),
                  buildCompletedButton(),
                ]
            ),
          ),
        )
      );
  }
}