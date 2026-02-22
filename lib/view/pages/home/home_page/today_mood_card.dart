import 'package:flutter/material.dart';
import 'package:mindisle_client/data/preference/const.dart';

class TodayMoodCard extends StatefulWidget {
  const TodayMoodCard({super.key});

  @override
  State<TodayMoodCard> createState() => _TodayMoodCardState();
}

class _TodayMoodCardState extends State<TodayMoodCard>
    with WidgetsBindingObserver {
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
  bool _isLockedForToday = false;

  bool get _showLowMoodDetails => _isLowMood(_selectedMoodIndex);
  bool get _showBodyFeelings =>
      _showLowMoodDetails && _selectedEvents.contains(_sideEffectTag);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _restoreTodayMoodEntry();
    _syncLockStateWithToday();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _noteController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncLockStateWithToday();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final descriptionTextStyle = theme.textTheme.bodySmall?.copyWith(
      color: colorScheme.onSurface.withValues(alpha: 0.72),
    );
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: BorderSide(
        color: colorScheme.primary,
        width: 0.9,
      ),
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
          children: _buildCardChildren(
            theme: theme,
            colorScheme: colorScheme,
            descriptionTextStyle: descriptionTextStyle,
            inputBorder: inputBorder,
          ),
        ),
      ),
    );
  }

  List<Widget> _buildCardChildren({
    required ThemeData theme,
    required ColorScheme colorScheme,
    required TextStyle? descriptionTextStyle,
    required OutlineInputBorder inputBorder,
  }) {
    final children = <Widget>[
      Text('心情日记', style: theme.textTheme.titleMedium),
      const SizedBox(height: 10),
      _buildMoodRow(),
    ];

    if (_showLowMoodDetails) {
      children.addAll(_buildLowMoodDetails(descriptionTextStyle));
    }

    if (_showBodyFeelings) {
      children.addAll(_buildBodyFeelingDetails(descriptionTextStyle));
    }

    children.addAll(<Widget>[
      const SizedBox(height: 8),
      _buildNoteField(
        descriptionTextStyle: descriptionTextStyle,
        colorScheme: colorScheme,
        inputBorder: inputBorder,
      ),
    ]);

    if (!_isLockedForToday) {
      children.addAll(<Widget>[
        const SizedBox(height: 14),
        _buildSubmitButton(
          descriptionTextStyle: descriptionTextStyle,
          colorScheme: colorScheme,
        ),
      ]);
    }

    return children;
  }

  Widget _buildMoodRow() {
    return Row(
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
              onPressed: () =>
                  _onMoodPressed(index: index, isSelected: selected),
            ),
          ),
        );
      }),
    );
  }

  List<Widget> _buildLowMoodDetails(TextStyle? descriptionTextStyle) {
    return <Widget>[
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
        enabled: !_isLockedForToday,
        onSelect: _onEventTagSelected,
      ),
    ];
  }

  List<Widget> _buildBodyFeelingDetails(TextStyle? descriptionTextStyle) {
    return <Widget>[
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
            onSelected: (value) => _onBodyTagSelected(
              label: tag.label,
              selected: value,
            ),
          );
        }).toList(growable: false),
      ),
    ];
  }

  Widget _buildNoteField({
    required TextStyle? descriptionTextStyle,
    required ColorScheme colorScheme,
    required OutlineInputBorder inputBorder,
  }) {
    return TextField(
      controller: _noteController,
      readOnly: _isLockedForToday,
      textInputAction: TextInputAction.newline,
      style: descriptionTextStyle,
      decoration: InputDecoration(
        hintText: '想多说一点吗？',
        hintStyle: descriptionTextStyle,
        fillColor: colorScheme.surface,
        border: inputBorder,
        enabledBorder: inputBorder,
        focusedBorder: inputBorder,
      ),
    );
  }

  Widget _buildSubmitButton({
    required TextStyle? descriptionTextStyle,
    required ColorScheme colorScheme,
  }) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          side: BorderSide(color: colorScheme.primary),
          textStyle: descriptionTextStyle,
        ),
        onPressed: _submitTodayMoodEntry,
        child: const Text('轻轻记下今天'),
      ),
    );
  }

  void _onMoodPressed({required int index, required bool isSelected}) {
    if (_isLockedForToday) return;
    setState(() {
      final nextIndex = isSelected ? null : index;
      _selectedMoodIndex = nextIndex;
      if (!_isLowMood(nextIndex)) {
        _selectedEvents.clear();
        _selectedBody.clear();
      }
    });
  }

  void _onEventTagSelected(String tag) {
    if (_isLockedForToday) return;
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
  }

  void _onBodyTagSelected({required String label, required bool selected}) {
    if (_isLockedForToday) return;
    setState(() {
      if (selected) {
        _selectedBody.add(label);
      } else {
        _selectedBody.remove(label);
      }
    });
  }

  bool _isLowMood(int? index) {
    if (index == null) return false;
    return index >= _lowMoodStartIndex;
  }

  void _restoreTodayMoodEntry() {
    final raw = AppPrefs.todayMoodEntry.value;
    if (raw.isEmpty) return;

    final savedDayKey = _toIntOrNull(raw['dayKey']);
    final todayKey = _toDayKey(DateTime.now());
    if (savedDayKey != todayKey) {
      AppPrefs.todayMoodEntry.value = <String, dynamic>{};
      return;
    }

    _selectedMoodIndex = _toIntOrNull(raw['moodIndex']);
    _selectedEvents
      ..clear()
      ..addAll(_toStringSet(raw['events']));
    _selectedBody
      ..clear()
      ..addAll(_toStringSet(raw['body']));
    _noteController.text = _toString(raw['note']);

    if (!_isLowMood(_selectedMoodIndex)) {
      _selectedEvents.clear();
      _selectedBody.clear();
    } else if (!_selectedEvents.contains(_sideEffectTag)) {
      _selectedBody.clear();
    }

    _isLockedForToday = true;
  }

  Future<void> _submitTodayMoodEntry() async {
    await AppPrefs.todayMoodEntry.set(<String, dynamic>{
      'dayKey': _toDayKey(DateTime.now()),
      'moodIndex': _selectedMoodIndex,
      'events': _selectedEvents.toList(growable: false),
      'body': _selectedBody.toList(growable: false),
      'note': _noteController.text.trim(),
    });

    if (!mounted) return;
    setState(() {
      _isLockedForToday = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已轻轻记下今天。')),
    );
  }

  void _syncLockStateWithToday() {
    if (!_isLockedForToday) return;
    final savedDayKey = _toIntOrNull(AppPrefs.todayMoodEntry.value['dayKey']);
    if (savedDayKey == _toDayKey(DateTime.now())) return;

    AppPrefs.todayMoodEntry.value = <String, dynamic>{};
    if (!mounted) return;
    setState(() {
      _isLockedForToday = false;
      _selectedMoodIndex = null;
      _selectedEvents.clear();
      _selectedBody.clear();
      _noteController.clear();
    });
  }

  int _toDayKey(DateTime dateTime) {
    return dateTime.year * 10000 + dateTime.month * 100 + dateTime.day;
  }

  int? _toIntOrNull(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  String _toString(Object? value) {
    if (value is String) return value;
    return '';
  }

  Set<String> _toStringSet(Object? value) {
    if (value is List) {
      return value.map((item) => item.toString()).toSet();
    }
    return <String>{};
  }
}

class _FilterChipGrid extends StatelessWidget {
  const _FilterChipGrid({
    required this.labels,
    required this.selectedValues,
    required this.onSelect,
    this.enabled = true,
    this.labelStyle,
  });

  final List<String> labels;
  final Set<String> selectedValues;
  final ValueChanged<String> onSelect;
  final bool enabled;
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
          onSelected: (_) {
            if (!enabled) return;
            onSelect(label);
          },
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
    this.textStyle,
  });

  final String title;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final defaultStyle = theme.textTheme.bodySmall?.copyWith(
      color: colorScheme.onSurface.withValues(alpha: 0.72),
    );
    final style = textStyle ?? defaultStyle;
    return Text(title, style: style);
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
