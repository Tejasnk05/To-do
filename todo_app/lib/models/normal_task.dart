import 'package:hive/hive.dart';

enum TaskStatus { pending, completed }

/// A one-time task, unrelated to the daily routine.
class NormalTask extends HiveObject {
  String id;
  String title;
  String description;
  int order;
  TaskStatus status;
  DateTime createdAt;
  DateTime? completedAt;

  NormalTask({
    required this.id,
    required this.title,
    this.description = '',
    required this.order,
    required this.createdAt,
    this.completedAt,
    this.status = TaskStatus.pending,
  });
}

class NormalTaskAdapter extends TypeAdapter<NormalTask> {
  @override
  final int typeId = 3;

  @override
  NormalTask read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return NormalTask(
      id: fields[0] as String,
      title: fields[1] as String,
      description: fields[2] as String? ?? '',
      order: fields[3] as int,
      createdAt: fields[4] as DateTime,
      completedAt: fields[5] as DateTime?,
      status: TaskStatus.values[fields[6] as int? ?? 0],
    );
  }

  @override
  void write(BinaryWriter writer, NormalTask obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.order)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.completedAt)
      ..writeByte(6)
      ..write(obj.status.index);
  }
}
