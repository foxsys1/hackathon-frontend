import 'package:flutter/material.dart';
import 'package:kos_gdgoc/core/theme/app_theme.dart';

class StepProgressBar extends StatelessWidget {
  const StepProgressBar({
    super.key,
    required this.currentStep,
    this.totalSteps = 3,
  });

  final int currentStep;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: List.generate(totalSteps, (i) {
                final isActive = i < currentStep;
                final isCurrent = i == currentStep - 1;
                return Expanded(
                  child: Container(
                    margin: EdgeInsets.only(right: i < totalSteps - 1 ? 8 : 0),
                    height: 6,
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppColors.primary
                          : isCurrent
                              ? AppColors.primaryLight
                              : AppColors.border.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '$currentStep/$totalSteps',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
