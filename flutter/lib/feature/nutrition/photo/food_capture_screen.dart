import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/model/food_photo_analysis_models.dart';
import 'food_camera_gateway.dart';
import 'food_photo_preprocessor.dart';

enum FoodCapturePurpose {
  primaryMealOrLabel,
  requestedSideOrCloseUp,
}

final class FoodCaptureScreen extends StatefulWidget {
  final FoodCameraGateway gateway;
  final FoodPhotoPreprocessor preprocessor;
  final FoodCapturePurpose capturePurpose;

  const FoodCaptureScreen({
    required this.gateway,
    required this.preprocessor,
    required this.capturePurpose,
    super.key,
  });

  @override
  State<FoodCaptureScreen> createState() => _FoodCaptureScreenState();
}

final class _FoodCaptureScreenState extends State<FoodCaptureScreen>
    with WidgetsBindingObserver {
  static const _navy = Color(0xFF14213D);
  static const _orange = Color(0xFFF97316);
  static const _lightGray = Color(0xFFF3F4F6);

  bool _initializing = true;
  bool _ready = false;
  bool _capturing = false;
  bool _permissionDenied = false;
  String? _recaptureMessage;
  int _lifecycleGeneration = 0;

  bool get _isRequestedSecondImage =>
      widget.capturePurpose == FoodCapturePurpose.requestedSideOrCloseUp;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_initializeCamera());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        unawaited(_initializeCamera());
        return;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        unawaited(_suspendCamera());
        return;
    }
  }

  Future<void> _initializeCamera() async {
    final generation = ++_lifecycleGeneration;
    if (mounted) {
      setState(() {
        _initializing = true;
        _ready = false;
        _permissionDenied = false;
      });
    }
    try {
      await widget.gateway.initialize();
      if (!mounted || generation != _lifecycleGeneration) {
        return;
      }
      setState(() {
        _initializing = false;
        _ready = true;
      });
    } on FoodCameraException catch (error) {
      if (!mounted || generation != _lifecycleGeneration) return;
      setState(() {
        _initializing = false;
        _ready = false;
        _permissionDenied = error.failure == FoodCameraFailure.permissionDenied;
      });
    } catch (_) {
      if (!mounted || generation != _lifecycleGeneration) return;
      setState(() {
        _initializing = false;
        _ready = false;
        _capturing = false;
      });
    }
  }

  Future<void> _suspendCamera() async {
    _lifecycleGeneration++;
    if (mounted) {
      setState(() {
        _initializing = false;
        _ready = false;
        _capturing = false;
      });
    }
    await widget.gateway.dispose();
  }

  Future<void> _capture() async {
    if (!_ready || _capturing) return;
    final generation = _lifecycleGeneration;
    setState(() {
      _capturing = true;
      _recaptureMessage = null;
    });

    var didPop = false;
    try {
      final sourceBytes = await widget.gateway.takePicture();
      if (!mounted || generation != _lifecycleGeneration) return;
      final result = await widget.preprocessor.prepare(sourceBytes);
      if (!mounted || generation != _lifecycleGeneration) return;
      if (result.accepted) {
        _lifecycleGeneration++;
        didPop = true;
        setState(() {
          _capturing = false;
        });
        Navigator.of(context).pop<PreparedUpload>(result.upload);
        return;
      }
      setState(() {
        _recaptureMessage = _messageForIssues(result.issues);
      });
    } on FoodCameraException catch (error) {
      if (!mounted || generation != _lifecycleGeneration) return;
      setState(() {
        _recaptureMessage = error.failure == FoodCameraFailure.permissionDenied
            ? 'Ứng dụng cần quyền camera để chụp món ăn hoặc nhãn dinh dưỡng.'
            : 'Không thể chụp ảnh lúc này. Hãy thử chụp lại.';
      });
    } catch (_) {
      if (!mounted || generation != _lifecycleGeneration) return;
      setState(() {
        _recaptureMessage = 'Không thể chụp ảnh lúc này. Hãy thử chụp lại.';
      });
    } finally {
      if (!didPop && mounted && generation == _lifecycleGeneration) {
        setState(() {
          _capturing = false;
        });
      }
    }
  }

  String _messageForIssues(Set<PhotoQualityIssue> issues) {
    if (issues.contains(PhotoQualityIssue.tooSmall)) {
      return 'Ảnh quá nhỏ. Hãy đưa camera gần hơn và chụp lại.';
    }
    if (issues.contains(PhotoQualityIssue.tooDark)) {
      return 'Ảnh quá tối. Hãy tăng ánh sáng và chụp lại.';
    }
    if (issues.contains(PhotoQualityIssue.tooBlurry)) {
      return 'Ảnh bị mờ. Hãy giữ máy ổn định và chụp lại.';
    }
    if (issues.contains(PhotoQualityIssue.majorOcclusion)) {
      return 'Khung hình bị che khuất. Hãy đặt toàn bộ món ăn hoặc nhãn vào khung.';
    }
    return 'Ảnh chưa đủ rõ để phân tích. Hãy chụp lại.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _navy,
        elevation: 0,
        leading: IconButton(
          key: const Key('close-food-camera'),
          tooltip: 'Đóng',
          onPressed: _close,
          icon: const Icon(Icons.close),
        ),
        title: Text(
          _isRequestedSecondImage ? 'Chụp ảnh bổ sung' : 'Chụp món ăn',
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _isRequestedSecondImage
                    ? 'Chụp góc bên hoặc cận cảnh theo yêu cầu'
                    : 'Đặt toàn bộ đĩa hoặc nhãn trong khung',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: _navy,
                      fontWeight: FontWeight.w700,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Expanded(child: _buildCameraArea()),
              if (_recaptureMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _lightGray,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _recaptureMessage!,
                    style: const TextStyle(
                      color: _navy,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              FilledButton.icon(
                key: const Key('capture-food-photo'),
                onPressed: _ready && !_capturing ? _capture : null,
                style: FilledButton.styleFrom(
                  backgroundColor: _orange,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: _capturing
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.camera_alt_outlined),
                label: Text(
                  _capturing
                      ? 'Đang xử lý...'
                      : _recaptureMessage != null
                          ? 'Chụp lại'
                          : 'Chụp ảnh',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _close() {
    _lifecycleGeneration++;
    _capturing = false;
    Navigator.of(context).pop();
  }

  Widget _buildCameraArea() {
    if (_initializing) {
      return const Center(child: CircularProgressIndicator(color: _orange));
    }
    if (!_ready) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.no_photography_outlined, size: 48, color: _navy),
            const SizedBox(height: 12),
            Text(
              _permissionDenied
                  ? 'Hãy cấp quyền camera để chụp món ăn hoặc nhãn dinh dưỡng.'
                  : 'Không thể khởi động camera. Hãy thử lại.',
              style: const TextStyle(color: _navy),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _initializeCamera,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: ColoredBox(
        color: Colors.black,
        child: widget.gateway.buildPreview(),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _lifecycleGeneration++;
    unawaited(widget.gateway.dispose());
    super.dispose();
  }
}
