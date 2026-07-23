import 'package:hive/hive.dart';

/// An "Everyday Task" — created once, repeated every day.
/// Its per-day completion state lives in [DailyCompletion], NOT here.
/// That's what makes the automatic midnight reset trivial: a new day
/// simply has no completion record yet, so the checkbox is unticked
/// by default without any reset job needing to run.
class RecurringTask extends HiveObject {
  String id;
  String title;
  int order;
  DateTime createdAt;
  int colorValue; // ARGB, used as an accent color for the task card

  RecurringTask({
    required this.id,
    required this.title,
    required this.order,
    required this.createdAt,
    this.colorValue = 0xFF6C63FF,
  });
}

class RecurringTaskAdapter extends TypeAdapter<RecurringTask> {
  @override
  final int typeId = 0;

  @override
  RecurringTask read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RecurringTask(
      id: fields[0] as String,
      title: fields[1] as String,
      order: fields[2] as int,
      createdAt: fields[3] as DateTime,
      colorValue: fields[4] as int? ?? 0xFF6C63FF,
    );
  }

  @override
  void write(BinaryWriter writer, RecurringTask obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.order)
      ..writeByte(3)
      ..write(obj.createdAt)
      ..writeByte(4)
      ..write(obj.colorValue);
  }
}
