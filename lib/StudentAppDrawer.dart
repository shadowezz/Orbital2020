import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:orbital2020/AuthProvider.dart';
import 'package:orbital2020/GameWidget.dart';
import 'package:orbital2020/Root.dart';
import 'package:provider/provider.dart';

import 'Auth.dart';
import 'DataContainers/User.dart';

class StudentAppDrawer extends StatelessWidget {
  StudentAppDrawer({ Key key }) : super(key: key);

  Future<void> signOut(BuildContext context, User _user) async {
    print("Tapped Logout");
    try {
      Auth auth = AuthProvider.of(context).auth;
      await auth.signOut();
      print("Signed out: ${_user.id}");
      GameWidget.unityWidgetKey.currentState.resetGame();
      Navigator.of(context, rootNavigator: true).pushReplacement(
        MaterialPageRoute(builder: (context) => RootPage())
      );
    } catch (error) {
      print("$error");
    }
  }

  @override
  Widget build(BuildContext context) {
    User _user = Provider.of<User>(context, listen: false);
    return Drawer(
        child: ListView(
          children: <Widget>[
            UserAccountsDrawerHeader(
              accountEmail: Text(_user.email),
              accountName: Text(_user.name),
              currentAccountPicture: _user.photoUrl != null ?
                CircleAvatar(
                  backgroundImage: NetworkImage(_user.photoUrl),
                  radius: 40,
                ) :
                CircleAvatar(
                  child: const Text("U"),
                  radius: 40,
                ),
            ),
            ListTile(
              title: const Text('Home'),
              onTap: () {
                print('Tapped Home');
                User user = Provider.of<User>(context, listen: false);
                Navigator.pop(context);
                if(user.accountType == 'student') {
                  //Navigator.pushNamed(context, 'student_main');
                  Navigator.popUntil(context, ModalRoute.withName('student_main'));
                } else {
                  Navigator.pushNamed(context, 'teacher_gruops');
                }
              },
            ),
            ListTile(
              title: const Text("Schedule"),
              onTap: () {
                print("Tapped Schedule");
                Navigator.pop(context);
                Navigator.of(context).pushNamed("schedule");
              }
            ),
            ListTile(
                title: const Text("Focus Mode"),
                onTap: () {
                  print("Tapped Focus");
                  Navigator.pop(context);
                  Navigator.of(context).pushNamed("focus").then((value) {
                    GameWidget.unityWidgetKey.currentState.handleFocusTime();
                  });
                }
            ),
            ListTile(
                title: const Text("Leaderboard"),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).pushNamed("leaderboard");
                }
            ),
            ListTile(
              title: Text('Logout'),
              onTap: () => signOut(context, _user)
            )
          ],
        )
    );
  }

}