import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// URL içeren metinleri otomatik olarak tespit edip tıklanabilir linke dönüştüren bileşen.
class LinkableText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;

  const LinkableText({
    super.key,
    required this.text,
    this.style,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    // http://, https:// veya www. ile başlayan linkleri yakalayan RegExp
    final RegExp urlRegex = RegExp(
      r'((https?:\/\/|www\.)[^\s]+)',
      caseSensitive: false,
    );

    final matches = urlRegex.allMatches(text);
    if (matches.isEmpty) {
      return Text(
        text,
        style: style,
        maxLines: maxLines,
        overflow: overflow,
      );
    }

    final defaultStyle = DefaultTextStyle.of(context).style;
    final effectiveStyle = defaultStyle.merge(style);
    final linkColor = Theme.of(context).primaryColor;

    final List<InlineSpan> spans = [];
    int lastIndex = 0;

    for (final match in matches) {
      // Link öncesi düz metin varsa ekle
      if (match.start > lastIndex) {
        spans.add(
          TextSpan(
            text: text.substring(lastIndex, match.start),
          ),
        );
      }

      final url = match.group(0)!;

      spans.add(
        TextSpan(
          text: url,
          style: TextStyle(
            color: linkColor,
            decoration: TextDecoration.underline,
            fontWeight: FontWeight.w600,
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () async {
              final cleanUrl = url.startsWith('http') ? url : 'https://$url';
              final uri = Uri.parse(cleanUrl);
              try {
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              } catch (_) {
                // Hata durumunda sessizce yoksay
              }
            },
        ),
      );

      lastIndex = match.end;
    }

    // Kalan düz metin varsa ekle
    if (lastIndex < text.length) {
      spans.add(
        TextSpan(
          text: text.substring(lastIndex),
        ),
      );
    }

    return RichText(
      text: TextSpan(
        style: effectiveStyle,
        children: spans,
      ),
      maxLines: maxLines,
      overflow: overflow ?? TextOverflow.clip,
    );
  }
}
