import 'package:epmsa_mobile/core/services/auto_save_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final autoSaveServiceProvider = Provider<AutoSaveService>((ref) {
  return AutoSaveService();
});
