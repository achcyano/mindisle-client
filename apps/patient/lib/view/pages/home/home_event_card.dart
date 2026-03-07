import 'package:flutter/material.dart';
import 'package:patient/features/event/domain/entities/event_entities.dart';
import 'package:patient/view/pages/home/card_home.dart';

class HomeEventCard extends StatelessWidget {
  const HomeEventCard({
    super.key,
    required this.item,
    this.onTap,
  });

  final UserEventItem item;
  final VoidCallback? onTap;

  static bool isActionable(UserEventItem item) {
    return switch (item.eventType) {
      UserEventType.bindDoctor || UserEventType.unknown => false,
      _ => true,
    };
  }

  @override
  Widget build(BuildContext context) {
    final config = _HomeEventCardConfig.from(item);
    final actionable = isActionable(item);

    return HomeActionCard(
      icon: config.icon,
      title: config.title,
      subtitle: config.subtitle,
      onTap: actionable ? onTap : null,
      showChevron: actionable,
    );
  }
}

final class _HomeEventCardConfig {
  const _HomeEventCardConfig({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  factory _HomeEventCardConfig.from(UserEventItem item) {
    return switch (item.eventType) {
      UserEventType.openScale => _HomeEventCardConfig(
        icon: Icons.assignment_outlined,
        title: '量表待完成',
        subtitle:
            item.scaleName?.trim().isNotEmpty == true
            ? item.scaleName!.trim()
            : '有待完成的量表',
      ),
      UserEventType.continueScaleSession => _HomeEventCardConfig(
        icon: Icons.playlist_add_check_circle_outlined,
        title: '继续填写量表',
        subtitle: _buildContinueScaleText(item),
      ),
      UserEventType.bindDoctor => _HomeEventCardConfig(
        icon: Icons.link_outlined,
        title: '绑定医生',
        subtitle: '绑定医生后可使用完整服务',
      ),
      UserEventType.importMedicationPlan => _HomeEventCardConfig(
        icon: Icons.medical_services_outlined,
        title: '补充用药计划',
        subtitle: '当前暂无进行中的用药计划',
      ),
      UserEventType.updateBasicProfile => _HomeEventCardConfig(
        icon: Icons.person_outline,
        title: '更新个人资料',
        subtitle: '建议定期更新个人资料',
      ),
      UserEventType.unknown => _HomeEventCardConfig(
        icon: Icons.notifications_outlined,
        title: '待办提醒',
        subtitle: '有新的待办事项',
      ),
    };
  }

  static String _buildContinueScaleText(UserEventItem item) {
    final scaleName = item.scaleName?.trim() ?? '';
    final progress = item.progress;
    final progressLabel = progress == null ? null : '进度 $progress%';

    if (scaleName.isNotEmpty && progressLabel != null) {
      return '$scaleName，$progressLabel';
    }
    if (scaleName.isNotEmpty) return scaleName;
    if (progressLabel != null) return progressLabel;
    return '有未提交的量表';
  }
}
