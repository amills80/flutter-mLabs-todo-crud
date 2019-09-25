import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
// import 'p'

void main() => runApp(new TodoApp());

class TodoApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Todo List',
      home: new TodoList()
    );
  }
}

class TodoList extends StatefulWidget {
  @override
  createState() => new TodoListState();
}

class TodoListState extends State<TodoList> {
  List _todoItems = [];
  bool _isLoading = true;
  // final url = "http://localhost:3000/tasks";
  final url = "https://flutter-api-endpoint.herokuapp.com/tasks";

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future _fetchData() async {
    setState(() {
      _todoItems = [];
    });
    final response = await http.get(url);
    if (response.statusCode == 200) {
      List tempList = json.decode(response.body) as List;
      setState(() {
        for (var i=0; i<tempList.length; i++){
          var item = tempList[i];
          // Temp error mgmt try-catch
          if(item['name'] == null ) {
            item['name'] = 'error';
          }
          _todoItems.add(tempList[i]);
        }        
      });
      _isLoading = false;
    } else {
      throw Exception('Failed to load');
    }
  }
  
  // Instead of autogenerating a todo item, _addTodoItem now accepts a string
  void _addTodoItem(String task) async {
    // Only add the task if the user actually entered something
    if(task.length > 0) {
      String postString = url;
      Map<String, String> header = {"Content-type": "application/json" };
      String body = '{"name":"'+task+'"}';
      final resp = await http.post(postString, headers: header, body: body);
      if (resp.statusCode == 200) {
        print(resp.body);
        _fetchData();
      }

    }
  }

  void _editTodoItem(int index, String val) async {
    if (val.length>0){
      String postString = url+"/"+_todoItems[index]['_id'];
      Map<String, String> header = {"Content-type": "application/json" };
      String body = '{"name":"'+val+'"}';

      final resp = await http.put(postString, headers: header, body: body);
      if (resp.statusCode == 200) {
        // print(resp.body);
        _fetchData();
      }
    }
  }

  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text('Todo List')
      ),
      body: new Center(
        child: _isLoading
          ? new CircularProgressIndicator() 
          : new ListView.builder(
            itemCount: this._todoItems != null ? this._todoItems.length : 0,
            itemBuilder: (context, i) {
              final item = this._todoItems[i];
              // print("item: $item");

              return new ListTile(
                // leading: thumbnail(),
                title: new Text(item['name']),
                trailing: IconButton(
                  onPressed: () => _promptRemoveTodoItem(i),
                  icon: Icon(Icons.more_vert)
                ),
              );
            
            }),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _pushAddTodoScreen() ,
        tooltip: 'Increment',
        child: Icon(Icons.add),
      )
    );
  }

  void _pushEditTodoScreen(int index) {
    Navigator.of(context).push(
      new MaterialPageRoute(
        builder: (context) {
          return new Scaffold(
            appBar: new AppBar(
              title: new Text('Edit Task'),
            ),
            body: new TextField(
              autofocus: true,
              controller: new TextEditingController(text: _todoItems[index]["name"]),
              onSubmitted: (val) {
                setState(() {
                  _isLoading=true;
                });
                _editTodoItem(index, val);
                Navigator.pop(context);
              },
            ),
          );
        }
      )
    );
  }

  void _pushAddTodoScreen() {
    // Push this page onto the stack
    Navigator.of(context).push(
      new MaterialPageRoute(
        builder: (context) {
          return new Scaffold(
            appBar: new AppBar(
              title: new Text('Add a new task')
            ),
            body: new TextField(
              autofocus: true,
              onSubmitted: (val) {
                setState(() {
                  _isLoading=true;
                });
                _addTodoItem(val);
                Navigator.pop(context); // Close the add todo screen
              },
              decoration: new InputDecoration(
                hintText: 'Enter something to do...',
                contentPadding: const EdgeInsets.all(16.0)
              ),
            )
          );
        }
      )
    );
  }

  // Much like _addTodoItem, this modifies the array of todo strings and
  // notifies the app that the state has changed by using setState
  void _removeTodoItem(int index) async {
    var urlstring = url+'/'+_todoItems[index]['_id'];
    final resp = await http.delete(urlstring);
    if (resp.statusCode == 200) {
      print(resp.body);
      _fetchData();
    }
  }

  // Show an alert dialog asking the user to confirm that the task is done
  void _promptRemoveTodoItem(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return new AlertDialog(
          title: new Text('Mark "${_todoItems[index]['name']}" as done?'),
          actions: <Widget>[
            new FlatButton(
              child: new Text('CANCEL'),
              onPressed: () => Navigator.of(context).pop()
            ),
            new RaisedButton(
              color: Colors.blue,
              child: new Text('EDIT', 
                style: TextStyle(color: Colors.white)
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _pushEditTodoScreen(index);
              }
            ),
            new RaisedButton(
              color: Colors.red,
              child: new Text('REMOVE', 
                style: TextStyle(color: Colors.white)
              ),
              onPressed: () {
                _removeTodoItem(index);
                Navigator.of(context).pop();
              }
            )
          ]
        );
      }
    );
  }
}
