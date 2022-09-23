import 'package:flutter/material.dart';

Widget loadingScreen(String text) {
  return Scaffold(
    appBar: AppBar(
      title: Text(text + "..."),
    ),
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          CircularProgressIndicator(),
        ],
      ),
    ),
  );
}
