import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';
import '../services/user_service.dart';
import '../services/api_service.dart';
import 'profile_popup.dart';

// ─── TEXT STYLES ─────────────────────────────────────────────
TextStyle monoStyle({
  double size = 12,
  FontWeight weight = FontWeight.w500,
  Color color = AppColors.ink2,
}) =>
    GoogleFonts.robotoMono(
        fontSize: size, fontWeight: weight, color: color);

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
          style: monoStyle(size: fontSize, weight: FontWeight.w700, color: color)),
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
      label: 'AUTO',
      color: AppColors.amber,
      background: AppColors.amberLt);

  factory AmsPill.locked() => const AmsPill(
      label: 'LOCKED',
      color: AppColors.ink3,
      background: AppColors.grayLt);

  factory AmsPill.optional() => const AmsPill(
      label: 'OPTIONAL',
      color: AppColors.green,
      background: AppColors.greenLt);

  factory AmsPill.required_() => const AmsPill(
      label: 'REQUIRED',
      color: AppColors.red,
      background: AppColors.redLt);

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

  const AmsButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AmsButtonVariant.primary,
    this.large = false,
    this.small = false,
    this.icon,
  });

  @override
  State<AmsButton> createState() => _AmsButtonState();
}

class _AmsButtonState extends State<AmsButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    late final Color bg;
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

    final double vPad = widget.small ? 6 : widget.large ? 10 : 8;
    final double hPad = widget.small ? 12 : widget.large ? 24 : 16;
    final double fSize = widget.small ? 11 : widget.large ? 14 : 13;
    final double radius = 4; // Sharp but soft corners like Zoho

    return MouseRegion(
      cursor: widget.onPressed != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
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
                          size: fSize,
                          weight: FontWeight.w700,
                          color: fg)),
                  if (widget.variant == AmsButtonVariant.primary && !widget.small) ...[
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
      decoration: decoration ?? BoxDecoration(
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
              decoration: const BoxDecoration(
                color: AppColors.cardHead,
                border: Border(
                    bottom: BorderSide(color: AppColors.border)),
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
Widget sectionTitle(String title, {Color color = AppColors.ink2, double size = 12}) {
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
              style: bodyStyle(
                  size: 11, color: hintColor ?? AppColors.ink3),
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
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      initialValue: controller == null ? initialValue : null,
      readOnly: readOnly,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      obscureText: obscureText,
      onChanged: onChanged,
      onFieldSubmitted: onFieldSubmitted,
      style: bodyStyle(
          size: 13,
          color: readOnly ? AppColors.ink3 : AppColors.ink),
      decoration: InputDecoration(
        hintText: placeholder,
        hintStyle:
            bodyStyle(size: 13, color: AppColors.ink4),
        errorText: errorText,
        errorStyle: bodyStyle(size: 11, color: AppColors.red),
        filled: true,
        fillColor: readOnly
            ? const Color(0xFFF7F9FC)
            : Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
        prefixIcon: icon != null
            ? Icon(icon, size: 18, color: AppColors.ink3)
            : null,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide: BorderSide(
              color: borderColor ?? (isValid ? AppColors.green : (readOnly ? AppColors.border : const Color(0xFFD1D5DB))),
              width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide:
              BorderSide(color: isValid ? AppColors.green : AppColors.tBlue, width: 1.0),
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
          borderSide:
              const BorderSide(color: AppColors.border, width: 1.0),
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
          ? Text(placeholder!, style: bodyStyle(size: 13, color: AppColors.ink4))
          : null,
      onChanged: onChanged,
      style: bodyStyle(size: 13, color: AppColors.ink),
      decoration: InputDecoration(
        errorText: errorText,
        errorStyle: bodyStyle(size: 11, color: AppColors.red),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide:
              BorderSide(color: isValid ? AppColors.green : const Color(0xFFD1D5DB), width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide:
              BorderSide(color: isValid ? AppColors.green : AppColors.tBlue, width: 1.0),
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
              value: e,
              child: Text(e, style: bodyStyle(size: 13))))
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
              return Container(
                  width: 24, height: 2, color: lineColor);
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
                    color: (nonTranMode ? AppColors.nTealLt : AppColors.tBlueLt),
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
                          size: 9,
                          weight: FontWeight.w700,
                          color: dotFg),
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
    final accent = brandColor ??
        (nonTranMode ? AppColors.nTeal : AppColors.tBlue);

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
        border:
            Border(bottom: BorderSide(color: AppColors.border)),
        boxShadow: [
          BoxShadow(
              color: Color(0x0F000000),
              blurRadius: 8,
              offset: Offset(0, 1))
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
                      style: bodyStyle(
                          size: 14,
                          weight: FontWeight.w700)),
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
                        style: bodyStyle(
                            size: 11,
                            weight: FontWeight.w600)),
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

// ─── IDENTITY HEADER ─────────────────────────────────────────
class AmsIdentityHeader extends StatelessWidget {
  final Widget icon;
  final String title;
  final String subtitle;
  final List<Widget> badges;
  final Color accentColor;
  final Color accentLt;
  final Color accentMd;
  final VoidCallback onBack;

  const AmsIdentityHeader({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.badges,
    required this.accentColor,
    required this.accentLt,
    required this.accentMd,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border, width: 1),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: icon,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title,
                    style: bodyStyle(
                        size: 18,
                        weight: FontWeight.w800,
                        color: accentColor)),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: bodyStyle(size: 12, color: AppColors.ink2)),
                ],
                if (badges.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Wrap(spacing: 6, runSpacing: 6, children: badges),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: onBack,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.redLt,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.red.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.arrow_back_ios_new_rounded, size: 13, color: AppColors.red),
                    const SizedBox(width: 6),
                    Text('Back', style: bodyStyle(size: 13, weight: FontWeight.w700, color: AppColors.red)),
                  ],
                ),
              ),
            ),
          ),
        ],
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
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 30,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.85),
              border: Border(
                top: BorderSide(
                    color: borderColor.withOpacity(0.2), width: 1.5),
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
          ),
        ),
      ),
    );
  }
}

