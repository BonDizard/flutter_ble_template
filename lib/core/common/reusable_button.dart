import 'package:flutter/material.dart';

import '../constants/color_constant.dart';

class ReusableButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String buttonText;
  const ReusableButton(
      {super.key, required this.onPressed, required this.buttonText});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return Container(
      width: width * 0.5,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(
          Radius.circular(15),
        ),
        color: ColorConstants.darkColor,
      ),
      child: ElevatedButton(
        style: const ButtonStyle(
          backgroundColor: WidgetStateColor.transparent,
        ),
        onPressed: onPressed,
        child: Text(
          buttonText,
          style: const TextStyle(
            fontFamily: 'Alatsi',
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
