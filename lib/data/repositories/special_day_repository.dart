import 'package:hive/hive.dart';
import '../models/special_day_model.dart';

class SpecialDayRepository {
  static const String _boxName = 'special_days';

  Box<SpecialDayModel> get _box => Hive.box<SpecialDayModel>(_boxName);

  List<SpecialDayModel> getAll() {
    return _box.values.toList()
      ..sort((a, b) => a.daysUntilNext.compareTo(b.daysUntilNext));
  }

  Future<void> add(SpecialDayModel model) async {
    await _box.put(model.id, model);
  }

  Future<void> update(SpecialDayModel model) async {
    await _box.put(model.id, model);
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  SpecialDayModel? getById(String id) {
    return _box.get(id);
  }

  Future<void> clearAll() async {
    await _box.clear();
  }
}
