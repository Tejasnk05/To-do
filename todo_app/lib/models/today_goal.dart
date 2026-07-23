import 'package:hive/hive.dart';

/// A temporary goal that only shows up on its [forDate].
/// Old goals stay in the box forever (history), but the UI filters
/// to forDate == today, so they "disappear" the next day for free.
class TodayGoal extends HiveObject {
  String id;
  String title;
  DateTime createdAt;
  bool completed;
  String forDate; // yyyy-MM-dd

  TodayGoal({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.forDate,
    this.completed = false,
  });
}

class TodayGoalAdapter extends TypeAdapter<TodayGoal> {
  @override
  final int typeId = 2;

  @override
  TodayGoal read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TodayGoal(
      id: fields[0] as String,
      title: fields[1] as String,
      createdAt: fields[2] as DateTime,
      forDate: fields[3] as String,
      completed: fields[4] as bool? ?? false,
    );
  }

  @override
  void write(BinaryWriter writer, TodayGoal obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.createdAt)
      ..writeByte(3)
      ..write(obj.forDate)
      ..writeByte(4)
      ..write(obj.completed);
  }
}
