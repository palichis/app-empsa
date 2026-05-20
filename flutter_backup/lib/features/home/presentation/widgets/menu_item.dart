import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
class MenuItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isExpanded;
  final bool isSelected;
  final VoidCallback? onTap;

  const MenuItem({required this.icon, required this.text, required this.isExpanded,    this.isSelected = false,
    this.onTap,});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: isExpanded ? 160 : 40,
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.only(top: 10,bottom: 10),
        margin: EdgeInsets.only(left: 5,right: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.secondary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            SizedBox(width: 5,),
            Icon(icon, color: Colors.white),
            if (isExpanded)
              SizedBox(width: 10),
            if (isExpanded)
              Expanded(
                  child: Text(text,
                style: AppTextStyles.drawerItemTitle,
                overflow: TextOverflow.ellipsis,
              )),
          ],
        ),
      ),
    );
  }
}