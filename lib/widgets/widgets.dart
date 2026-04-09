import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';
import '../services/user_service.dart';
import '../services/api_service.dart';

// ─── TEXT STYLES ─────────────────────────────────────────────
TextStyle monoStyle({
  double size = 12,
  FontWeight weight = FontWeight.w500,
  Color color = AppColors.ink2,
}) =>
    GoogleFonts.robotoMono(fontSize: size, fontWeight: weight, color: color);

TextStyle bodyStyle({
  double size = 13,
  FontWeight weight = FontWeight.w400,
  Color color = AppColors.ink,
  double? height = 1.5,
}) =>
    GoogleFonts.roboto(
        fontSize: size, fontWeight: weight, color: color, height: height);

// ─── BADGE ────────────────────────────────────────────────────
class AmsBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color background;
  final double fontSize;

  const AmsBadge({
    super.key,
    required this.label,
    this.color = AppColors.tBlue,
    this.background = AppColors.tBlueLt,
    this.fontSize = 10,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style:
              monoStyle(size: fontSize, weight: FontWeight.w700, color: color)),
    );
  }
}

// ─── PILL (inline label) ──────────────────────────────────────
class AmsPill extends StatelessWidget {
  final String label;
  final Color color;
  final Color background;

  const AmsPill({
    super.key,
    required this.label,
    required this.color,
    required this.background,
  });

  factory AmsPill.auto() => const AmsPill(
      label: 'AUTO', color: AppColors.amber, background: AppColors.amberLt);

  factory AmsPill.locked() => const AmsPill(
      label: 'LOCKED', color: AppColors.ink3, background: AppColors.grayLt);

  factory AmsPill.optional() => const AmsPill(
      label: 'OPTIONAL', color: AppColors.green, background: AppColors.greenLt);

  factory AmsPill.required_() => const AmsPill(
      label: 'REQUIRED', color: AppColors.red, background: AppColors.redLt);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label,
          style: monoStyle(size: 8, weight: FontWeight.w700, color: color)),
    );
  }
}

// ─── BUTTON ───────────────────────────────────────────────────
enum AmsButtonVariant { primary, teal, green, outline, ghost, danger }

class AmsButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final AmsButtonVariant variant;
  final bool large;
  final bool small;
  final IconData? icon;
  final Color? backgroundColor;

  const AmsButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AmsButtonVariant.primary,
    this.large = false,
    this.small = false,
    this.icon,
    this.backgroundColor,
  });

  @override
  State<AmsButton> createState() => _AmsButtonState();
}

class _AmsButtonState extends State<AmsButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    late Color bg;
    late final Color fg;
    Border? border;
    List<BoxShadow>? shadow;
    Gradient? gradient;

    switch (widget.variant) {
      case AmsButtonVariant.primary:
        bg = AppColors.tBlue;
        fg = Colors.white;
        border = Border.all(color: AppColors.tBlueDk.withValues(alpha: 0.2));
      case AmsButtonVariant.teal:
        bg = AppColors.nTeal;
        fg = Colors.white;
        border = Border.all(color: AppColors.nTealDk.withValues(alpha: 0.2));
      case AmsButtonVariant.green:
        bg = const Color(0xFF22C55E); // Zoho Green
        fg = Colors.white;
      case AmsButtonVariant.outline:
        bg = Colors.white;
        fg = AppColors.ink;
        border = Border.all(color: AppColors.border, width: 1.0);
      case AmsButtonVariant.ghost:
        bg = _isHovered ? AppColors.bg : Colors.transparent;
        fg = AppColors.ink2;
      case AmsButtonVariant.danger:
        bg = AppColors.red;
        fg = Colors.white;
        border = Border.all(color: AppColors.red.withValues(alpha: 0.2));
    }

    if (widget.backgroundColor != null) bg = widget.backgroundColor!;

    final double vPad = widget.small
        ? 6
        : widget.large
            ? 10
            : 8;
    final double hPad = widget.small
        ? 12
        : widget.large
            ? 24
            : 16;
    final double fSize = widget.small
        ? 11
        : widget.large
            ? 14
            : 13;
    final double radius = 4; // Sharp but soft corners like Zoho

    return MouseRegion(
      cursor: widget.onPressed != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedScale(
          scale: _isHovered ? 1.02 : 1.0,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
          child: AnimatedOpacity(
            opacity: widget.onPressed == null ? 0.5 : 1.0,
            duration: const Duration(milliseconds: 150),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
              decoration: BoxDecoration(
                color: bg,
                gradient: gradient,
                borderRadius: BorderRadius.circular(radius),
                border: border,
                boxShadow: shadow,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.icon != null) ...[
                    Icon(widget.icon, size: fSize + 2, color: fg),
                    const SizedBox(width: 7),
                  ],
                  Text(widget.label,
                      style: bodyStyle(
                          size: fSize, weight: FontWeight.w700, color: fg)),
                  if ((widget.variant == AmsButtonVariant.primary ||
                          widget.variant == AmsButtonVariant.teal ||
                          widget.variant == AmsButtonVariant.green) &&
                      !widget.small) ...[
                    const SizedBox(width: 8),
                    Icon(Icons.arrow_forward_rounded,
                        size: fSize + 2, color: fg),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── CARD ─────────────────────────────────────────────────────
class AmsCard extends StatelessWidget {
  final Widget? headLeft;
  final Widget? headRight;
  final Widget child;
  final EdgeInsets padding;
  final BoxDecoration? decoration;
  final VoidCallback? onTap;

  const AmsCard({
    super.key,
    this.headLeft,
    this.headRight,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.decoration,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget card = Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: decoration ??
          BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (headLeft != null || headRight != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
              decoration: const BoxDecoration(
                color: AppColors.cardHead,
                border: Border(bottom: BorderSide(color: AppColors.border)),
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  if (headLeft != null) Expanded(child: headLeft!),
                  if (headRight != null) headRight!,
                ],
              ),
            ),
          Padding(padding: padding, child: child),
        ],
      ),
    );

    if (onTap != null) {
      return MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: card,
        ),
      );
    }

    return card;
  }
}

// ─── INFO BANNER ──────────────────────────────────────────────
class AmsInfoBanner extends StatelessWidget {
  final String text;

