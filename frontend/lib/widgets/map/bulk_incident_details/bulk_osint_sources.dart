import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class BulkOsintSources extends StatelessWidget {
  final List<String> urls;
  final double? itemFontSize;
  final double? iconSize;
  final EdgeInsets? padding;
  final double? marginBottom;

  const BulkOsintSources({
    Key? key,
    required this.urls,
    this.itemFontSize,
    this.iconSize,
    this.padding,
    this.marginBottom,
  }) : super(key: key);

  Future<void> _launch(BuildContext context, String url) async {
    try {
      final uri = Uri.parse(url);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open link'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final fontSize = itemFontSize ?? 12.0;
    final iSize = iconSize ?? 16.0;
    final pad =
        padding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 10);
    final mb = marginBottom ?? 8.0;

    return Column(
      children: urls.map((url) {
        return GestureDetector(
          onTap: () => _launch(context, url),
          child: Container(
            margin: EdgeInsets.only(bottom: mb),
            padding: pad,
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED).withOpacity(0.07),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFF7C3AED).withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.link, size: iSize, color: const Color(0xFF7C3AED)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    url,
                    style: TextStyle(
                      fontSize: fontSize,
                      color: const Color(0xFF7C3AED),
                      decoration: TextDecoration.underline,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
