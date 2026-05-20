import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF1E3A8A);
  static const Color secondary = Color(0xFF1D4ED8);
  static const Color background = Color(0xFFf1f5f9);
  static const Color text = Color(0xFF0F172A);
  static const Color red = Color(0xFFDC2626);

}

class AppTextStyles {
  static const TextStyle titleBoldBlack = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: Colors.black,
  );

  static TextStyle subTitleGrey = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.normal,
    color: Colors.grey[700],
  );

  static const TextStyle titleBoldWhite = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  static const TextStyle subTitleWhite= TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: Colors.white,
  );

  static const TextStyle subTitleWhiteBold= TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  static const TextStyle drawerExpansionTitle= TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: Colors.white,
  );

  static const TextStyle drawerExpansionSubTitle= TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.normal,
    color: Colors.white,
  );

  static const TextStyle drawerItemTitle= TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: Colors.white,
  );

}