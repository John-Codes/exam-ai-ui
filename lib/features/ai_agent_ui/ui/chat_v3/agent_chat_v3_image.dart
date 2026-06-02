import 'dart:convert';
import 'package:flutter/material.dart';

class AgentChatV3Image extends StatelessWidget {
  final String data;
  final double height;
  final VoidCallback? onClear;

  const AgentChatV3Image({
    super.key,
    required this.data,
    this.height = 190,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) => Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(
              base64Decode(data),
              width: double.infinity,
              height: height,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _Broken(height: height),
            ),
          ),
          if (onClear != null)
            Positioned(
              top: 4,
              right: 4,
              child: IconButton.filledTonal(
                tooltip: 'Clear image',
                icon: const Icon(Icons.close, size: 18),
                onPressed: onClear,
              ),
            ),
        ],
      );
}

class _Broken extends StatelessWidget {
  final double height;
  const _Broken({required this.height});

  @override
  Widget build(BuildContext context) => Container(
        height: height,
        color: Colors.black26,
        alignment: Alignment.center,
        child: const Icon(Icons.image_not_supported_outlined),
      );
}
