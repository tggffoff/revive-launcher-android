import 'package:flutter/material.dart';

/// Chapter 1 season 1 up to season 41 are bundled with the app.
int? seasonFromVersion(String version) {
  final match = RegExp(r'(?<!\d)(\d{1,2})\.\d').firstMatch(version);
  if (match == null) return null;
  final season = int.parse(match.group(1)!);
  return season >= 1 && season <= 41 ? season : null;
}

/// Remote thumbnail when there is one, else the bundled season artwork.
class BuildArtwork extends StatelessWidget {
  const BuildArtwork({
    super.key,
    required this.version,
    required this.width,
    required this.height,
    this.imageUrl = '',
  });

  final String version;
  final double width;
  final double height;
  final String imageUrl;

  Widget _fallback() {
    final season = seasonFromVersion(version);
    const icon = Center(
      child: Icon(
        Icons.sports_esports_outlined,
        size: 40,
        color: Color(0x55FFFFFF),
      ),
    );
    if (season == null) return icon;
    return Image.asset(
      'assets/seasons/Season$season.jpg',
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => icon,
    );
  }

  @override
  Widget build(BuildContext context) => Container(
        width: width,
        height: height,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              Color(0xFF6126A8),
              Color(0xFF183B70),
              Color(0xFF101827),
            ],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            if (imageUrl.isEmpty)
              _fallback()
            else
              Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _fallback(),
              ),
            if (version.isNotEmpty) ...<Widget>[
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.center,
                    end: Alignment.bottomCenter,
                    colors: <Color>[
                      Colors.transparent,
                      Colors.black.withValues(alpha: .8),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 8,
                right: 5,
                bottom: 7,
                child: Text(
                  version,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      );
}
