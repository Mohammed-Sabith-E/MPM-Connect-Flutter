import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

enum StatusType {
  paid,
  partial,
  credit,
  overdue,
  draft,
  custom,
}

class StatusChip extends StatelessWidget {
  final String label;
  final StatusType type;

  const StatusChip({
    super.key,
    required this.label,
    required this.type,
  });

  factory StatusChip.fromPaymentStatus(String status) {
    switch (status.toLowerCase().trim()) {
      case 'paid':
        return const StatusChip(label: 'PAID', type: StatusType.paid);
      case 'partial':
        return const StatusChip(label: 'PARTIAL', type: StatusType.partial);
      case 'overdue':
        return const StatusChip(label: 'OVERDUE', type: StatusType.overdue);
      case 'credit':
      default:
        return const StatusChip(label: 'CREDIT', type: StatusType.credit);
    }
  }

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color textColor;
    Color borderColor;

    switch (type) {
      case StatusType.paid:
        bg = AppColors.emeraldLight;
        textColor = AppColors.emeraldSuccess;
        borderColor = const Color.fromRGBO(16, 185, 129, 0.2);
        break;
      case StatusType.overdue:
        bg = AppColors.crimsonLight;
        textColor = AppColors.crimsonDanger;
        borderColor = const Color.fromRGBO(239, 68, 68, 0.2);
        break;
      case StatusType.partial:
        bg = AppColors.amberLight;
        textColor = AppColors.amberPrimary;
        borderColor = const Color.fromRGBO(245, 158, 11, 0.25);
        break;
      case StatusType.credit:
        bg = AppColors.surfaceContainer;
        textColor = AppColors.navyPrimary;
        borderColor = AppColors.hairlineBorder;
        break;
      case StatusType.draft:
      default:
        bg = AppColors.navySoftTint;
        textColor = AppColors.slateNeutral;
        borderColor = AppColors.hairlineBorder;
        break;
    }

    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(9999),
        border: Border.all(color: borderColor, width: 1),
      ),
      alignment: Alignment.center,
      child: Text(
        label.toUpperCase(),
        style: AppTypography.labelSm(color: textColor),
      ),
    );
  }
}
