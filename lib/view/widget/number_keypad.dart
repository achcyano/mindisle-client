import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class NumberKeypad extends StatelessWidget {
  const NumberKeypad({
    required this.onDigitPressed,
    required this.onBackspacePressed,
    this.enabled = true,
    this.height = 210,
    super.key,
  });

  final ValueChanged<String> onDigitPressed;
  final VoidCallback onBackspacePressed;
  final bool enabled;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        child: Column(
          children: [
            _buildRow(context, const ['1', '2', '3']),
            const SizedBox(height: 10),
            _buildRow(context, const ['4', '5', '6']),
            const SizedBox(height: 10),
            _buildRow(context, const ['7', '8', '9']),
            const SizedBox(height: 10),
            _buildBottomRow(context),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(BuildContext context, List<String> digits) {
    return Expanded(
      child: Row(
        children: [
          for (final digit in digits)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _DigitKey(
                  digit: digit,
                  letters: _lettersForDigit(digit),
                  enabled: enabled,
                  onTap: () {
                    HapticFeedback.vibrate();
                    onDigitPressed(digit);
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomRow(BuildContext context) {
    return Expanded(
      child: Row(
        children: [
          const Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 6),
              child: SizedBox.shrink(),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: _DigitKey(
                digit: '0',
                letters: _lettersForDigit('0'),
                enabled: enabled,
                onTap: () {
                  HapticFeedback.vibrate();
                  onDigitPressed('0');
                },
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: _BackspaceKey(
                enabled: enabled,
                onTap: () {
                  HapticFeedback.vibrate();
                  onBackspacePressed();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _lettersForDigit(String digit) {
    return switch (digit) {
      '2' => 'ABC',
      '3' => 'DEF',
      '4' => 'GHI',
      '5' => 'JKL',
      '6' => 'MNO',
      '7' => 'PQRS',
      '8' => 'TUV',
      '9' => 'WXYZ',
      '0' => '+',
      _ => '',
    };
  }
}

class _DigitKey extends StatelessWidget {
  const _DigitKey({
    required this.digit,
    required this.letters,
    required this.enabled,
    required this.onTap,
  });

  final String digit;
  final String letters;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    const keyRadius = 8.0;
    final keyFill = colorScheme.surfaceContainerHighest.withValues(alpha: 0.55);
    final baseDigitStyle =
        textTheme.titleLarge ?? const TextStyle(fontSize: 23, fontWeight: FontWeight.w300);
    final baseLettersStyle = textTheme.titleMedium ??
        const TextStyle(fontSize: 16, fontWeight: FontWeight.w300, letterSpacing: 0.6);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(keyRadius),
        splashFactory: InkRipple.splashFactory,
        radius: 52,
        splashColor: colorScheme.onSurface.withValues(alpha: 0.16),
        highlightColor: colorScheme.onSurface.withValues(alpha: 0.06),
        onTap: enabled ? onTap : null,
        child: Ink(
          decoration: BoxDecoration(
            color: keyFill,
            borderRadius: BorderRadius.circular(keyRadius),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  SizedBox(
                    width: 28,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        digit,
                        style: baseDigitStyle.copyWith(
                          color: enabled
                              ? colorScheme.onSurface
                              : colorScheme.onSurface.withValues(alpha: 0.38),
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: 44,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        letters,
                        style: baseLettersStyle.copyWith(
                          color: enabled
                              ? colorScheme.onSurface.withValues(alpha: 0.55)
                              : colorScheme.onSurface.withValues(alpha: 0.30),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BackspaceKey extends StatelessWidget {
  const _BackspaceKey({
    required this.enabled,
    required this.onTap,
  });

  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    const keyRadius = 8.0;
    final keyFill = colorScheme.surfaceContainerHighest.withValues(alpha: 0.55);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(keyRadius),
        splashFactory: InkRipple.splashFactory,
        radius: 52,
        splashColor: colorScheme.onSurface.withValues(alpha: 0.16),
        highlightColor: colorScheme.onSurface.withValues(alpha: 0.06),
        onTap: enabled ? onTap : null,
        child: Ink(
          decoration: BoxDecoration(
            color: keyFill,
            borderRadius: BorderRadius.circular(keyRadius),
          ),
          child: Center(
            child: Icon(
              Icons.backspace_outlined,
              size: 20,
              color: enabled
                  ? colorScheme.onSurface
                  : colorScheme.onSurface.withValues(alpha: 0.38),
            ),
          ),
        ),
      ),
    );
  }
}
