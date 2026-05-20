abstract class CriteriaItem {
  String get name;
  double get maxValue;
  double? get controlValue;
  double get percentage;
  String? get qualification;
  String? get note;

  CriteriaItem copyWithField(String field, dynamic value);
}
