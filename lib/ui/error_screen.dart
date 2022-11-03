import 'package:flutter/material.dart';

Widget showError(String title, String error) {
  return Scaffold(
    appBar: AppBar(
      title: Text(title),
    ),
    backgroundColor: Colors.redAccent.shade400,
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(error),
        ],
      ),
    ),
  );
}
