import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.showText = true, this.symbolSize = 44, this.textStyle});

  final bool showText;
  final double symbolSize;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final icon = Container(
      width: symbolSize,
      height: symbolSize,
      decoration: BoxDecoration(
        color: AppColors.bluePrimary,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Icon(
          Icons.favorite,
          color: AppColors.orangeAction,
          size: symbolSize * 0.58,
        ),
      ),
    );

    if (!showText) {
      return icon;
    }

    final theme = Theme.of(context);
    final style = textStyle ??
        theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              color: AppColors.darkText,
            );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        icon,
        const SizedBox(width: 10),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(text: 'MANOS\n', style: style),
              TextSpan(
                text: 'SOLIDARIAS',
                style: style?.copyWith(color: AppColors.orangeAction),
              ),
            ],
          ),
          textAlign: TextAlign.start,
        ),
      ],
    );
  }
}
