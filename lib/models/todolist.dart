// models/todolist.dart
import 'package:isar/isar.dart';

// this line is needed to generate file
// then run dart run build_runner build
part 'todolist.g.dart';

@Collection()
class Todolist {
  Id id = Isar.autoIncrement;
  late String title;
  late DateTime deadline;
  late bool isDone = false;
}