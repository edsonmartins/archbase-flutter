import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../theme/archbase_theme_extensions.dart';

/// Numeric stepper (touch spin) com botões -/+ e campo central editável.
class ArchbaseNumericStepper extends StatefulWidget {
  const ArchbaseNumericStepper({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 999,
    this.step = 1,
    this.suffix,
    this.disabled = false,
    this.editable = true,
  });

  final num value;
  final ValueChanged<num> onChanged;
  final num min;
  final num max;
  final num step;
  final String? suffix;
  final bool disabled;
  final bool editable;

  @override
  State<ArchbaseNumericStepper> createState() => _ArchbaseNumericStepperState();
}

class _ArchbaseNumericStepperState extends State<ArchbaseNumericStepper> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _formatted(widget.value));
  }

  @override
  void didUpdateWidget(ArchbaseNumericStepper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _controller.text = _formatted(widget.value);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatted(num value) {
    if (value is int || value == value.toInt()) return value.toInt().toString();
    return value.toString();
  }

  void _set(num next) {
    final clamped = next.clamp(widget.min, widget.max);
    if (clamped != widget.value) {
      widget.onChanged(clamped);
    }
  }

  void _decrement() => _set(widget.value - widget.step);
  void _increment() => _set(widget.value + widget.step);

  @override
  Widget build(BuildContext context) {
    final colors = context.archbase;
    final canDec = !widget.disabled && widget.value > widget.min;
    final canInc = !widget.disabled && widget.value < widget.max;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepperButton(
            icon: LucideIcons.minus,
            onPressed: canDec ? _decrement : null,
          ),
          Container(width: 1, height: 36, color: colors.border),
          SizedBox(
            width: 64,
            child: widget.editable
                ? TextField(
                    controller: _controller,
                    enabled: !widget.disabled,
                    textAlign: TextAlign.center,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: false,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 8),
                    ),
                    onSubmitted: (raw) {
                      final n = num.tryParse(raw.replaceAll(',', '.'));
                      if (n != null) _set(n);
                    },
                  )
                : Text(
                    widget.suffix == null
                        ? _formatted(widget.value)
                        : '${_formatted(widget.value)} ${widget.suffix}',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
          ),
          Container(width: 1, height: 36, color: colors.border),
          _StepperButton(
            icon: LucideIcons.plus,
            onPressed: canInc ? _increment : null,
          ),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Icon(
          icon,
          size: 18,
          color: onPressed == null
              ? Theme.of(context).disabledColor
              : Theme.of(context).iconTheme.color,
        ),
      ),
    );
  }
}
