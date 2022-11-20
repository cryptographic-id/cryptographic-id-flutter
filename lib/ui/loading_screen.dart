import 'package:flutter/material.dart';

Widget loadingScreen(String title) {
  return Scaffold(
    appBar: AppBar(
      title: Text(title),
    ),
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const <Widget>[
          CircularProgressIndicator(),
        ],
      ),
    ),
  );
}
