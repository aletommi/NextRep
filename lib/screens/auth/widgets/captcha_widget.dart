import 'package:flutter/material.dart';

class CaptchaWidget extends StatefulWidget {
  final ValueChanged<bool> onVerify;

  const CaptchaWidget({super.key, required this.onVerify});

  @override
  State<CaptchaWidget> createState() => _CaptchaWidgetState();
}

class _CaptchaWidgetState extends State<CaptchaWidget> {
  bool _isChecked = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9),
        border: Border.all(color: const Color(0xFFD3D3D3)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Checkbox(
            value: _isChecked,
            onChanged: (val) {
              setState(() {
                _isChecked = val ?? false;
              });
              widget.onVerify(_isChecked);
            },
            activeColor: Colors.blue, // Classic styling
          ),
          const SizedBox(width: 8),
          const Text(
            "I'm not a robot",
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          // Mock Recaptcha logo
          Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.security, color: Colors.blueGrey, size: 24),
              Text(
                "reCAPTCHA",
                style: TextStyle(fontSize: 8, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
