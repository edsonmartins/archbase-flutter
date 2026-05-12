import 'package:archbase_flutter/archbase_flutter.dart';
import 'package:get/get.dart';

/// `GetxController` que herda o `guard()` do [ArchbaseController].
///
/// Em vez de manter `state` imutável (como [ArchbaseController]), usa
/// `RxBool` / `RxnString` para `isLoading` e `error` — alinhando-se ao
/// padrão reativo do GetX.
///
/// ```dart
/// class VisitasController extends ArchbaseGetController {
///   final visitas = <Visita>[].obs;
///   final _repo = Get.find<VisitasRepository>();
///
///   Future<void> load() => guard(() async {
///     visitas.assignAll(await _repo.list());
///   });
/// }
/// ```
abstract class ArchbaseGetController extends GetxController {
  final RxBool isLoading = false.obs;
  final RxnString error = RxnString();

  bool get hasError => error.value != null;

  /// Executa [action] gerenciando loading + erro automaticamente.
  Future<T?> guard<T>(
    Future<T> Function() action, {
    void Function(Object error, StackTrace stackTrace)? onError,
  }) async {
    isLoading.value = true;
    error.value = null;
    try {
      final result = await action();
      return result;
    } catch (err, stackTrace) {
      error.value = _humanize(err);
      onError?.call(err, stackTrace);
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  String _humanize(Object err) {
    if (err is ApiException) {
      if (err.hasFieldErrors) {
        return err.fieldErrors.map((e) => e.message).join('\n');
      }
      return err.message;
    }
    if (err is ArchbaseException) return err.message;
    return err.toString();
  }

  void clearError() {
    if (error.value != null) error.value = null;
  }

  @override
  void onClose() {
    isLoading.close();
    error.close();
    super.onClose();
  }
}
