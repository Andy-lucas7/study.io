import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const background = Color.fromARGB(255, 9, 17, 24);
  static const tile = Color.fromARGB(255, 20, 26, 32);
  static const inputBackground = Color.fromARGB(255, 6, 24, 34);
  static const moodBackground = Color.fromARGB(255, 16, 21, 25);
  static const text = Colors.white;
  static const hintText = Colors.white;
  static const border = Color.fromARGB(255, 81, 145, 194);
  static const splashBackground = Colors.black;
}

class AppFonts {
  final TextStyle montserratTitle = GoogleFonts.montserrat(
    color: AppColors.text,
    fontSize: 24,
    fontWeight: FontWeight.w500,
  );
  final TextStyle roboto = GoogleFonts.roboto(
    color: AppColors.text,
    fontSize: 16,
    fontWeight: FontWeight.w500,
  );
  final TextStyle pacifico = GoogleFonts.pacifico(
    color: AppColors.text,
    fontSize: 16,
    fontWeight: FontWeight.w500,
  );
}