  const AmsInfoBanner({
    super.key,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F7FF),
        border: Border.all(color: const Color(0xFFCCE4FF)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded,
              size: 18, color: Color(0xFF1E6AD3)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: bodyStyle(size: 13, color: const Color(0xFF475569)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── SECTION TITLE ────────────────────────────────────────────
Widget sectionTitle(String title,
    {Color color = AppColors.ink2, double size = 12}) {
  return Text(title,
      style: monoStyle(size: size, weight: FontWeight.w700, color: color));
}

// ─── FORM FIELD WRAPPER ───────────────────────────────────────
class AmsField extends StatelessWidget {
  final String label;
  final bool required;
  final Widget? pill;
  final String? hint;
  final Color? hintColor;
  final Color? hintBg;
  final String? tooltip;
  final bool labelAbove;
  final Widget child;

  const AmsField({
    super.key,
    required this.label,
    this.required = false,
    this.pill,
    this.hint,
    this.hintColor,
    this.hintBg,
    this.tooltip,
    this.labelAbove = false,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final labelWidget = SizedBox(
      width: labelAbove ? double.infinity : 180,
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: label,
              style: bodyStyle(
                size: 13,
                weight: FontWeight.w500,
                color: AppColors.ink2,
              ),
            ),
            if (required) ...[
              const WidgetSpan(child: SizedBox(width: 4)),
              TextSpan(
                text: '*',
                style: bodyStyle(
                  size: 14,
                  weight: FontWeight.w700,
                  color: AppColors.red,
                ),
              ),
            ],
            const WidgetSpan(child: SizedBox(width: 4)),
            WidgetSpan(
              alignment: ui.PlaceholderAlignment.middle,
              child: Tooltip(
                message: tooltip ?? 'Click for more info',
                preferBelow: false,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.ink,
                  borderRadius: BorderRadius.circular(4),
                ),
                textStyle: bodyStyle(size: 11, color: Colors.white),
                child: const Icon(Icons.info_outline_rounded,
                    size: 14, color: AppColors.ink4),
              ),
            ),
          ],
        ),
      ),
    );

    final contentWidget = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        child,
        if (hint != null) ...[
          const SizedBox(height: 6),
          Container(
            padding: hintBg != null
                ? const EdgeInsets.symmetric(horizontal: 8, vertical: 3)
                : EdgeInsets.zero,
            decoration: hintBg != null
                ? BoxDecoration(
                    color: hintBg,
                    borderRadius: BorderRadius.circular(5),
                  )
                : null,
            child: Text(
              hint!,
              style: bodyStyle(size: 11, color: hintColor ?? AppColors.ink3),
            ),
          ),
        ],
      ],
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: labelAbove
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                labelWidget,
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: contentWidget),
                    if (pill != null) ...[
                      const SizedBox(width: 12),
                      pill!,
                    ],
                  ],
                ),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                labelWidget,
                const SizedBox(width: 20),
                Expanded(child: contentWidget),
                if (pill != null) ...[
                  const SizedBox(width: 12),
                  pill!,
                ],
              ],
            ),
    );
  }
}

class AmsFormGrid extends StatelessWidget {
  final List<Widget> children;
  final int cols;
  final double spacing;

  const AmsFormGrid({
    super.key,
    required this.children,
    this.cols = 2,
    this.spacing = 16,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, constraints) {
      final effectiveCols = constraints.maxWidth < 600
          ? 1
          : (constraints.maxWidth < 850 ? 2 : cols);
      return Wrap(
        spacing: spacing,
        runSpacing: 0, // AmsField already has vertical padding
        children: children.map((child) {
          final w = (constraints.maxWidth - (effectiveCols - 1) * spacing) /
              effectiveCols;
          return SizedBox(width: w.clamp(0, double.infinity), child: child);
        }).toList(),
      );
    });
  }
}

// ─── TEXT INPUT ───────────────────────────────────────────────
class AmsTextInput extends StatelessWidget {
  final String? placeholder;
  final bool readOnly;
  final String? initialValue;
  final TextEditingController? controller;
  final TextInputType keyboardType;
  final Color? borderColor;
  final bool obscureText;
  final void Function(String)? onChanged;
  final IconData? icon;
  final String? errorText;
  final bool isValid;
  final FocusNode? focusNode;
  final void Function(String)? onFieldSubmitted;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLines;
  final VoidCallback? onTap;

  const AmsTextInput({
    super.key,
    this.placeholder,
    this.readOnly = false,
    this.initialValue,
    this.controller,
    this.keyboardType = TextInputType.text,
    this.borderColor,
    this.obscureText = false,
    this.onChanged,
    this.icon,
    this.errorText,
    this.isValid = false,
    this.focusNode,
    this.onFieldSubmitted,
    this.textInputAction,
    this.inputFormatters,
    this.maxLines = 1,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      inputFormatters: inputFormatters,
      focusNode: focusNode,
      initialValue: controller == null ? initialValue : null,
      readOnly: readOnly,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      obscureText: obscureText,
      maxLines: maxLines,
      onChanged: onChanged,
      onFieldSubmitted: onFieldSubmitted,
      onTap: onTap,
      style:
          bodyStyle(size: 13, color: readOnly ? AppColors.ink3 : AppColors.ink),
      decoration: InputDecoration(
        hintText: placeholder,
        hintStyle: bodyStyle(size: 13, color: AppColors.ink4),
        errorText: errorText,
        errorStyle: bodyStyle(size: 11, color: AppColors.red),
        filled: true,
        fillColor: readOnly ? const Color(0xFFF7F9FC) : Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        prefixIcon:
            icon != null ? Icon(icon, size: 18, color: AppColors.ink3) : null,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide: BorderSide(
              color: borderColor ??
                  (isValid
                      ? AppColors.green
                      : (readOnly
                          ? AppColors.border
                          : const Color(0xFFD1D5DB))),
              width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide: BorderSide(
              color: isValid ? AppColors.green : AppColors.tBlue, width: 1.0),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide: const BorderSide(color: AppColors.red, width: 1.0),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide: const BorderSide(color: AppColors.red, width: 1.0),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide: const BorderSide(color: AppColors.border, width: 1.0),
        ),
      ),
    );
  }
}

// ─── DROPDOWN ─────────────────────────────────────────────────
class AmsDropdown extends StatelessWidget {
  final List<String> items;
  final String? initialValue;
  final String? placeholder;
  final void Function(String?)? onChanged;
  final FocusNode? focusNode;
  final String? errorText;
  final bool isValid;

  const AmsDropdown({
    super.key,
    required this.items,
    this.initialValue,
    this.placeholder,
    this.onChanged,
    this.focusNode,
    this.errorText,
    this.isValid = false,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      focusNode: focusNode,
      initialValue: initialValue ?? (placeholder == null ? items.first : null),
      hint: placeholder != null
          ? Text(placeholder!,
              style: bodyStyle(size: 13, color: AppColors.ink4))
          : null,
      onChanged: onChanged,
      style: bodyStyle(size: 13, color: AppColors.ink),
      decoration: InputDecoration(
        errorText: errorText,
        errorStyle: bodyStyle(size: 11, color: AppColors.red),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide: BorderSide(
              color: isValid ? AppColors.green : const Color(0xFFD1D5DB),
              width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide: BorderSide(
              color: isValid ? AppColors.green : AppColors.tBlue, width: 1.0),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide: const BorderSide(color: AppColors.red, width: 1.0),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide: const BorderSide(color: AppColors.red, width: 1.0),
        ),
      ),
      items: items
          .map((e) => DropdownMenuItem(
              value: e, child: Text(e, style: bodyStyle(size: 13))))
          .toList(),
    );
  }
}

class AmsStepInfo {
  final String label;
  final String sub;
  const AmsStepInfo(this.label, this.sub);
}

// ─── STEPPER ─────────────────────────────────────────────────
class AmsTopStepper extends StatelessWidget {
  final int currentStep;
  final bool nonTranMode;

  static const List<AmsStepInfo> steps = [
    AmsStepInfo('Login', 'Done'),
    AmsStepInfo('Select Type', 'Choose'),
    AmsStepInfo('Entry Form', 'Fill'),
    AmsStepInfo('Submit', 'AUTH101'),
    AmsStepInfo('Result', 'Final'),
  ];

