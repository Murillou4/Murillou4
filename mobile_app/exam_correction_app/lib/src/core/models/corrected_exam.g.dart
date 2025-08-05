// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'corrected_exam.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CorrectedExamAdapter extends TypeAdapter<CorrectedExam> {
  @override
  final int typeId = 0;

  @override
  CorrectedExam read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CorrectedExam(
      examId: fields[0] as String,
      assessmentId: fields[1] as String,
      scanTimestamp: fields[3] as DateTime,
      studentAnswers: (fields[4] as List).cast<String>(),
      correctAnswers: (fields[5] as List).cast<String>(),
      scores: (fields[6] as List).cast<int>(),
      finalGrade: fields[7] as double,
      assessmentName: fields[10] as String,
      pointValues: (fields[11] as Map).cast<String, int>(),
      studentIdentifier: fields[2] as String?,
      imagePath: fields[8] as String?,
      isSynced: fields[9] as bool? ?? false,
    );
  }

  @override
  void write(BinaryWriter writer, CorrectedExam obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.examId)
      ..writeByte(1)
      ..write(obj.assessmentId)
      ..writeByte(2)
      ..write(obj.studentIdentifier)
      ..writeByte(3)
      ..write(obj.scanTimestamp)
      ..writeByte(4)
      ..write(obj.studentAnswers)
      ..writeByte(5)
      ..write(obj.correctAnswers)
      ..writeByte(6)
      ..write(obj.scores)
      ..writeByte(7)
      ..write(obj.finalGrade)
      ..writeByte(8)
      ..write(obj.imagePath)
      ..writeByte(9)
      ..write(obj.isSynced)
      ..writeByte(10)
      ..write(obj.assessmentName)
      ..writeByte(11)
      ..write(obj.pointValues);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CorrectedExamAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}