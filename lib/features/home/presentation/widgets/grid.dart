import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/presentation/widgets/common_widgets.dart';
import '../../model/action_model.dart';

class ActionGrid extends StatelessWidget {
  final List<ActionItem> actions;

  const ActionGrid({
    required this.actions, super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: AppDimens.gridCrossAxisCount,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: AppDimens.gridSpacing,
      mainAxisSpacing: AppDimens.gridSpacing,
      childAspectRatio: AppDimens.gridAspectRatio,
      children: actions.map((action) {
        return ActionCard(
          icon: action.icon,
          title: action.title,
          color: action.color,
          onTap: action.onTap,
        );
      }).toList(),
    );
  }
}
