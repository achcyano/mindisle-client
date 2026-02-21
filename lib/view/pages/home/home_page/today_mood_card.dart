import 'package:flutter/material.dart';

class TodayMoodCard extends StatefulWidget {
  const TodayMoodCard({super.key});

  @override
  State<TodayMoodCard> createState() => _TodayMoodCardState();
}

class _TodayMoodCardState extends State<TodayMoodCard> {
  static const int _lowMoodStartIndex = 3;
  static const String _sideEffectTag = '副作用';

  static const List<_MoodOption> _moods = <_MoodOption>[
    _MoodOption(emoji: '😀'),
    _MoodOption(emoji: '🙂'),
    _MoodOption(emoji: '😐'),
    _MoodOption(emoji: '😟'),
    _MoodOption(emoji: '😢'),
  ];

  static const List<String> _eventTags = <String>[
    '工作压力',
    '家庭冲突',
    '睡眠不好',
    '食欲增加',
    '吃了药',
    '副作用',
    '运动了',
    '暴食冲动',
    '什么都没发生',
  ];

  static const List<_BodyTag> _bodyTags = <_BodyTag>[
    _BodyTag(icon: Icons.air, label: '胸闷'),
    _BodyTag(icon: Icons.psychology_alt_outlined, label: '头痛'),
    _BodyTag(icon: Icons.local_hospital_outlined, label: '便秘'),
    _BodyTag(icon: Icons.favorite_border, label: '心悸'),
    _BodyTag(icon: Icons.bedtime_outlined, label: '嗜睡'),
    _BodyTag(icon: Icons.bolt_outlined, label: '焦躁'),
    _BodyTag(icon: Icons.battery_0_bar_outlined, label: '无力'),
  ];

  int? _selectedMoodIndex;
  final Set<String> _selectedEvents = <String>{};
  final Set<String> _selectedBody = <String>{};
  final TextEditingController _noteController = TextEditingController();

  bool get _showLowMoodDetails => _isLowMood(_selectedMoodIndex);
  bool get _showBodyFeelings =>
      _showLowMoodDetails && _selectedEvents.contains(_sideEffectTag);

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final descriptionTextStyle = theme.textTheme.bodySmall?.copyWith(
      color: colorScheme.onSurface.withValues(alpha: 0.72),
    );

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('心情日记', style: theme.textTheme.titleMedium),
            const SizedBox(height: 10),
            Row(
              children: List<Widget>.generate(_moods.length, (index) {
                final option = _moods[index];
                final selected = _selectedMoodIndex == index;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: index == 0 ? 0 : 3,
                      right: index == _moods.length - 1 ? 0 : 3,
                    ),
                    child: _MoodButton(
                      option: option,
                      selected: selected,
                      onPressed: () {
                        setState(() {
                          final nextIndex = selected ? null : index;
                          _selectedMoodIndex = nextIndex;
                          if (!_isLowMood(nextIndex)) {
                            _selectedEvents.clear();
                            _selectedBody.clear();
                          }
                        });
                      },
                    ),
                  ),
                );
              }),
            ),
            if (_showLowMoodDetails) ...[
              const SizedBox(height: 14),
              _SectionTitle(
                title: '今天发生了什么？',
                textStyle: descriptionTextStyle,
              ),
              const SizedBox(height: 8),
              _FilterChipGrid(
                labels: _eventTags,
                selectedValues: _selectedEvents,
                labelStyle: descriptionTextStyle,
                onSelect: (tag) {
                  setState(() {
                    if (_selectedEvents.contains(tag)) {
                      _selectedEvents.remove(tag);
                      if (tag == _sideEffectTag) {
                        _selectedBody.clear();
                      }
                      return;
                    }
                    if (_selectedEvents.length >= 3) {
                      return;
                    }
                    _selectedEvents.add(tag);
                  });
                },
              ),
            ],
            if (_showBodyFeelings) ...[
              const SizedBox(height: 14),
              _SectionTitle(
                title: '身体感觉如何？',
                textStyle: descriptionTextStyle,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 8,
                children: _bodyTags.map((tag) {
                  final selected = _selectedBody.contains(tag.label);
                  return FilterChip(
                    selected: selected,
                    showCheckmark: false,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                    avatar: Icon(tag.icon, size: 16),
                    label: Text(tag.label, style: descriptionTextStyle),
                    onSelected: (value) {
                      setState(() {
                        if (value) {
                          _selectedBody.add(tag.label);
                        } else {
                          _selectedBody.remove(tag.label);
                        }
                      });
                    },
                  );
                }).toList(growable: false),
              ),
            ],
            const SizedBox(height: 8),
            TextField(
              controller: _noteController,
              textInputAction: TextInputAction.newline,
              style: descriptionTextStyle,
              decoration: InputDecoration(
                hintText: '想多说一点吗？',
                hintStyle: descriptionTextStyle,
                fillColor: colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(
                    width: 0.9,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(
                    color: colorScheme.primary,
                    width: 0.9,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: colorScheme.primary,
                  side: BorderSide(color: colorScheme.primary),
                  textStyle: descriptionTextStyle,
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('已轻轻记下今天。')),
                  );
                },
                child: const Text('轻轻记下今天'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isLowMood(int? index) {
    if (index == null) return false;
    return index >= _lowMoodStartIndex;
  }
}

class _FilterChipGrid extends StatelessWidget {
  const _FilterChipGrid({
    required this.labels,
    required this.selectedValues,
    required this.onSelect,
    this.labelStyle,
  });

  final List<String> labels;
  final Set<String> selectedValues;
  final ValueChanged<String> onSelect;
  final TextStyle? labelStyle;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 8,
      children: labels.map((label) {
        final selected = selectedValues.contains(label);
        return FilterChip(
          selected: selected,
          showCheckmark: false,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
          label: Text(label, style: labelStyle),
          onSelected: (_) => onSelect(label),
        );
      }).toList(growable: false),
    );
  }
}

class _MoodButton extends StatelessWidget {
  const _MoodButton({
    required this.option,
    required this.selected,
    required this.onPressed,
  });

  final _MoodOption option;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final backgroundColor = selected
        ? colorScheme.primaryContainer
        : colorScheme.primaryContainer.withValues(alpha: 0.75);

    return Center(
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: backgroundColor,
              shape: BoxShape.circle,
              border: selected
                  ? Border.all(
                      color: colorScheme.primary.withValues(alpha: 0.45),
                    )
                  : null,
            ),
            child: Text(option.emoji, style: const TextStyle(fontSize: 18)),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    this.subtitle,
    this.textStyle,
  });

  final String title;
  final String? subtitle;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final defaultStyle = theme.textTheme.bodySmall?.copyWith(
      color: colorScheme.onSurface.withValues(alpha: 0.72),
    );
    final style = textStyle ?? defaultStyle;
    final hasSubtitle = subtitle != null && subtitle!.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: style),
        if (hasSubtitle) Text(subtitle!, style: style),
      ],
    );
  }
}

class _MoodOption {
  const _MoodOption({
    required this.emoji,
  });

  final String emoji;
}

class _BodyTag {
  const _BodyTag({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;
}
