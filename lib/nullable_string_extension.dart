extension NullableStringExtension on String? {
  bool get isNullOrEmpty => this?.isEmpty ?? true;

  bool get isNotNullAndNotEmpty => !isNullOrEmpty;

  bool get isNullOrBlank => this?.trim().isEmpty ?? true;

  bool get isNotNullAndNotBlank => !isNullOrBlank;
}
