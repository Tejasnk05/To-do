import 'package:hive/hive.dart';

/// One record per (recurring task, calendar date).
/// Key format used in the Hive box: "<taskId>_<yyyy-MM-dd>"
/// This is the single source of truth for:
///  - today's checkbox state on the Everyday Tasks tab
///  - the Weekly Dashboard's Mon-Sat grid
///  - the Monthly Dashboard's consistency stats
class DailyCompletion extends HiveObject {
  String taskId;
  String date; // yyyy-MM-dd
  bool completed;

  DailyCompletion({
    required this.taskId,
    required this.date,
    required this.completed,
  });

  static String keyFor(String taskId, String date) => '${taskId}_$date';
}

class DailyCompletionAdapter extends TypeAdapter<DailyCompletion> {
  @override
  final int typeId = 1;

  @override
  DailyCompletion read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DailyCompletion(
      taskId: fields[0] as String,
      date: fields[1] as String,
      completed: fields[2] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, DailyCompletion obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.taskId)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.completed);
  }
}
