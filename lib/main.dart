import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import './task.dart';

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
  final _formKey = GlobalKey();
  Future<File> imgFile;  

  // final url = "http://localhost:3000/tasks";
  final url = "https://flutter-api-endpoint.herokuapp.com/tasks";

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  // void _choose() async {
  //   var uploadThread = await ImagePicker.pickImage(source: ImageSource.gallery);
  //   setState(() {
  //     file = uploadThread;
  //   });
  // }

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
  
  void _addTodoItem(Task newTask) async {
    var task = newTask.name;
    var img = (defaultB64THR);
    // String thumb = (newTask.thumbnail != null )? newTask.thumbnail : '';
    // print(thumb);
    if(task.length > 0) {
      String postString = url;
      Map<String, String> header = {"Content-type": "application/json" };
      String body = '{"name":"'+task+'", "thumbnail":"'+img+'"}';
      final resp = await http.post(postString, headers: header, body: body);
      if (resp.statusCode == 200) {
        print(resp.body);
        Navigator.pop(context);
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
              Uint8List bytes = base64Decode(item['thumbnail']);
              return new ListTile(
                leading: new Image.memory(bytes),
                // leading: ImageClickEvent(),
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
            body: new Container(
              padding: const EdgeInsets.all(8.0),
              child: new Column(
                children: <Widget>[
                  new TextField(
                    autofocus: true,
                    controller: new TextEditingController(text: _todoItems[index]["name"]),
                    onSubmitted: (val) {
                      setState(() {
                        _isLoading=true;
                      });
                      _editTodoItem(index, val);
                      Navigator.pop(context);
                    },
                    decoration: new InputDecoration(
                      hintText: 'Task Name',
                      contentPadding: const EdgeInsets.all(16.0)
                    ),
                  ),
                  SizedBox(height: 10.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      // SizedBox(width: 20.0),
                      RaisedButton(
                        onPressed: null,
                        child: Text('Update Thumbnail'),
                      ),
                      // new Container(
                      //   padding: EdgeInsets.all(20),
                      //   child: file == null
                      //   ? Text('No Image Selected') 
                      //   : Image.file(file, height: 80,),
                      // )
                    ],
                  ),
                  RaisedButton(
                    child: Text('Submit Changes'),
                    color: Colors.green,
                    onPressed: () {
                      setState(() {
                        _isLoading=true;
                      });
                      // TODO FIGURE OUT HOW TO SUBMIT ENTIRE FORM
                      // _editTodoItem(index, val);
                      Navigator.pop(context);
                    }
                  )
                ],
              )
            )
          );
        }
      )
    );
  }

  void _pushAddTodoScreen() {
    Task newTask = new Task();    
    Navigator.of(context).push(
      new MaterialPageRoute(
        builder: (context) {
          return new Scaffold(
            appBar: new AppBar(
              title: new Text('Add a new task')
            ),
            body: Form(
              key: _formKey,
              autovalidate: true,
              child: new Container(
                padding: const EdgeInsets.all(8.0),
                child: new Column(
                  children: <Widget>[
                    new TextFormField(
                      decoration: new InputDecoration(
                        hintText: 'Enter something to do...',
                        contentPadding: const EdgeInsets.all(16.0)
                      ),
                      validator: (val) => val.isEmpty ? 'Name is required' : null,
                      onSaved: (val) => {newTask.name = val},
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        
                        RaisedButton(
                          color: Colors.blue,
                          onPressed: null,
                          child: Text('Select Img'),)
                      ],
                    ), 

                    RaisedButton(
                      onPressed: (){
                        // _addTodoItem(newTask);
                        final FormState form = _formKey.currentState;
                        if (!form.validate()){
                          print('Form Not Valid');
                        } else {
                          form.save();
                          print(newTask.name);
                          _addTodoItem(newTask);
                        }
                      },
                      child: Text('Submit Task'),
                      color: Colors.green,
                    )
                  ],
                ),
              ),
            )
          );
        }
      )
    );
  }

  void _removeTodoItem(int index) async {
    var urlstring = url+'/'+_todoItems[index]['_id'];
    final resp = await http.delete(urlstring);
    if (resp.statusCode == 200) {
      print(resp.body);
      _fetchData();
    }
  }

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
