import 'package:mindisle_client/features/medication/domain/entities/medication_entities.dart';

final class MedicationEditorArgs {
  const MedicationEditorArgs({this.initial});

  final MedicationRecord? initial;

  bool get isEditing => initial != null;
}
