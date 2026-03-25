import 'package:flutter/material.dart';
import '../services/user_service.dart';
import '../models/user_profile.dart';

class ProfilePopup extends StatefulWidget {
  @override
  _ProfilePopupState createState() => _ProfilePopupState();
}

class _ProfilePopupState extends State<ProfilePopup> {

  UserProfile? user;

  void loadUser() async {
    user = await UserService.getUserProfile();
    showPopup();
  }

  void showPopup() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              CircleAvatar(
                radius: 25,
                child: Text(user!.username[0]),
              ),

              SizedBox(height: 10),

              Text(user!.username),

              Text(user!.email),

              Text("Role: ${user!.role}"),

              Divider(),

              ListTile(
                leading: Icon(Icons.logout),
                title: Text("Logout"),
                onTap: () {},
              )
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loadUser,
      child: CircleAvatar(
        child: Text("A"),
      ),
    );
  }
}