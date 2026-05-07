import 'package:flutter/material.dart';

/// Categorias de tamanho de tela.
enum ArchbaseDeviceType { phone, tablet, desktop }

/// Helpers responsivos sem amarrar a um pacote específico
/// (complementa `flutter_screenutil`).
class ArchbaseResponsive {
  ArchbaseResponsive._();

  static const double phoneMaxWidth = 600;
  static const double tabletMaxWidth = 1200;

  static ArchbaseDeviceType deviceTypeOf(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w < phoneMaxWidth) return ArchbaseDeviceType.phone;
    if (w < tabletMaxWidth) return ArchbaseDeviceType.tablet;
    return ArchbaseDeviceType.desktop;
  }

  static bool isPhone(BuildContext c) =>
      deviceTypeOf(c) == ArchbaseDeviceType.phone;
  static bool isTablet(BuildContext c) =>
      deviceTypeOf(c) == ArchbaseDeviceType.tablet;
  static bool isDesktop(BuildContext c) =>
      deviceTypeOf(c) == ArchbaseDeviceType.desktop;

  /// Escolha um valor por device type. Use:
  /// `ArchbaseResponsive.value(context, phone: 12, tablet: 16, desktop: 24)`
  static T value<T>(
    BuildContext context, {
    required T phone,
    T? tablet,
    T? desktop,
  }) {
    switch (deviceTypeOf(context)) {
      case ArchbaseDeviceType.phone:
        return phone;
      case ArchbaseDeviceType.tablet:
        return tablet ?? phone;
      case ArchbaseDeviceType.desktop:
        return desktop ?? tablet ?? phone;
    }
  }

  /// Quantidade de colunas para grids.
  static int gridColumns(BuildContext context) =>
      value(context, phone: 1, tablet: 2, desktop: 4);
}
