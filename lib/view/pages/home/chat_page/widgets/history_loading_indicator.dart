import 'package:flutter/material.dart';
import 'package:progress_indicator_m3e/progress_indicator_m3e.dart';

class HistoryLoadingIndicator extends StatelessWidget {
  const HistoryLoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 6),
      child: Center(
        child: SizedBox(
          width: 18,
          height: 18,
          child: const FittedBox(child: CircularProgressIndicatorM3E()),
        ),
      ),
    );
  }
}