  const AmsTopStepper({
    super.key,
    required this.currentStep,
    this.nonTranMode = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(steps.length * 2 - 1, (i) {
            if (i.isOdd) {
              final stepIdx = i ~/ 2;
              final isDone = stepIdx + 1 < currentStep;
              Color lineColor = AppColors.border;
              if (isDone) lineColor = AppColors.green;
              if (stepIdx + 1 == currentStep) {
                lineColor = nonTranMode ? AppColors.nTealMd : AppColors.tBlueMd;
              }
              return Container(width: 24, height: 2, color: lineColor);
            }
            final idx = i ~/ 2;
            final n = idx + 1;
            final isDone = n < currentStep;
            final isActive = n == currentStep;
            Color dotBg = AppColors.border;
            Color dotFg = AppColors.ink3;
            List<BoxShadow>? shadow;
            if (isDone) {
              dotBg = AppColors.green;
              dotFg = Colors.white;
            } else if (isActive) {
              dotBg = nonTranMode ? AppColors.nTeal : AppColors.tBlue;
              dotFg = Colors.white;
              shadow = [
                BoxShadow(
                    color:
                        (nonTranMode ? AppColors.nTealLt : AppColors.tBlueLt),
                    spreadRadius: 4)
              ];
            }
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: dotBg,
                    shape: BoxShape.circle,
                    boxShadow: shadow,
                  ),
                  child: Center(
                    child: Text(
                      isDone ? '✓' : '$n',
                      style: monoStyle(
                          size: 9, weight: FontWeight.w700, color: dotFg),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      steps[idx].label,
                      style: bodyStyle(
                        size: 10,
                        weight: FontWeight.w600,
                        color: isDone
                            ? AppColors.green
                            : isActive
                                ? (nonTranMode
                                    ? AppColors.nTeal
                                    : AppColors.tBlue)
                                : AppColors.ink3,
                      ),
                    ),
                    Text(steps[idx].sub,
                        style: monoStyle(size: 8, color: AppColors.ink3)),
                  ],
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

// ─── TOP BAR ─────────────────────────────────────────────────
class AmsTopBar extends StatelessWidget {
  final int currentStep;
  final String brandSub;
  final Color? brandColor;
  final bool nonTranMode;
  final String? userName;

  const AmsTopBar({
    super.key,
    required this.currentStep,
    this.brandSub = 'Normal Auth Flow',
    this.brandColor,
    this.nonTranMode = false,
    this.userName,
  });

  @override
  Widget build(BuildContext context) {
    final accent =
        brandColor ?? (nonTranMode ? AppColors.nTeal : AppColors.tBlue);

    String name = userName ?? 'Arjun Mehta';
    String initials = '';
    if (name.contains('@')) {
      initials = name.substring(0, 1).toUpperCase();
    } else {
      final parts = name.split(' ');
      if (parts.length >= 2) {
        initials = parts[0][0].toUpperCase() + parts[1][0].toUpperCase();
      } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
        initials = parts[0][0].toUpperCase();
      }
    }
    if (initials.isEmpty) initials = 'U';

    return Container(
      height: 62,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
        boxShadow: [
          BoxShadow(
              color: Color(0x0F000000), blurRadius: 8, offset: Offset(0, 1))
        ],
      ),
      child: Row(
        children: [
          // Brand
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    'assets/images/logo.jpg',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('BBOTS Management',
                      style: bodyStyle(size: 14, weight: FontWeight.w700)),
                  Text(brandSub,
                      style: monoStyle(size: 9, color: AppColors.ink3)),
                ],
              ),
            ],
          ),
          const Spacer(),
          // User chip
          Container(
            padding: const EdgeInsets.fromLTRB(5, 4, 14, 4),
            decoration: BoxDecoration(
              color: AppColors.bg,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: accent,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(initials,
                        style: monoStyle(
                            size: 9,
                            weight: FontWeight.w700,
                            color: Colors.white)),
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: bodyStyle(size: 11, weight: FontWeight.w600)),
                    Text('EMP00123 · Branch Mgr',
                        style: monoStyle(size: 9, color: AppColors.ink3)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── BREADCRUMB ITEM ─────────────────────────────────────────
class HeaderBreadcrumb {
  final String label;
  final VoidCallback? onTap;

  HeaderBreadcrumb({required this.label, this.onTap});
}

// ─── IDENTITY HEADER ─────────────────────────────────────────
class AmsIdentityHeader extends StatefulWidget {
  final Widget icon;
  final String title;
  final String subtitle;
  final List<Widget> badges;
  final Color accentColor;
  final Color accentLt;
  final Color accentMd;
  final List<HeaderBreadcrumb>? breadcrumbs;
  final VoidCallback onBack;
  final List<Widget>? actions;
  final bool showBack;

  const AmsIdentityHeader({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.badges,
    required this.accentColor,
    required this.accentLt,
    required this.accentMd,
    this.breadcrumbs,
    required this.onBack,
    this.actions,
    this.showBack = true,
  });

  @override
  State<AmsIdentityHeader> createState() => _AmsIdentityHeaderState();
}

class _AmsIdentityHeaderState extends State<AmsIdentityHeader> {
  bool _isHover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHover = true),
      onExit: (_) => setState(() => _isHover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 🔥 Breadcrumbs (SHOW ONLY ON HOVER)
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 200),
              crossFadeState: _isHover
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
              firstChild: Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: widget.breadcrumbs!.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final item = entry.value;
                    final isLast = idx == widget.breadcrumbs!.length - 1;

                    return Row(
                      children: [
                        MouseRegion(
                          cursor: item.onTap != null
                              ? SystemMouseCursors.click
                              : SystemMouseCursors.basic,
                          child: GestureDetector(
                            onTap: item.onTap,
                            child: Text(
                              item.label,
                              style: bodyStyle(
                                size: 11,
                                weight: FontWeight.w600,
                                color: AppColors.ink4,
                              ).copyWith(
                                decoration: item.onTap != null
                                    ? TextDecoration.underline
                                    : TextDecoration.none,
                                decorationColor:
                                    AppColors.ink4.withOpacity(0.3),
                              ),
                            ),
                          ),
                        ),
                        if (!isLast)
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6),
                            child: Icon(
                              Icons.chevron_right_rounded,
                              size: 14,
                              color: AppColors.ink4,
                            ),
                          ),
                      ],
                    );
                  }).toList(),
                ),
              ),
              secondChild: const SizedBox(),
            ),

            /// Title Row
            Row(
              children: [
                widget.icon,
                const SizedBox(width: 10),
                Text(
                  widget.title,
                  style: bodyStyle(
                    size: 16,
                    weight: FontWeight.w800,
                    color: widget.accentColor,
                  ),
                ),
                const Spacer(),

                if (widget.actions != null) ...[
                  ...widget.actions!,
                  const SizedBox(width: 12),
                ],

                /// Back Button
                GestureDetector(
                  onTap: widget.onBack,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.red,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.arrow_back, color: Colors.white, size: 14),
                        SizedBox(width: 6),
                        Text(
                          "Back",
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── SUBMIT BAR ───────────────────────────────────────────────
class AmsSubmitBar extends StatelessWidget {
  final Color borderColor;
  final List<Widget> actions;

  const AmsSubmitBar({
    super.key,
    required this.borderColor,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: borderColor.withOpacity(0.2), width: 1.5),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: actions,
          ),
        ],
      ),
    );
  }
}

