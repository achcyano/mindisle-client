import 'package:flutter/material.dart';
import 'package:mindisle_client/features/scale/presentation/assessment/scale_answer_draft.dart';
import 'package:mindisle_client/view/pages/scale/widgets/question_inputs/question_input_factory.dart';

class TextInput extends StatefulWidget {
  const TextInput({
    required this.draft,
    required this.enabled,
    required this.onDraftChanged,
    super.key,
  });

  final ScaleAnswerDraft? draft;
  final bool enabled;
  final ScaleAnswerDraftChanged onDraftChanged;

  @override
  State<TextInput> createState() => _TextInputState();
}

class _TextInputState extends State<TextInput> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.draft?.textValue ?? '');
    _focusNode = FocusNode()..addListener(_onFocusChanged);
  }

  @override
  void didUpdateWidget(covariant TextInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    final incoming = widget.draft?.textValue ?? '';
    if (_focusNode.hasFocus) {
      return;
    }
    if (incoming == _controller.text) {
      return;
    }
    _controller.value = TextEditingValue(
      text: incoming,
      selection: TextSelection.collapsed(offset: incoming.length),
    );
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_onFocusChanged)
      ..dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus) return;
    widget.onDraftChanged(
      ScaleAnswerDraft.text(textValue: _controller.text),
      true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      enabled: widget.enabled,
      minLines: 3,
      maxLines: 6,
      textInputAction: TextInputAction.done,
      onSubmitted: (_) {
        widget.onDraftChanged(
          ScaleAnswerDraft.text(textValue: _controller.text),
          true,
        );
      },
      onChanged: (value) {
        widget.onDraftChanged(
          ScaleAnswerDraft.text(textValue: value),
          false,
        );
      },
      decoration: const InputDecoration(
        hintText: '请输入内容',
        border: OutlineInputBorder(),
        alignLabelWithHint: true,
      ),
    );
  }
}
