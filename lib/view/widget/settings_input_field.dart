import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SettingsInputField extends StatefulWidget {
  const SettingsInputField({
    required this.value,
    required this.onChanged,
    this.onCommit,
    this.hintText = '',
    this.enabled = true,
    this.keyboardType,
    this.inputFormatters,
    this.textInputAction = TextInputAction.done,
    this.maxLength,
    this.obscureText = false,
    this.padding = const EdgeInsets.fromLTRB(16, 0, 16, 12),
    super.key,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final Future<void> Function()? onCommit;
  final String hintText;
  final bool enabled;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputAction textInputAction;
  final int? maxLength;
  final bool obscureText;
  final EdgeInsetsGeometry padding;

  @override
  State<SettingsInputField> createState() => _SettingsInputFieldState();
}

class _SettingsInputFieldState extends State<SettingsInputField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  bool _dirty = false;
  bool _isCommitting = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
    _focusNode = FocusNode()..addListener(_handleFocusChanged);
  }

  @override
  void didUpdateWidget(covariant SettingsInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_focusNode.hasFocus) return;
    if (_controller.text == widget.value) return;
    _controller.value = TextEditingValue(
      text: widget.value,
      selection: TextSelection.collapsed(offset: widget.value.length),
    );
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChanged);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _handleFocusChanged() {
    if (_focusNode.hasFocus) {
      _dirty = false;
      return;
    }
    if (!_dirty) return;
    unawaited(_commit());
  }

  Future<void> _commit() async {
    final onCommit = widget.onCommit;
    if (onCommit == null || _isCommitting) return;
    _isCommitting = true;
    try {
      await onCommit();
    } finally {
      _isCommitting = false;
      _dirty = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: widget.padding,
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        enabled: widget.enabled,
        keyboardType: widget.keyboardType,
        inputFormatters: widget.inputFormatters,
        textInputAction: widget.textInputAction,
        maxLength: widget.maxLength,
        obscureText: widget.obscureText,
        onChanged: (value) {
          _dirty = true;
          widget.onChanged(value);
        },
        onSubmitted: (_) {
          _focusNode.unfocus();
        },
        decoration: InputDecoration(
          hintText: widget.hintText,
          border: InputBorder.none,
          isDense: true,
          counterText: widget.maxLength == null ? null : '',
        ),
      ),
    );
  }
}
