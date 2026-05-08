import 'package:flutter/widgets.dart';

/// Estado compartilhado entre [ArchbaseForm] e seus campos. Permite
/// que campos descubram seus valores iniciais e reportem mudanças sem
/// precisar de um state management externo.
class ArchbaseFormController extends ChangeNotifier {
  ArchbaseFormController({Map<String, dynamic>? initialValues})
      : _values = {...?initialValues};

  final Map<String, dynamic> _values;
  final Map<String, String?> _errors = {};

  Map<String, dynamic> get values => Map.unmodifiable(_values);
  Map<String, String?> get errors => Map.unmodifiable(_errors);
  bool get hasErrors => _errors.values.any((e) => e != null);

  T? read<T>(String name) => _values[name] as T?;

  void setValue(String name, dynamic value) {
    if (_values[name] == value) return;
    _values[name] = value;
    notifyListeners();
  }

  void setError(String name, String? error) {
    _errors[name] = error;
    notifyListeners();
  }

  void reset({Map<String, dynamic>? initialValues}) {
    _values
      ..clear()
      ..addAll(initialValues ?? {});
    _errors.clear();
    notifyListeners();
  }
}

/// Marker para descendentes localizarem o controller via context.
class ArchbaseFormScope extends InheritedNotifier<ArchbaseFormController> {
  const ArchbaseFormScope({
    super.key,
    required ArchbaseFormController controller,
    required super.child,
  }) : super(notifier: controller);

  static ArchbaseFormController? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<ArchbaseFormScope>()
        ?.notifier;
  }

  static ArchbaseFormController of(BuildContext context) {
    final ctrl = maybeOf(context);
    if (ctrl == null) {
      throw FlutterError(
        'Nenhum ArchbaseForm acima na árvore. Envolva os campos com '
        'ArchbaseForm(controller: ...).',
      );
    }
    return ctrl;
  }
}
