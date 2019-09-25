import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

class TaskTile extends StatelessWidget{
  final item;
  TaskTile(this.item);

  @override 
  Widget build(BuildContext context) {
    return new FlatButton(
      padding: new EdgeInsets.all(0),
      child: new ListTile(
        title: new Text(item["name"]),
      ),
      onPressed: () => {
        print('clicked')
      },
    );
  }
}

class Task {
  final String name;
  final String date = new DateTime.now().toString(); 
  // final String status;
  // final String id;
  
  Task ({this.name});

  factory Task.fromJson(Map<String, String> json) {
    return Task(
      name: json['name'],
    );
  }
}