// ─── SNACKBAR TOAST ───────────────────────────────────────────
void showAmsToast(BuildContext context, String icon, String msg,
    {String type = 's'}) {
  final Color bg = type == 's'
      ? AppColors.tBlue
      : type == 'w'
          ? AppColors.amber
          : AppColors.tBlue;
  final size = MediaQuery.of(context).size;
  // Calculate bottom margin to place it near the top (e.g. 80px from top)
  // We subtract 80px + approximate height of snackbar (50px) = 130px
  final double bottomMargin = size.height > 150 ? size.height - 130 : 20;
  // Width around 320px
  final double leftMargin = size.width > 360 ? size.width - 340 : 20;

  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 15)),
        const SizedBox(width: 9),
        Expanded(
            child: Text(msg,
                style: bodyStyle(
                    size: 13,
                    weight: FontWeight.w700,
                    color: Colors.white))),
      ],
    ),
    backgroundColor: bg,
    behavior: SnackBarBehavior.floating,
    margin: EdgeInsets.only(
      bottom: bottomMargin,
      left: leftMargin,
      right: 20,
    ),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
    duration: const Duration(milliseconds: 3500),
  ));
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
          margin: EdgeInsets.symmetric(
              vertical: 2, horizontal: isCollapsed ? 6 : 12),
          padding: EdgeInsets.symmetric(
              horizontal: isCollapsed ? 0 : 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.tBlueLt.withValues(alpha: 0.5)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: isSelected
                ? const Border(
                    left: BorderSide(color: AppColors.tBlue, width: 3))
                : null,
          ),
          child: isCollapsed
              ? Center(
                  child: Icon(icon,
                      size: 20,
                      color: color ?? (isSelected ? AppColors.tBlue : AppColors.ink2)),
                )
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const NeverScrollableScrollPhysics(),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Icon(icon,
                          size: 20,
                          color: color ?? (isSelected ? AppColors.tBlue : AppColors.ink2)),
                      const SizedBox(width: 14),
                      SizedBox(
                        width: 200,
                        child: Text(
                          label,
                          style: bodyStyle(
                            size: 14,
                            weight: isSelected ? FontWeight.w700 : FontWeight.w600,
                            color: color ?? (isSelected ? AppColors.tBlue : AppColors.ink),
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
              left: isCollapsed ? 6 : 36, right: 6, top: 2, bottom: 2),
          padding: EdgeInsets.symmetric(
              horizontal: isCollapsed ? 8 : 16, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.tBlueLt.withValues(alpha: 0.5) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border(
              left: BorderSide(
                color: isSelected ? AppColors.tBlue : AppColors.border2,
                width: 2,
              ),
            ),
          ),
          child: isCollapsed
              ? Center(
                  child: Icon(icon ?? Icons.adjust_rounded,
                      size: 16,
                      color: isSelected ? AppColors.tBlue : AppColors.ink3),
                )
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const NeverScrollableScrollPhysics(),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Icon(icon ?? Icons.circle,
                          size: 6,
                          color: isSelected ? AppColors.tBlue : AppColors.ink3),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 185,
                        child: Text(
                          label,
                          style: bodyStyle(
                            size: 12,
                            weight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? AppColors.tBlue : AppColors.ink2,
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
    if (['USR-CRT', 'USR-ROLE', 'ROLE-CRT', 'MOD-CRT', 'MENU-CRT', 'PGM-CRT'].contains(widget.selectedProg)) {
      openMenu = 'masters';
    } else if (['GL-CAT', 'GL-MST', 'GL-CUR', 'GL-BRN', 'GL-SEG', 'GL-ATT'].contains(widget.selectedProg)) {
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
      width: widget.isCollapsed ? 70 : 260,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: Column(
        children: [
          // 🔹 TOP BAR
          Container(
            height: 70,
            padding: EdgeInsets.symmetric(horizontal: widget.isCollapsed ? 0 : 20),
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: widget.isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
              children: [
                if (!widget.isCollapsed) ...[
                  // Container(
                  //   padding: const EdgeInsets.all(6),
                  //   decoration: BoxDecoration(
                  //     color: AppColors.tBlue,
                  //     borderRadius: BorderRadius.circular(6),
                  //   ),
                  //   child: const Icon(Icons.shield_rounded, color: Colors.white, size: 20),
                  // ),
                  // const SizedBox(width: 10),
                  // Text(
                  //   'AMS',
                  //   style: bodyStyle(
                  //       size: 18,
                  //       weight: FontWeight.w900,
                  //       color: AppColors.ink),
                  // ),
                  const Spacer(),
                ],
                SizedBox(
                  width: 28,
                  height: 28,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: widget.onToggle,
                      child: Center(
                        child: Icon(
                          widget.isCollapsed ? Icons.menu_rounded : Icons.menu_open_rounded,
                          color: AppColors.ink2,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppColors.border2),
          const SizedBox(height: 16),

          // 🔹 MENU LIST
          Expanded(
            child: ListView(
              children: [
                if (!widget.isCollapsed) _sectionHeader('GENERAL'),

                // 🔹 Dashboard
                AmsSidebarItem(
                  label: widget.isCollapsed ? '' : 'Dashboard',
                  icon: Icons.dashboard_rounded,
                  isCollapsed: widget.isCollapsed,
                  isSelected: widget.currentScreen == 'list' && widget.selectedProg == null,
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
                  icon: openMenu == 'masters' ? Icons.folder_open_rounded : Icons.folder_shared_rounded,
                  isCollapsed: widget.isCollapsed,
                  isSelected: openMenu == 'masters' || ['USR-CRT', 'USR-ROLE', 'ROLE-CRT', 'MOD-CRT', 'MENU-CRT', 'PGM-CRT'].contains(widget.selectedProg) || widget.currentScreen == 'submenu_dashboard' && ['MASTERS', 'GL'].contains(widget.selectedProg),
                  onTap: () {
                    setState(() {
                      openMenu = openMenu == 'masters' ? '' : 'masters';
                    });
                    widget.onNavigate('submenu_dashboard', 'MASTERS');
                  },
                ),

                if (openMenu == 'masters') ...[
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
                    icon: Icons.app_registration_rounded,
                    isSelected: widget.selectedProg == 'PGM-CRT',
                    onTap: () => widget.onNavigate('nontran', 'PGM-CRT'),
                  ),
                ],

                const SizedBox(height: 16),

                // 🔹 GL MODULE
                AmsSidebarItem(
                  label: widget.isCollapsed ? '' : 'GL Module',
                  icon: openMenu == 'gl' ? Icons.account_balance_rounded : Icons.account_balance_outlined,
                  isCollapsed: widget.isCollapsed,
                  isSelected: openMenu == 'gl' || ['GL-CAT', 'GL-MST', 'GL-CUR', 'GL-BRN', 'GL-SEG', 'GL-ATT'].contains(widget.selectedProg),
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
                  isSelected: openMenu == 'config' || widget.selectedProg == 'AUTHCTL' || (widget.currentScreen == 'submenu_dashboard' && widget.selectedProg == 'CONFIG'),
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
                  isSelected: openMenu == 'auth' || widget.currentScreen == 'nontranauth' || (widget.currentScreen == 'submenu_dashboard' && widget.selectedProg == 'AUTH'),
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
        style: monoStyle(size: 10, weight: FontWeight.w800, color: AppColors.ink4),
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
          _buildTopBar(context),

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
        color: Colors.white,
        border: const Border(
          bottom: BorderSide(color: AppColors.border),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
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
                  Text("AMS",
                      style:
                          bodyStyle(size: 20, weight: FontWeight.w800)),
                  Text("Management System",
                      style: bodyStyle(
                          size: 10, color: AppColors.ink3)),
                ],
              ),
            ],
          ),

          const SizedBox(width: 30),

          /// 🔍 SEARCH
          _PremiumSearchBar(),

          const Spacer(),

          /// 🔹 ICONS
          _topIconBox(Icons.help_outline_rounded),
          const SizedBox(width: 8),
          _topIconBox(Icons.notifications_none_rounded),
          const SizedBox(width: 8),
          _topIconBox(Icons.settings_outlined),

          const SizedBox(width: 16),

          Container(height: 32, width: 1, color: AppColors.border),

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
            color: _hover ? AppColors.bg : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.apps_rounded,
              size: 22, color: AppColors.ink2),
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
// 🔹 SEARCH BAR
// ─────────────────────────────────────────────────────────────
class _PremiumSearchBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: const Row(
        children: [
          Icon(Icons.search, size: 18, color: AppColors.ink3),
          SizedBox(width: 8),
          Text("Search...",
              style: TextStyle(color: AppColors.ink3, fontSize: 13)),
        ],
      ),
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
          color: _hover ? AppColors.bg : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(widget.icon,
            size: 20, color: AppColors.ink2),
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

  const _PremiumProfileMenu({
    this.userName,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton(
      offset: const Offset(0, 45),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: AppColors.tBlue,
            child: Text(
              (userName ?? "U")[0].toUpperCase(),
              style: const TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(width: 8),
          Text(userName ?? "User",
              style: bodyStyle(size: 13, weight: FontWeight.w600)),
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
        style: bodyStyle(size: 12, weight: FontWeight.w700, color: Colors.white),
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
  final Widget Function(BuildContext context, List<T> currentItems) builder;

  const AmsPaginatedView({
    super.key,
    required this.items,
    this.itemsPerPage = 10,
    this.shrinkWrap = false,
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
    if (oldWidget.items != widget.items) {
      _currentPage = 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalItems = widget.items.length;
    if (totalItems == 0) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('No records found', style: TextStyle(color: Color(0xFF64748B), fontSize: 15)),
        ),
      );
    }

    final totalPages = (totalItems / widget.itemsPerPage).ceil();
    if (_currentPage > totalPages) _currentPage = totalPages;

    final startIndex = (_currentPage - 1) * widget.itemsPerPage;
    final endIndex = (startIndex + widget.itemsPerPage) > totalItems
        ? totalItems
        : (startIndex + widget.itemsPerPage);

    final currentItems = widget.items.sublist(startIndex, endIndex);

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
                Text('Showing ${startIndex + 1} to $endIndex of $totalItems entries',
                    style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: _currentPage > 1
                          ? () => setState(() => _currentPage--)
                          : null,
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: _currentPage > 1 ? const Color(0xFFE2E8F0) : Colors.transparent),
                        ),
                        child: Icon(Icons.chevron_left_rounded, 
                          color: _currentPage > 1 ? const Color(0xFF0F172A) : const Color(0xFFCBD5E1),
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text('Page $_currentPage of $totalPages',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
                    const SizedBox(width: 16),
                    InkWell(
                      onTap: _currentPage < totalPages
                          ? () => setState(() => _currentPage++)
                          : null,
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: _currentPage < totalPages ? const Color(0xFFE2E8F0) : Colors.transparent),
                        ),
                        child: Icon(Icons.chevron_right_rounded, 
                          color: _currentPage < totalPages ? const Color(0xFF0F172A) : const Color(0xFFCBD5E1),
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

