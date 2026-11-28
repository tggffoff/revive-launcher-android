import 'package:flutter/material.dart';

const reviveMagenta = Color(0xFFC43BFF);
const revivePurple = Color(0xFF9A4DFF);
const reviveBlue = Color(0xFF4B4DFF);
const reviveCyan = Color(0xFF22C8FF);
const reviveBackground = Color(0xFF080A12);
const revivePanel = Color(0xFF151827);
const reviveMuted = Color(0xFF929AAF);
const reviveLilac = Color(0xFFBCA0F1);

const reviveGradient = LinearGradient(
  colors: <Color>[reviveMagenta, revivePurple, reviveBlue],
);

ThemeData reviveTheme() => ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: reviveBackground,
      colorScheme: ColorScheme.fromSeed(
        seedColor: revivePurple,
        brightness: Brightness.dark,
        surface: revivePanel,
      ),
      useMaterial3: true,
    );

BoxDecoration revivePanelDecoration([double radius = 16]) => BoxDecoration(
      color: revivePanel,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: Colors.white10),
    );

/// Main call to action: gradient, heavy italic label.
class ReviveButton extends StatelessWidget {
  const ReviveButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.busy = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !busy;
    final radius = BorderRadius.circular(10);
    return Semantics(
      button: true,
      enabled: enabled,
      child: Opacity(
        opacity: onPressed == null && !busy ? .45 : 1,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: reviveGradient,
            borderRadius: radius,
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: revivePurple.withValues(alpha: .35),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: radius,
              onTap: enabled ? onPressed : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 15,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    if (busy)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    else if (icon != null)
                      Icon(icon, size: 20, color: Colors.white),
                    const SizedBox(width: 9),
                    Flexible(
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                          letterSpacing: .6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PageTitle extends StatelessWidget {
  const PageTitle({super.key, required this.section, required this.title});

  final String section;
  final String title;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'REVIVE / $section',
            style: const TextStyle(
              color: reviveLilac,
              fontSize: 10,
              letterSpacing: 2,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 16),
        ],
      );
}

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.4,
        ),
      );
}
