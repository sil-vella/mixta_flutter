import 'dart:async';
import '../../../../core/00_base/module_base.dart';
import '../../../../core/managers/services_manager.dart';
import '../../../../tools/logging/logger.dart';

class FunctionHelperModule extends ModuleBase {
  static FunctionHelperModule? _instance;
  final ServicesManager _servicesManager = ServicesManager();

  FunctionHelperModule._internal() {
    Logger().info('FunctionHelperModule initialized.');
  }

  /// ✅ Factory method to ensure singleton
  factory FunctionHelperModule() {
    _instance ??= FunctionHelperModule._internal();
    return _instance!;
  }

}
