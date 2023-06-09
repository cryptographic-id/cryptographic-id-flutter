import 'package:flutter/material.dart';

Widget loadingScreen(String title) {
  return Scaffold(
    appBar: AppBar(
      title: Text(title),
    ),
    body: const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          CircularProgressIndicator(),
        ],
      ),
    ),
  );
}
