import 'package:flutter/material.dart';

void showVoiceError(BuildContext context, Object error) {
  final message = error.toString().replaceFirst('Exception: ', '');
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );
}
