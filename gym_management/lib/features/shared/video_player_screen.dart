import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Full-screen video player that opens a video URL.
///
/// For YouTube links it extracts the video ID and launches the
/// YouTube app / browser.  For other URLs it launches the default
/// browser.  Meanwhile, a nice placeholder is shown in-app.
class VideoPlayerScreen extends StatefulWidget {
  final String videoUrl;
  final String title;

  const VideoPlayerScreen({
    super.key,
    required this.videoUrl,
    required this.title,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  bool _launched = false;

  @override
  void initState() {
    super.initState();
    _launchVideo();
  }

  Future<void> _launchVideo() async {
    final uri = Uri.tryParse(widget.videoUrl);
    if (uri == null) return;

    try {
      // Try launching in external app first (YouTube app, etc.)
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (mounted) setState(() => _launched = launched);
    } catch (_) {
      // Fallback to in-app browser
      try {
        await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
        if (mounted) setState(() => _launched = true);
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isYouTube =
        widget.videoUrl.contains('youtube.com') ||
        widget.videoUrl.contains('youtu.be');

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          widget.title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Video icon
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isYouTube
                    ? Icons.ondemand_video_rounded
                    : Icons.play_circle_outline_rounded,
                color: Colors.red,
                size: 56,
              ),
            ),
            const SizedBox(height: 24),

            Text(
              _launched ? 'Video opened in player' : 'Opening video...',
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                widget.videoUrl,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 12,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 32),

            // Replay / re-open button
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.replay_rounded, size: 20),
              label: const Text(
                'Open Again',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              onPressed: _launchVideo,
            ),
          ],
        ),
      ),
    );
  }
}
