import 'package:crud_local_database_app/models/todolist.dart';
import 'package:flutter/cupertino.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class TodolistDatabase extends ChangeNotifier{
  static late Isar isar;

  // INIT
  static Future<void> initialize() async {
    if (Platform.isAndroid) { // Check if it's Android
      final dir = await getApplicationDocumentsDirectory();
      isar = await Isar.open([TodolistSchema], directory: dir.path);
    } else {
      // Handle other platforms or provide a default directory
      final dir = getTemporaryDirectory(); // Example for other platforms
      isar = await Isar.open([TodolistSchema], directory: (await dir).path);
    }
  }

  // list
  final List<Todolist> currentTodolists = [];

  // create
  Future<void> addTodolist(String textFromUser, DateTime dateFromUser) async {
    // create a new object
    final newTodolist = Todolist()..title = textFromUser..deadline = dateFromUser..isDone = false;

    // save to db
    await isar.writeTxn(() => isar.todolists.put(newTodolist));

    // re-read from db
    fetchTodolists();
  }
  // read
  Future<void> fetchTodolists() async {
    List<Todolist> fetchedTodolists = await isar.todolists.where().findAll();
    currentTodolists.clear();
    currentTodolists.addAll(fetchedTodolists);
    notifyListeners();
  }
  // update
  Future<void> updateTodolist(int id, String newText, DateTime newDeadline, bool isDone) async {
    final existingTodolist = await isar.todolists.get(id);
    if (existingTodolist != null) {
      existingTodolist.title = newText;
      existingTodolist.deadline = newDeadline;
      existingTodolist.isDone = isDone;
      await isar.writeTxn(() => isar.todolists.put(existingTodolist));
      await fetchTodolists();
    }
  }
  // delete
  Future<void> deleteTodolist(int id) async {
    await isar.writeTxn(() => isar.todolists.delete(id));
    await fetchTodolists();
  }
}