void showAmsSnack(BuildContext context, String msg,
    {String type = 'i', int seconds = 3, String? icon}) {
  late Color bg;
  late Color border;
  late Color accent;

  switch (type) {
    case 's': // success
      bg = const Color(0xFFF0FDF4);
      border = const Color(0xFFDCFCE7);
      accent = AppColors.green;
    case 'e': // error
      bg = const Color(0xFFFEF2F2);
      border = const Color(0xFFFEE2E2);
      accent = AppColors.red;
    case 'w': // warning
      bg = const Color(0xFFFFFBEB);
      border = const Color(0xFFFEF3C7);
      accent = AppColors.amber;
    default: // info
      bg = const Color(0xFFF0F9FF);
      border = const Color(0xFFE0F2FE);
      accent = AppColors.tBlue;
  }

  final displayIcon = icon ??
      (type == 's'
          ? '✅'
          : type == 'e'
              ? '❌'
              : type == 'w'
                  ? '⚠️'
                  : 'ℹ️');

  ScaffoldMessenger.of(context).clearSnackBars();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      elevation: 0,
      backgroundColor: Colors.transparent,
      duration: Duration(seconds: seconds),
      content: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(color: border),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: accent.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                  child:
                      Text(displayIcon, style: const TextStyle(fontSize: 14))),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                msg,
                style: bodyStyle(
                    size: 13, weight: FontWeight.w600, color: AppColors.ink),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// ─── SIDEBAR ITEM ─────────────────────────────────────────────
