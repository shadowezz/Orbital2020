import 'package:background_fetch/background_fetch.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:orbital2020/AuthProvider.dart';
import 'package:orbital2020/Root.dart';
import 'package:provider/provider.dart';

import 'Auth.dart';
import 'DataContainers/User.dart';

class AppDrawer extends StatelessWidget {
  AppDrawer({ Key key }) : super(key: key);

  Future<void> signOut(BuildContext context, User _user) async {
    print("Tapped Logout");
    try {
      Auth auth = AuthProvider.of(context).auth;
      await auth.signOut();
      print("Signed out: ${_user.id}");
      BackgroundFetch.stop();
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
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: ListTile(
                leading: const Icon(Icons.account_circle),
                title: Text('${_user.name}'),
              ),
            ),
            ListTile(
              title: const Text('Home'),
              onTap: () {
                print('Tapped Home');
                User user = Provider.of<User>(context, listen: false);
                Navigator.pop(context);
                if(user.accountType == 'student') {
                  Navigator.pushNamed(context, 'student_main');
                } else {
                  Navigator.pushNamed(context, 'teacher_gruops');
                }
              },
            ),
            ListTile(
              title: const Text('Add task'),
              onTap: () {
                print('Tapped Add Task');
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Groups'),
              onTap: () {
                print('Tapped Groups');
                Navigator.pop(context);
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
                  Navigator.of(context).pushNamed("focus");
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
              title: const Text('Settings'),
              onTap: () {
                print('Tapped Settings');
                Navigator.pop(context);
              },
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