import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../theme/spacing.dart';
import '../theme/theme.dart';
import 'gym_card.dart';
import 'gym_button.dart';

class Exercise3DDialog extends StatefulWidget {
  final String animationId;
  final String exerciseName;
  final List<String> instructions;
  final VoidCallback onDismiss;

  const Exercise3DDialog({
    super.key,
    required this.animationId,
    required this.exerciseName,
    required this.instructions,
    required this.onDismiss,
  });

  static Future<void> show({
    required BuildContext context,
    required String animationId,
    required String exerciseName,
    required List<String> instructions,
  }) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Dismiss",
      barrierColor: Colors.black.withValues(alpha: 0.6),
      transitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Exercise3DDialog(
          animationId: animationId,
          exerciseName: exerciseName,
          instructions: instructions,
          onDismiss: () => Navigator.of(context).pop(),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
              .animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              ),
          child: child,
        );
      },
    );
  }

  @override
  State<Exercise3DDialog> createState() => _Exercise3DDialogState();
}

class _Exercise3DDialogState extends State<Exercise3DDialog> {
  static String? _cachedInlinedHtml;

  late final WebViewController _webViewController;
  bool _isLoading = true;
  bool _hasError = false;
  bool _isHtmlLoaded = false;
  bool _didStartLoading = false;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didStartLoading) return;
    _didStartLoading = true;
    _loadHtmlAsset(isDark: Theme.of(context).brightness == Brightness.dark);
  }

  void _initWebView() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..addJavaScriptChannel(
        'Exercise3D',
        onMessageReceived: (message) {
          debugPrint('Exercise 3D error: ${message.message}');
          if (mounted) {
            setState(() {
              _hasError = true;
              _isLoading = false;
            });
          }
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
              _injectExerciseId();
            }
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint("WebView error: ${error.description}");
            if (mounted) {
              setState(() {
                _hasError = true;
                _isLoading = false;
              });
            }
          },
        ),
      );
  }

  Future<void> _loadHtmlAsset({required bool isDark}) async {
    try {
      String html = _cachedInlinedHtml ?? "";
      if (html.isEmpty) {
        html = await rootBundle.loadString('assets/3d/model_viewer.html');
        final js = await rootBundle.loadString(
          'assets/3d/exercise_animations.js',
        );

        // Inline the JS content to avoid relative path errors in WebView across platforms
        html = html.replaceFirst(
          '<script src="exercise_animations.js" onerror="showError(\'Không thể nạp tệp exercise_animations.js\')"></script>',
          '<script>$js</script>',
        );
        _cachedInlinedHtml = html;
      }

      // Dynamically inject the theme state (isDarkTheme) on a local copy
      final localHtml = html.replaceFirst(
        '__IS_DARK_THEME__',
        isDark.toString(),
      );

      await _webViewController.loadHtmlString(localHtml);
      if (mounted) {
        setState(() {
          _isHtmlLoaded = true;
        });
      }
    } catch (e) {
      debugPrint("Error loading HTML or JS assets: $e");
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  void _injectExerciseId() {
    final animationId = jsonEncode(widget.animationId);
    _webViewController.runJavaScript(
      "if (window.initExercise) { window.initExercise($animationId); } "
      "else if (window.Exercise3D) { window.Exercise3D.postMessage('initExercise is unavailable'); }",
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final customColors = context.customColors;

    return Dialog(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 20.0,
        vertical: 40.0,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.exerciseName,
                        style: isDark
                            ? GymTypography.titleMedium.white.bold
                            : GymTypography.titleMedium.navy.bold,
                      ),
                      Text(
                        "MINH HỌA CHUYỂN ĐỘNG 3D",
                        style: GymTypography.labelSmall.orange.bold,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  color: isDark ? AppColors.white : AppColors.navy,
                  onPressed: widget.onDismiss,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: GymCard(
                variant: GymCardVariant.flat,
                backgroundColor: isDark
                    ? AppColors.darkSurface
                    : AppColors.surfaceGray,
                padding: EdgeInsets.zero,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _hasError
                      ? _buildFallbackUI(customColors.primaryText)
                      : Stack(
                          children: [
                            if (_isHtmlLoaded)
                              WebViewWidget(controller: _webViewController),
                            if (_isLoading)
                              const Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.energyOrange,
                                  ),
                                ),
                              ),
                          ],
                        ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Minh họa hỗ trợ nhận biết chuyển động; hãy ưu tiên hướng dẫn kỹ thuật và dừng tập nếu thấy đau.",
              style: GymTypography.bodySmall.muted,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              "Hướng dẫn thực hiện:",
              style: GymTypography.titleSmall.bold.copyWith(
                color: isDark ? AppColors.white : AppColors.navy,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.surfaceGray,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(12),
              child: Scrollbar(
                child: SingleChildScrollView(
                  child: Column(
                    children: List.generate(
                      widget.instructions.length,
                      (index) => Padding(
                        padding: const EdgeInsets.only(bottom: 6.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${index + 1}.",
                              style: GymTypography.bodyMedium.orange.bold,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                widget.instructions[index],
                                style: GymTypography.bodyMedium.copyWith(
                                  color: customColors.primaryText,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            GymButton.primary(text: "Đã hiểu", onPressed: widget.onDismiss),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackUI(Color textColor) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text("🏃‍♂️", style: TextStyle(fontSize: 48)),
          GymGap.md,
          Text(
            "Chưa có minh họa chuyển động phù hợp",
            style: GymTypography.titleMedium.bold.copyWith(color: textColor),
            textAlign: TextAlign.center,
          ),
          GymGap.xs,
          Text(
            "Vui lòng tham khảo hướng dẫn từng bước bên dưới.",
            style: GymTypography.bodySmall.muted,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