// ─── SIDEBAR ITEM ─────────────────────────────────────────────
class AmsSidebarItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isCollapsed;
  final Color? color;

  const AmsSidebarItem({
    super.key,
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    this.isCollapsed = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: EdgeInsets.only(
              left: isCollapsed ? 6 : 12, right: 0, top: 2, bottom: 2),
          padding: EdgeInsets.symmetric(
              horizontal: isCollapsed ? 0 : 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.transparent,
            border: isSelected
                ? const Border(left: BorderSide(color: Colors.white, width: 3))
                : null,
          ),
          child: isCollapsed
              ? Center(
                  child: Icon(icon,
                      size: 24,
                      color: color ??
                          (isSelected ? Colors.white : Colors.white70)),
                )
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const NeverScrollableScrollPhysics(),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Icon(icon,
                          size: 24,
                          color: color ??
                              (isSelected ? Colors.white : Colors.white70)),
                      const SizedBox(width: 14),
                      SizedBox(
                        width: 200,
                        child: Text(
                          label,
                          style: bodyStyle(
                            size: 14,
                            weight:
                                isSelected ? FontWeight.w700 : FontWeight.w600,
                            color: color ??
                                (isSelected ? Colors.white : Colors.white70),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

// ─── SUB SIDEBAR ITEM ─────────────────────────────────────────
class AmsSubSidebarItem extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData? icon;
  final bool isCollapsed;

  const AmsSubSidebarItem({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.icon,
    this.isCollapsed = false,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: EdgeInsets.only(
              left: isCollapsed ? 6 : 30, right: 0, top: 1, bottom: 1),
          padding: EdgeInsets.symmetric(
              horizontal: isCollapsed ? 8 : 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.transparent,
            border: isSelected
                ? const Border(
                    left: BorderSide(
                      color: Colors.white,
                      width: 2,
                    ),
                  )
                : null,
          ),
          child: isCollapsed
              ? Center(
                  child: Icon(icon ?? Icons.adjust_rounded,
                      size: 18,
                      color: isSelected ? Colors.white : Colors.white70),
                )
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const NeverScrollableScrollPhysics(),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Icon(icon ?? Icons.circle,
                          size: 8,
                          color: isSelected ? Colors.white : Colors.white70),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 185,
                        child: Text(
                          label,
                          style: bodyStyle(
                            size: 12,
                            weight:
                                isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? Colors.white : Colors.white70,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

// ─── SIDEBAR ──────────────────────────────────────────────────
class AmsSidebar extends StatefulWidget {
  final String currentScreen;
  final String? selectedProg;
  final void Function(String screen, String? prog) onNavigate;
  final bool isCollapsed;
  final VoidCallback onToggle;

  const AmsSidebar({
    super.key,
    required this.currentScreen,
    this.selectedProg,
    required this.onNavigate,
    required this.isCollapsed,
    required this.onToggle,
  });

  @override
  State<AmsSidebar> createState() => _AmsSidebarState();
}

class _AmsSidebarState extends State<AmsSidebar> {
  String openMenu = ''; // 'masters', 'gl', 'config', 'auth'

  @override
  void initState() {
    super.initState();
    // Auto open menu based on selected page
    if ([
      'USR-CRT',
      'USR-ROLE',
      'ROLE-CRT',
      'MOD-CRT',
      'MENU-CRT',
      'ORG-CRT',
      'PROG-CRT',
      'BRN-CRT'
    ].contains(widget.selectedProg)) {
      openMenu = 'masters';
    } else if (['GL-CAT', 'GL-MST', 'GL-CUR', 'GL-BRN', 'GL-SEG', 'GL-ATT']
        .contains(widget.selectedProg)) {
      openMenu = 'gl';
    } else if (['AUTHCTL'].contains(widget.selectedProg)) {
      openMenu = 'config';
    } else if (widget.currentScreen == 'nontranauth') {
      openMenu = 'auth';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: widget.isCollapsed ? 70 : 240,
      decoration: const BoxDecoration(
        color: Color(0xFF1E2B5E), // Dark Blue Sidebar
        border: Border(
          right: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: Column(
        children: [
          // 🔹 MENU LIST
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(top: 24, bottom: 24),
              children: [
                if (!widget.isCollapsed) _sectionHeader('GENERAL'),

                // 🔹 Dashboard
                AmsSidebarItem(
                  label: widget.isCollapsed ? '' : 'Dashboard',
                  icon: Icons.dashboard_rounded,
                  isCollapsed: widget.isCollapsed,
                  isSelected: widget.currentScreen == 'list' &&
                      widget.selectedProg == null,
                  onTap: () {
                    setState(() {
                      openMenu = '';
                    });
                    widget.onNavigate('list', null);
                  },
                ),

                const SizedBox(height: 16),

                // 🔹 MASTERS
                AmsSidebarItem(
                  label: widget.isCollapsed ? '' : 'Masters',
                  icon: openMenu == 'masters'
                      ? Icons.folder_open_rounded
                      : Icons.folder_shared_rounded,
                  isCollapsed: widget.isCollapsed,
                  isSelected: (widget.currentScreen == 'submenu_dashboard' &&
                      widget.selectedProg == 'MASTERS'),
                  onTap: () {
                    setState(() {
                      openMenu = openMenu == 'masters' ? '' : 'masters';
                    });
                    widget.onNavigate('submenu_dashboard', 'MASTERS');
                  },
                ),

                if (openMenu == 'masters') ...[
                  AmsSubSidebarItem(
                    label: 'Branch',
                    isCollapsed: widget.isCollapsed,
                    icon: Icons.store_rounded,
                    isSelected: widget.selectedProg == 'BRN-CRT',
                    onTap: () => widget.onNavigate('nontran', 'BRN-CRT'),
                  ),
                  AmsSubSidebarItem(
                    label: 'User',
                    isCollapsed: widget.isCollapsed,
                    icon: Icons.person_add_rounded,
                    isSelected: widget.selectedProg == 'USR-CRT',
                    onTap: () => widget.onNavigate('nontran', 'USR-CRT'),
                  ),
                  AmsSubSidebarItem(
                    label: 'User Role Assign',
                    isCollapsed: widget.isCollapsed,
                    icon: Icons.assignment_ind_rounded,
                    isSelected: widget.selectedProg == 'USR-ROLE',
                    onTap: () => widget.onNavigate('nontran', 'USR-ROLE'),
                  ),
                  AmsSubSidebarItem(
                    label: 'Role',
                    isCollapsed: widget.isCollapsed,
                    icon: Icons.supervised_user_circle_rounded,
                    isSelected: widget.selectedProg == 'ROLE-CRT',
                    onTap: () => widget.onNavigate('nontran', 'ROLE-CRT'),
                  ),
                  AmsSubSidebarItem(
                    label: 'Modules',
                    isCollapsed: widget.isCollapsed,
                    icon: Icons.view_module_rounded,
                    isSelected: widget.selectedProg == 'MOD-CRT',
                    onTap: () => widget.onNavigate('nontran', 'MOD-CRT'),
                  ),
                  AmsSubSidebarItem(
                    label: 'Menus',
                    isCollapsed: widget.isCollapsed,
                    icon: Icons.menu_open_rounded,
                    isSelected: widget.selectedProg == 'MENU-CRT',
                    onTap: () => widget.onNavigate('nontran', 'MENU-CRT'),
                  ),
                  AmsSubSidebarItem(
                    label: 'Program',
                    isCollapsed: widget.isCollapsed,
                    icon: Icons.app_settings_alt_rounded,
                    isSelected: widget.selectedProg == 'PROG-CRT',
                    onTap: () => widget.onNavigate('nontran', 'PROG-CRT'),
                  ),
                  AmsSubSidebarItem(
                    label: 'Organisation',
                    isCollapsed: widget.isCollapsed,
                    icon: Icons.business_rounded,
                    isSelected: widget.selectedProg == 'ORG-CRT',
                    onTap: () => widget.onNavigate('nontran', 'ORG-CRT'),
                  ),
                ],

                const SizedBox(height: 16),

                // 🔹 GL MODULE
                AmsSidebarItem(
                  label: widget.isCollapsed ? '' : 'GL Module',
                  icon: openMenu == 'gl'
                      ? Icons.account_balance_rounded
                      : Icons.account_balance_outlined,
                  isCollapsed: widget.isCollapsed,
                  isSelected: (widget.currentScreen == 'submenu_dashboard' &&
                      widget.selectedProg == 'GL'),
                  onTap: () {
                    setState(() {
                      openMenu = openMenu == 'gl' ? '' : 'gl';
                    });
                    widget.onNavigate('submenu_dashboard', 'GL');
                  },
                ),

                if (openMenu == 'gl') ...[
                  AmsSubSidebarItem(
                    label: 'GL Category',
                    isCollapsed: widget.isCollapsed,
                    icon: Icons.category_rounded,
                    isSelected: widget.selectedProg == 'GL-CAT',
                    onTap: () => widget.onNavigate('nontran', 'GL-CAT'),
                  ),
                  AmsSubSidebarItem(
                    label: 'GL Master',
                    isCollapsed: widget.isCollapsed,
                    icon: Icons.account_balance_wallet_rounded,
                    isSelected: widget.selectedProg == 'GL-MST',
                    onTap: () => widget.onNavigate('nontran', 'GL-MST'),
                  ),
                  AmsSubSidebarItem(
                    label: 'Allowed Currency',
                    isCollapsed: widget.isCollapsed,
                    icon: Icons.currency_exchange_rounded,
                    isSelected: widget.selectedProg == 'GL-CUR',
                    onTap: () => widget.onNavigate('nontran', 'GL-CUR'),
                  ),
                  AmsSubSidebarItem(
                    label: 'Allowed Branch',
                    isCollapsed: widget.isCollapsed,
                    icon: Icons.store_rounded,
                    isSelected: widget.selectedProg == 'GL-BRN',
                    onTap: () => widget.onNavigate('nontran', 'GL-BRN'),
                  ),
                  AmsSubSidebarItem(
                    label: 'GL Segments',
                    isCollapsed: widget.isCollapsed,
                    icon: Icons.pie_chart_rounded,
                    isSelected: widget.selectedProg == 'GL-SEG',
                    onTap: () => widget.onNavigate('nontran', 'GL-SEG'),
                  ),
                  AmsSubSidebarItem(
                    label: 'GL Attributes',
                    isCollapsed: widget.isCollapsed,
                    icon: Icons.tune_rounded,
                    isSelected: widget.selectedProg == 'GL-ATT',
                    onTap: () => widget.onNavigate('nontran', 'GL-ATT'),
                  ),
                ],

                const SizedBox(height: 16),
                if (!widget.isCollapsed) _sectionHeader('SYSTEM'),

                // 🔹 CONFIGURATION
                AmsSidebarItem(
                  label: widget.isCollapsed ? '' : 'Configuration',
                  icon: Icons.settings_suggest_rounded,
                  isCollapsed: widget.isCollapsed,
                  isSelected: (widget.currentScreen == 'submenu_dashboard' &&
                      widget.selectedProg == 'CONFIG'),
                  onTap: () {
                    setState(() {
                      openMenu = openMenu == 'config' ? '' : 'config';
                    });
                    widget.onNavigate('submenu_dashboard', 'CONFIG');
                  },
                ),

                if (openMenu == 'config') ...[
                  AmsSubSidebarItem(
                    label: 'Auth Controller',
                    isCollapsed: widget.isCollapsed,
                    icon: Icons.admin_panel_settings_rounded,
                    isSelected: widget.selectedProg == 'AUTHCTL',
                    onTap: () => widget.onNavigate('nontran', 'AUTHCTL'),
                  ),
                ],

                const SizedBox(height: 16),

                // 🔹 AUTH
                AmsSidebarItem(
                  label: widget.isCollapsed ? '' : 'Auth Queue',
                  icon: Icons.security_rounded,
                  isCollapsed: widget.isCollapsed,
                  isSelected: (widget.currentScreen == 'submenu_dashboard' &&
                      widget.selectedProg == 'AUTH'),
                  onTap: () {
                    setState(() {
                      openMenu = openMenu == 'auth' ? '' : 'auth';
                    });
                    widget.onNavigate('submenu_dashboard', 'AUTH');
                  },
                ),

                if (openMenu == 'auth') ...[
                  AmsSubSidebarItem(
                    label: 'Authorization',
                    isCollapsed: widget.isCollapsed,
                    icon: Icons.rule_folder_rounded,
                    isSelected: widget.currentScreen == 'nontranauth',
                    onTap: () => widget.onNavigate('nontranauth', null),
                  ),
                ],
              ],
            ),
          ),

          const Divider(height: 1, color: AppColors.border2),

          // 🔹 LOGOUT
          // Padding(
          //   padding: const EdgeInsets.all(12),
          //   child: AmsSidebarItem(
          //     label: widget.isCollapsed ? '' : 'Logout',
          //     icon: Icons.logout_rounded,
          //     isSelected: false,
          //     isCollapsed: widget.isCollapsed,
          //     color: AppColors.red,
          //     onTap: () => widget.onNavigate('login', null),
          //   ),
          // ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
      child: Text(
        title,
        style:
            monoStyle(size: 10, weight: FontWeight.w800, color: Colors.white54),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// 🔹 AMS SHELL
// ─────────────────────────────────────────────────────────────
class AmsShell extends StatefulWidget {
  final Widget child;
  final String currentScreen;
  final String? selectedProg;
  final void Function(String screen, String? prog) onNavigate;
  final String? userName;

  const AmsShell({
    super.key,
    required this.child,
    required this.currentScreen,
    this.selectedProg,
    required this.onNavigate,
    this.userName,
  });

  @override
  State<AmsShell> createState() => _AmsShellState();
}

class _AmsShellState extends State<AmsShell> {
  bool _isCollapsed = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          _HoverTopBar(
            userName: widget.userName,
            onNavigate: widget.onNavigate,
          ),
          Expanded(
            child: Row(
              children: [
                MouseRegion(
                  onEnter: (_) => setState(() => _isCollapsed = false),
                  onExit: (_) => setState(() => _isCollapsed = true),
                  child: AnimatedSize(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    child: AmsSidebar(
                      currentScreen: widget.currentScreen,
                      selectedProg: widget.selectedProg,
                      onNavigate: widget.onNavigate,
                      isCollapsed: _isCollapsed,
                      onToggle: () =>
                          setState(() => _isCollapsed = !_isCollapsed),
                    ),
                  ),
                ),
                Expanded(child: widget.child),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 🔥 TOP BAR
  Widget _buildTopBar(BuildContext context) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2B5E), // Match Sidebar Dark Blue
        border: const Border(
          bottom: BorderSide(color: Colors.white12),
        ),
      ),
      child: Row(
        children: [
          /// ✅ 9 DOTS
          _PremiumAppLauncher(),
          const SizedBox(width: 12),

          /// 🔹 LOGO
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.tBlue,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.shield_rounded,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 10),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("FINANCE",
                      style: bodyStyle(
                          size: 18,
                          weight: FontWeight.w800,
                          color: Colors.white)),
                  Text("Management System",
                      style: bodyStyle(size: 10, color: Colors.white70)),
                ],
              ),
            ],
          ),

          const Spacer(),

          /// 🔹 ICONS
          _topIconBox(Icons.help_outline_rounded),
          const SizedBox(width: 8),
          _topIconBox(Icons.notifications_none_rounded),
          const SizedBox(width: 8),
          _topIconBox(Icons.settings_outlined),

          const SizedBox(width: 16),

          Container(height: 32, width: 1, color: Colors.white24),

          const SizedBox(width: 16),

          /// 🔹 PROFILE
          _profileAvatar(context),
        ],
      ),
    );
  }

  Widget _topIconBox(IconData icon) {
    return _HoverIconButton(icon: icon);
  }

  Widget _profileAvatar(BuildContext context) {
    return _PremiumProfileMenu(
      userName: widget.userName,
      onNavigate: widget.onNavigate,
    );
  }
}

class _HoverTopBar extends StatefulWidget {
  final String? userName;
  final void Function(String, String?) onNavigate;

  const _HoverTopBar({
    this.userName,
    required this.onNavigate,
  });

  @override
  State<_HoverTopBar> createState() => _HoverTopBarState();
}

class _HoverTopBarState extends State<_HoverTopBar> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        alignment: Alignment.center,
        height: _hover ? 72 : 45, //  Height collapse / expand
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: const BoxDecoration(
          color: Color(0xFF1E2B5E),
          border: Border(
            bottom: BorderSide(color: Colors.white12),
          ),
        ),
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Top Row (Always visible)
              Row(
                children: [
                  _PremiumAppLauncher(),
                  const SizedBox(width: 12),

                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppColors.tBlue,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.shield_rounded,
                        color: Colors.white, size: 20),
                  ),

                  const SizedBox(width: 10),

                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "FINANCE",
                        style: bodyStyle(
                          size: 16,
                          weight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      if (_hover)
                        Text(
                          "Management System",
                          style: bodyStyle(
                            size: 10,
                            color: Colors.white70,
                          ),
                        ),
                    ],
                  ),

                  const Spacer(),

                  /// Icons only when expanded
                  if (_hover) ...[
                    _HoverIconButton(icon: Icons.help_outline_rounded),
                    const SizedBox(width: 8),
                    _HoverIconButton(icon: Icons.notifications_none_rounded),
                    const SizedBox(width: 8),
                    _HoverIconButton(icon: Icons.settings_outlined),
                    const SizedBox(width: 16),
                    Container(height: 28, width: 1, color: Colors.white24),
                    const SizedBox(width: 16),
                  ],
                  _PremiumProfileMenu(
                    userName: widget.userName,
                    onNavigate: widget.onNavigate,
                    isExpanded: _hover,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// 🔹 ANIMATED NINE DOTS
// ─────────────────────────────────────────────────────────────
class _AnimatedNineDots extends StatefulWidget {
  final bool isHovered;
  const _AnimatedNineDots({required this.isHovered});

  @override
  State<_AnimatedNineDots> createState() => _AnimatedNineDotsState();
}

class _AnimatedNineDotsState extends State<_AnimatedNineDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
  }

  @override
  void didUpdateWidget(_AnimatedNineDots oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isHovered && !oldWidget.isHovered) {
      _controller.forward(from: 0.0);
    } else if (!widget.isHovered && oldWidget.isHovered) {
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 26,
      height: 26,
      child: Center(
        child: Wrap(
          spacing: 2,
          runSpacing: 2,
          children: List.generate(9, (index) {
            final delay = index * 0.05;
            final animation = TweenSequence([
              TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.6), weight: 50),
              TweenSequenceItem(tween: Tween(begin: 1.6, end: 1.0), weight: 50),
            ]).animate(
              CurvedAnimation(
                parent: _controller,
                curve: Interval(delay, delay + 0.5, curve: Curves.easeInOut),
              ),
            );

            return AnimatedBuilder(
              animation: animation,
              builder: (context, child) {
                return Transform.scale(
                  scale: widget.isHovered ? animation.value : 1.0,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: widget.isHovered ? Colors.blue : Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              },
            );
          }),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// 🔹 9 DOTS APP LAUNCHER
// ─────────────────────────────────────────────────────────────
class _PremiumAppLauncher extends StatefulWidget {
  @override
  State<_PremiumAppLauncher> createState() => _PremiumAppLauncherState();
}

class _PremiumAppLauncherState extends State<_PremiumAppLauncher> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton(
      offset: const Offset(0, 50),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _hover
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: _AnimatedNineDots(isHovered: _hover),
        ),
      ),
      itemBuilder: (context) => [
        PopupMenuItem(
          enabled: false,
          child: SizedBox(
            width: 250,
            child: GridView.count(
              shrinkWrap: true,
              crossAxisCount: 3,
              children: [
                _appItem(Icons.dashboard_rounded, "Dashboard"),
                _appItem(Icons.admin_panel_settings_rounded, "User"),
                _appItem(Icons.people_alt_rounded, "HRMS"),
                _appItem(Icons.handshake_rounded, "CRM"),
                _appItem(Icons.verified_user, "Auth"),
                _appItem(Icons.settings_rounded, "Admin"),
                _appItem(Icons.security_rounded, "Security"),
                _appItem(Icons.notifications_active_rounded, "Alerts"),
                _appItem(Icons.support_agent_rounded, "Support"),
                _appItem(Icons.payments, "Payments"),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _appItem(IconData icon, String label) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 22, color: Colors.blue.shade900),
        const SizedBox(height: 6),
        Text(label, style: bodyStyle(size: 11)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// 🔹 ICON HOVER
// ─────────────────────────────────────────────────────────────
class _HoverIconButton extends StatefulWidget {
  final IconData icon;

  const _HoverIconButton({required this.icon});

  @override
  State<_HoverIconButton> createState() => _HoverIconButtonState();
}

class _HoverIconButtonState extends State<_HoverIconButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color:
              _hover ? Colors.white.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(widget.icon,
            size: 20, color: _hover ? Colors.white : Colors.white70),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// 🔹 PROFILE MENU
// ─────────────────────────────────────────────────────────────
class _PremiumProfileMenu extends StatelessWidget {
  final String? userName;
  final void Function(String, String?) onNavigate;
  final bool isExpanded;

  const _PremiumProfileMenu({
    this.userName,
    required this.onNavigate,
    this.isExpanded = true,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton(
      tooltip: '', // Disable the default 'Show menu' tooltip
      offset: const Offset(0, 45),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                userName ?? "User@gmail.com",
                style: bodyStyle(
                    size: 13, weight: FontWeight.w700, color: Colors.white),
              ),
              if (isExpanded) ...[
                const SizedBox(height: 2),
                Text(
                  "Administrator",
                  style: bodyStyle(size: 11, color: Colors.white),
                ),
              ],
            ],
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () async {
              final user = await UserService.getUserProfile();

              print("USER DATA : $user");

              if (user == null) return;

              showMenu(
                context: context,
                position: RelativeRect.fromLTRB(
                  MediaQuery.of(context).size.width - 300,
                  60,
                  20,
                  0,
                ),
                items: [
                  PopupMenuItem(
                    enabled: false,
                    child: Container(
                      width: 280,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          /// Avatar
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blue.withOpacity(.25),
                                  blurRadius: 12,
                                )
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 28,
                              backgroundColor: AppColors.tBlue,
                              child: Text(
                                (user['username'] ?? "A")[0],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          /// Username
                          Text(
                            user['username'] ?? "",
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: Colors.black87,
                            ),
                          ),

                          const SizedBox(height: 4),

                          /// Email
                          Text(
                            user['email'] ?? "",
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.grey,
                            ),
                          ),

                          const SizedBox(height: 8),

                          /// Role Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.tBlue.withOpacity(.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              "ROLE: ${user['role'] ?? ""}",
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.tBlue,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          const Divider(),

                          /// Logout Button
                          InkWell(
                            onTap: () async {
                              Navigator.pop(context);
                              apiService.updateToken(null);
                              onNavigate('login', null);
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 10,
                                horizontal: 12,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.logout,
                                      size: 18, color: Colors.red),
                                  SizedBox(width: 6),
                                  Text(
                                    "Logout",
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
            child: CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.tBlueLt,
              child: Text(
                (userName ?? 'A')[0].toUpperCase(),
                style: bodyStyle(
                    size: 14, weight: FontWeight.w800, color: AppColors.tBlue),
              ),
            ),
          ),
        ],
      ),

      itemBuilder: (context) => [
        PopupMenuItem(
          child: const Text("Profile"),
        ),
        PopupMenuItem(
          child: const Text("Logout"),
          onTap: () => onNavigate('login', null),
        ),
      ],
    );
  }
}

// ─── AUTH TABLE ──────────────────────────────────────────────
class AmsAuthTable extends StatelessWidget {
  final List<String> headers;
  final List<TableRow> rows;
  final Map<int, TableColumnWidth>? columnWidths;

  const AmsAuthTable({
    super.key,
    required this.headers,
    required this.rows,
    this.columnWidths,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border2),
      ),
      child: Table(
        columnWidths: columnWidths,
        border: TableBorder(
          horizontalInside: const BorderSide(color: Colors.white, width: 2),
          verticalInside: const BorderSide(color: Colors.white, width: 2),
        ),
        children: [
          // Header Row
          TableRow(
            decoration: const BoxDecoration(color: Color(0xFF1E6381)),
            children: headers.map((h) => _headerCell(h)).toList(),
          ),
          ...rows,
        ],
      ),
    );
  }

  Widget _headerCell(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Text(
        text,
        style:
            bodyStyle(size: 12, weight: FontWeight.w700, color: Colors.white),
      ),
    );
  }
}

// ─── AUTH FIELD ─────────────────────────────────────────────
class AmsAuthField extends StatelessWidget {
  final String label;
  final String value;
  final int maxLines;
  final bool isEditable;
  final String? placeholder;
  final TextEditingController? controller;
  final bool labelAbove;

  const AmsAuthField({
    super.key,
    required this.label,
    required this.value,
    this.maxLines = 1,
    this.isEditable = false,
    this.placeholder,
    this.controller,
    this.labelAbove = false,
  });

  @override
  Widget build(BuildContext context) {
    if (labelAbove) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: bodyStyle(
                size: 13,
                weight: FontWeight.w500,
                color: AppColors.ink2,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: maxLines == 1 ? 38 : 64,
              width: double.infinity,
              decoration: BoxDecoration(
                color: isEditable ? Colors.white : const Color(0xFFF8FAFB),
                border: Border.all(color: const Color(0xFFD1D5DB), width: 1.0),
                borderRadius: BorderRadius.circular(5),
              ),
              child: isEditable
                  ? TextField(
                      controller: controller,
                      maxLines: maxLines,
                      style: bodyStyle(size: 13),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: placeholder,
                        hintStyle: bodyStyle(size: 13, color: AppColors.ink4),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                      ),
                    )
                  : Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      child: Text(
                        value,
                        style: monoStyle(size: 13, color: AppColors.ink),
                      ),
                    ),
            ),
          ],
        ),
      );
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: maxLines == 1 ? 38 : 64,
          margin: const EdgeInsets.only(top: 10),
          width: double.infinity,
          decoration: BoxDecoration(
            color: isEditable ? Colors.white : const Color(0xFFF8FAFB),
            border: Border.all(color: const Color(0xFF1E6381), width: 1.2),
            borderRadius: BorderRadius.circular(2),
          ),
          child: isEditable
              ? TextField(
                  controller: controller,
                  maxLines: maxLines,
                  style: bodyStyle(size: 13),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: placeholder,
                    hintStyle: bodyStyle(size: 13, color: AppColors.ink4),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                )
              : Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Text(value,
                      style: monoStyle(size: 13, color: AppColors.ink)),
                ),
        ),
        Positioned(
          top: 0,
          left: 10,
          child: Container(
            color: AppColors.bg,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              label,
              style: bodyStyle(
                  size: 11, color: AppColors.ink2, weight: FontWeight.w500),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── PAGINATION WRAPPER ─────────────────────────────────────────
class AmsPaginatedView<T> extends StatefulWidget {
  final List<T> items;
  final int itemsPerPage;
  final bool shrinkWrap;
  final int? totalRecords; // New: for server-side
  final Function(int page)? onPageChanged; // New: for server-side
  final Widget Function(BuildContext context, List<T> currentItems) builder;

  const AmsPaginatedView({
    super.key,
    required this.items,
    this.itemsPerPage = 10,
    this.shrinkWrap = false,
    this.totalRecords,
    this.onPageChanged,
    required this.builder,
  });

  @override
  State<AmsPaginatedView<T>> createState() => _AmsPaginatedViewState<T>();
}

class _AmsPaginatedViewState<T> extends State<AmsPaginatedView<T>> {
  int _currentPage = 1;

  @override
  void didUpdateWidget(AmsPaginatedView<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.onPageChanged == null && oldWidget.items != widget.items) {
      _currentPage = 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalItems = widget.totalRecords ?? widget.items.length;
    if (totalItems == 0 && widget.items.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('No records found',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 15)),
        ),
      );
    }

    final totalPages = (totalItems / widget.itemsPerPage).ceil();
    if (_currentPage > totalPages && totalPages > 0) _currentPage = totalPages;

    final startIndex = (_currentPage - 1) * widget.itemsPerPage;

    // If server-side, we use items directly. If client-side, we sublist.
    final currentItems = widget.onPageChanged != null
        ? widget.items
        : widget.items.skip(startIndex).take(widget.itemsPerPage).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: widget.shrinkWrap ? MainAxisSize.min : MainAxisSize.max,
      children: [
        if (widget.shrinkWrap)
          widget.builder(context, currentItems)
        else
          Expanded(child: widget.builder(context, currentItems)),
        if (totalPages > 1)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
              color: Colors.white,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                    'Showing ${startIndex + 1} to ${startIndex + currentItems.length}',
                    style: const TextStyle(
                        fontSize: 13, color: Color(0xFF64748B))),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: _currentPage > 1
                          ? () {
                              setState(() => _currentPage--);
                              if (widget.onPageChanged != null)
                                widget.onPageChanged!(_currentPage);
                            }
                          : null,
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: _currentPage > 1
                                  ? const Color(0xFFE2E8F0)
                                  : Colors.transparent),
                        ),
                        child: Icon(
                          Icons.chevron_left_rounded,
                          color: _currentPage > 1
                              ? const Color(0xFF0F172A)
                              : const Color(0xFFCBD5E1),
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text('Page $_currentPage of $totalPages',
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0F172A))),
                    const SizedBox(width: 16),
                    InkWell(
                      onTap: _currentPage < totalPages
                          ? () {
                              setState(() => _currentPage++);
                              if (widget.onPageChanged != null)
                                widget.onPageChanged!(_currentPage);
                            }
                          : null,
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: _currentPage < totalPages
                                  ? const Color(0xFFE2E8F0)
                                  : Colors.transparent),
                        ),
                        child: Icon(
                          Icons.chevron_right_rounded,
                          color: _currentPage < totalPages
                              ? const Color(0xFF0F172A)
                              : const Color(0xFFCBD5E1),
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ─── SEARCHABLE DROPDOWN ───────────────────────────────────────
class AmsSearchableDropdown extends StatefulWidget {
  final List<String> items;
  final String? initialValue;
  final String? placeholder;
  final void Function(String?)? onChanged;
  final bool readOnly;
  final String? errorText;
  final bool isValid;

  const AmsSearchableDropdown({
    super.key,
    required this.items,
    this.initialValue,
    this.placeholder,
    this.onChanged,
    this.readOnly = false,
    this.errorText,
    this.isValid = false,
  });

  @override
  State<AmsSearchableDropdown> createState() => _AmsSearchableDropdownState();
}

class _AmsSearchableDropdownState extends State<AmsSearchableDropdown> {
  late List<String> _filteredItems;
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _filteredItems = widget.items;
    _controller = TextEditingController(text: widget.initialValue ?? '');
    _focusNode = FocusNode();
  }

  @override
  void didUpdateWidget(AmsSearchableDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue) {
      _controller.text = widget.initialValue ?? '';
    }
    if (oldWidget.items != widget.items) {
      _filterItems(_controller.text);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _filterItems(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredItems = widget.items;
      } else {
        _filteredItems = widget.items
            .where((item) => item.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return TapRegion(
      onTapOutside: (event) {
        if (_isOpen) {
          setState(() => _isOpen = false);
          _focusNode.unfocus();
        }
      },
      child: Focus(
        onFocusChange: (hasFocus) {
          if (hasFocus && !widget.readOnly) {
            setState(() => _isOpen = true);
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _controller,
              focusNode: _focusNode,
              readOnly: widget.readOnly,
              onChanged: widget.readOnly ? null : _filterItems,
              style: bodyStyle(size: 13, color: AppColors.ink),
              decoration: InputDecoration(
                hintText: widget.placeholder,
                hintStyle: bodyStyle(size: 13, color: AppColors.ink4),
                errorText: widget.errorText,
                errorStyle: bodyStyle(size: 11, color: AppColors.red),
                filled: true,
                fillColor:
                    widget.readOnly ? const Color(0xFFF7F9FC) : Colors.white,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
                suffixIcon: Icon(
                  _isOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                  color: AppColors.ink3,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(5),
                  borderSide: BorderSide(
                    color: widget.isValid
                        ? AppColors.green
                        : const Color(0xFFD1D5DB),
                    width: 1.0,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(5),
                  borderSide: BorderSide(
                    color: widget.isValid ? AppColors.green : AppColors.tBlue,
                    width: 1.0,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(5),
                  borderSide:
                      const BorderSide(color: AppColors.red, width: 1.0),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(5),
                  borderSide:
                      const BorderSide(color: AppColors.red, width: 1.0),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(5),
                  borderSide:
                      const BorderSide(color: AppColors.border, width: 1.0),
                ),
              ),
            ),
            if (_isOpen && !widget.readOnly && _filteredItems.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = _filteredItems[index];
                      return InkWell(
                        onTap: () {
                          _controller.text = item;
                          setState(() => _isOpen = false);
                          widget.onChanged?.call(item);
                          _focusNode.unfocus();
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          child: Text(
                            item,
                            style: bodyStyle(size: 13, color: AppColors.ink),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── SKELETON / LOADING UI ───────────────────────────────────────
class AmsSkeleton extends StatefulWidget {
  final double width;
  final double height;
  final double radius;
  final EdgeInsets? margin;

  const AmsSkeleton({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.radius = 4,
    this.margin,
  });

  @override
  State<AmsSkeleton> createState() => _AmsSkeletonState();
}

class _AmsSkeletonState extends State<AmsSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _gradientPosition;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        duration: const Duration(milliseconds: 1500), vsync: this)
      ..repeat();
    _gradientPosition = Tween<double>(begin: -1.0, end: 2.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _gradientPosition,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          margin: widget.margin,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: const Alignment(-1.0, -0.3),
              end: const Alignment(1.0, 0.3),
              colors: const [
                Color(0xFFF1F5F9),
                Color(0xFFE2E8F0),
                Color(0xFFF1F5F9),
              ],
              stops: [
                _gradientPosition.value - 0.4,
                _gradientPosition.value,
                _gradientPosition.value + 0.4,
              ],
            ),
          ),
        );
      },
    );
  }
}

class AmsTableSkeleton extends StatelessWidget {
  final int rows;
  final List<double> columnFlex;
  final bool shrinkWrap;

  const AmsTableSkeleton({
    super.key,
    this.rows = 5,
    this.columnFlex = const [1.0, 3.0, 4.0, 2.0, 2.0, 1.5],
    this.shrinkWrap = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: shrinkWrap ? MainAxisSize.min : MainAxisSize.max,
      children: [
        // Header Skeleton
        Container(
          height: 48,
          decoration: const BoxDecoration(
            color: Color(0xFFE2E8F0),
            borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
          ),
        ),
        // Row Skeletons
        if (shrinkWrap)
          ...List.generate(rows, (i) => _buildRow())
        else
          Expanded(
            child: ListView.builder(
              itemCount: rows,
              physics:
                  const NeverScrollableScrollPhysics(), // Match table behavior
              itemBuilder: (context, index) => _buildRow(),
            ),
          ),
      ],
    );
  }

  Widget _buildRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Row(
        children: columnFlex
            .map((flex) => Expanded(
                  flex: (flex * 10).toInt(),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: AmsSkeleton(
                      height: 14,
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }
}

class AmsListSkeleton extends StatelessWidget {
  final int count;

  const AmsListSkeleton({super.key, this.count = 6});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: count,
      itemBuilder: (ctx, idx) => Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFF1F5F9)),
        ),
        child: Row(
          children: [
            const AmsSkeleton(width: 40, height: 40, radius: 20),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  AmsSkeleton(width: 120, height: 14),
                  SizedBox(height: 8),
                  AmsSkeleton(width: 200, height: 10),
                ],
              ),
            ),
            const SizedBox(width: 16),
            const AmsSkeleton(width: 60, height: 20, radius: 4),
          ],
        ),
      ),
    );
  }
}
