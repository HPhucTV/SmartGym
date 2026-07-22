import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

import '../../../core/model/food_photo_analysis_models.dart';

enum PhotoQualityIssue {
  tooSmall,
  tooDark,
  tooBlurry,
  majorOcclusion,
}

final class PhotoPreparationResult {
  final PreparedUpload? upload;
  final Set<PhotoQualityIssue> issues;

  const PhotoPreparationResult({
    required this.upload,
    required this.issues,
  });

  bool get accepted => upload != null && issues.isEmpty;
}

abstract interface class FoodPhotoPreprocessor {
  Future<PhotoPreparationResult> prepare(Uint8List sourceBytes);
}

/// Deterministic, local image checks before a photo crosses the network boundary.
///
/// These thresholds are app heuristics, not guarantees about food recognition.
final class DeterministicFoodPhotoPreprocessor
    implements FoodPhotoPreprocessor {
  static const int minimumDimensionPixels = 640;
  static const int maximumLongEdgePixels = 1600;
  // The decoder can coexist briefly with a resized/oriented copy and a fresh
  // RGB copy. These bounds keep the worst-case 16-bit RGBA path around a
  // low-memory Android device's practical heap budget before JPEG encoding.
  static const int maximumSourceBytes = 15 * 1024 * 1024;
  static const int maximumDecodedDimensionPixels = 4096;
  static const int maximumDecodedPixels = 8 * 1000 * 1000;
  static const int maximumDecodedPixelBytes = 32 * 1024 * 1024;
  static const int analysisLongEdgePixels = 256;
  static const double minimumMeanLuminance = 35;
  static const double minimumLaplacianVariance = 18;
  static const int clippedDarkLuminance = 6;
  static const int clippedLightLuminance = 249;
  static const double minimumClippedComponentRatio = 0.12;
  static const double minimumClippedBoundingBoxOccupancy = 0.20;
  static const int jpegQuality = 85;
  static const List<int> jpegFallbackQualities = [75, 65, 55];
  static const List<int> jpegFallbackLongEdges = [1440, 1280, 1024];

  @override
  Future<PhotoPreparationResult> prepare(Uint8List sourceBytes) async {
    if (sourceBytes.isEmpty || sourceBytes.length > maximumSourceBytes) {
      return PhotoPreparationResult(
        upload: null,
        issues: const {PhotoQualityIssue.tooSmall},
      );
    }

    try {
      final prepared = await Isolate.run(
        () => _preparePixels(Uint8List.fromList(sourceBytes)),
      );
      if (prepared.issues.isNotEmpty || prepared.jpegBytes == null) {
        return PhotoPreparationResult(
          upload: null,
          issues: Set.unmodifiable(prepared.issues),
        );
      }
      return PhotoPreparationResult(
        upload: PreparedUpload(
          bytes: prepared.jpegBytes!,
          mimeType: 'image/jpeg',
          filename: 'food-analysis.jpg',
        ),
        issues: const {},
      );
    } catch (_) {
      // Malformed or unsupported camera bytes are a local recapture condition.
      return PhotoPreparationResult(
        upload: null,
        issues: const {PhotoQualityIssue.tooSmall},
      );
    }
  }
}

final class _PreparedPixels {
  final Uint8List? jpegBytes;
  final Set<PhotoQualityIssue> issues;

  const _PreparedPixels({
    required this.jpegBytes,
    required this.issues,
  });
}

_PreparedPixels _preparePixels(Uint8List sourceBytes) {
  final decoded = _decodeBounded(sourceBytes);
  if (decoded == null) {
    return const _PreparedPixels(
      jpegBytes: null,
      issues: {PhotoQualityIssue.tooSmall},
    );
  }

  // Downscale before orientation baking and channel normalization so no
  // second full-resolution copy is needed for ordinary camera captures.
  final resizedDecoded = _resizeToLongEdge(
    decoded,
    DeterministicFoodPhotoPreprocessor.maximumLongEdgePixels,
  );
  final oriented = img.bakeOrientation(resizedDecoded);
  final issues = <PhotoQualityIssue>{};
  if (oriented.width <
          DeterministicFoodPhotoPreprocessor.minimumDimensionPixels ||
      oriented.height <
          DeterministicFoodPhotoPreprocessor.minimumDimensionPixels) {
    issues.add(PhotoQualityIssue.tooSmall);
  }

  // image 4.8 decodes PNG 16-bit samples as uint16. Normalize through the
  // supported uint8 RGBA representation before alpha compositing.
  final normalized = oriented.convert(
    format: img.Format.uint8,
    numChannels: 4,
    noAnimation: true,
  );
  final pixels = _freshPixelImage(normalized);
  final analysis = _analysisImage(pixels);
  final luminance = _luminanceValues(analysis);
  final mean =
      luminance.reduce((left, right) => left + right) / luminance.length;
  if (mean < DeterministicFoodPhotoPreprocessor.minimumMeanLuminance) {
    issues.add(PhotoQualityIssue.tooDark);
  }
  if (_laplacianVariance(luminance, analysis.width, analysis.height) <
      DeterministicFoodPhotoPreprocessor.minimumLaplacianVariance) {
    issues.add(PhotoQualityIssue.tooBlurry);
  }
  if (_hasMajorClippedRegion(luminance, analysis.width, analysis.height)) {
    issues.add(PhotoQualityIssue.majorOcclusion);
  }
  if (issues.isNotEmpty) {
    return _PreparedPixels(jpegBytes: null, issues: issues);
  }

  final resized = _resizeForUpload(pixels);
  final encoded = _encodeUnderUploadLimit(resized);
  if (encoded == null) {
    return const _PreparedPixels(
      jpegBytes: null,
      issues: {PhotoQualityIssue.tooSmall},
    );
  }
  return _PreparedPixels(jpegBytes: encoded, issues: const {});
}

Uint8List? _encodeUnderUploadLimit(img.Image source) {
  final first = _encodeJpeg(
    source,
    DeterministicFoodPhotoPreprocessor.jpegQuality,
  );
  if (first.length <= PreparedUpload.maxBytes) return first;

  for (final longEdge
      in DeterministicFoodPhotoPreprocessor.jpegFallbackLongEdges) {
    final resized = _resizeToLongEdge(source, longEdge);
    for (final quality
        in DeterministicFoodPhotoPreprocessor.jpegFallbackQualities) {
      final encoded = _encodeJpeg(resized, quality);
      if (encoded.length <= PreparedUpload.maxBytes) return encoded;
    }
  }
  return null;
}

Uint8List _encodeJpeg(img.Image source, int quality) {
  return Uint8List.fromList(
    img.encodeJpg(
      source,
      quality: quality,
      chroma: img.JpegChroma.yuv420,
    ),
  );
}

img.Image _resizeToLongEdge(img.Image source, int longEdge) {
  final currentLongEdge = math.max(source.width, source.height);
  if (currentLongEdge <= longEdge) return source;
  final scale = longEdge / currentLongEdge;
  return img.copyResize(
    source,
    width: math.max(1, (source.width * scale).round()),
    height: math.max(1, (source.height * scale).round()),
    interpolation: img.Interpolation.linear,
  );
}

img.Image? _decodeBounded(Uint8List sourceBytes) {
  final decoder = _decoderForSupportedFormat(sourceBytes);
  if (decoder == null) return null;
  final info = decoder.startDecode(sourceBytes);
  if (info == null ||
      !_isSingleSupportedFrame(decoder, info) ||
      info.width <= 0 ||
      info.height <= 0 ||
      info.width >
          DeterministicFoodPhotoPreprocessor.maximumDecodedDimensionPixels ||
      info.height >
          DeterministicFoodPhotoPreprocessor.maximumDecodedDimensionPixels ||
      info.width * info.height >
          DeterministicFoodPhotoPreprocessor.maximumDecodedPixels ||
      info.width * info.height * _decodedBytesPerPixel(decoder) >
          DeterministicFoodPhotoPreprocessor.maximumDecodedPixelBytes) {
    return null;
  }
  return decoder.decodeFrame(0);
}

bool _isSingleSupportedFrame(img.Decoder decoder, img.DecodeInfo info) {
  if (decoder is img.WebPDecoder) {
    final webp = info as img.WebPInfo;
    // image 4.8 reports zero frames for valid static WebP bitstreams.
    return !webp.hasAnimation;
  }
  if (decoder is img.PngDecoder) {
    final png = info as img.PngInfo;
    return !png.isAnimated && png.numFrames == 1;
  }
  return info.numFrames == 1;
}

int _decodedBytesPerPixel(img.Decoder decoder) {
  if (decoder is! img.PngDecoder) return 4;
  final info = decoder.info;
  final channels = switch (info.colorType) {
    img.PngColorType.grayscale => 1,
    img.PngColorType.rgb => 3,
    img.PngColorType.indexed => 4,
    img.PngColorType.grayscaleAlpha => 2,
    img.PngColorType.rgba => 4,
    _ => 4,
  };
  final bytesPerChannel = info.bits > 8 ? 2 : 1;
  return channels * bytesPerChannel;
}

img.Decoder? _decoderForSupportedFormat(Uint8List bytes) {
  if (bytes.length >= 2 && bytes[0] == 0xff && bytes[1] == 0xd8) {
    return img.JpegDecoder();
  }
  const pngSignature = <int>[137, 80, 78, 71, 13, 10, 26, 10];
  if (bytes.length >= pngSignature.length && _startsWith(bytes, pngSignature)) {
    return img.PngDecoder();
  }
  if (bytes.length >= 12 &&
      bytes[0] == 0x52 &&
      bytes[1] == 0x49 &&
      bytes[2] == 0x46 &&
      bytes[3] == 0x46 &&
      bytes[8] == 0x57 &&
      bytes[9] == 0x45 &&
      bytes[10] == 0x42 &&
      bytes[11] == 0x50) {
    return img.WebPDecoder();
  }
  return null;
}

bool _startsWith(Uint8List bytes, List<int> signature) {
  for (var index = 0; index < signature.length; index++) {
    if (bytes[index] != signature[index]) return false;
  }
  return true;
}

img.Image _freshPixelImage(img.Image source) {
  final fresh = img.Image(
    width: source.width,
    height: source.height,
    numChannels: 3,
  );
  for (final pixel in source) {
    final alpha = pixel.aNormalized;
    fresh.setPixelRgb(
      pixel.x,
      pixel.y,
      (pixel.rNormalized * 255 * alpha) + (255 * (1 - alpha)),
      (pixel.gNormalized * 255 * alpha) + (255 * (1 - alpha)),
      (pixel.bNormalized * 255 * alpha) + (255 * (1 - alpha)),
    );
  }
  return fresh;
}

img.Image _analysisImage(img.Image source) {
  final longEdge = math.max(source.width, source.height);
  if (longEdge <= DeterministicFoodPhotoPreprocessor.analysisLongEdgePixels) {
    return source;
  }
  final scale =
      DeterministicFoodPhotoPreprocessor.analysisLongEdgePixels / longEdge;
  return img.copyResize(
    source,
    width: math.max(1, (source.width * scale).round()),
    height: math.max(1, (source.height * scale).round()),
    interpolation: img.Interpolation.average,
  );
}

img.Image _resizeForUpload(img.Image source) {
  final longEdge = math.max(source.width, source.height);
  if (longEdge <= DeterministicFoodPhotoPreprocessor.maximumLongEdgePixels) {
    return source;
  }
  final scale =
      DeterministicFoodPhotoPreprocessor.maximumLongEdgePixels / longEdge;
  return img.copyResize(
    source,
    width: math.max(1, (source.width * scale).round()),
    height: math.max(1, (source.height * scale).round()),
    interpolation: img.Interpolation.linear,
  );
}

List<double> _luminanceValues(img.Image image) {
  final values = List<double>.filled(image.width * image.height, 0);
  var index = 0;
  for (final pixel in image) {
    values[index++] =
        (0.2126 * pixel.r) + (0.7152 * pixel.g) + (0.0722 * pixel.b);
  }
  return values;
}

double _laplacianVariance(List<double> values, int width, int height) {
  if (width < 3 || height < 3) return 0;
  var sum = 0.0;
  var sumSquares = 0.0;
  var count = 0;
  for (var y = 1; y < height - 1; y++) {
    for (var x = 1; x < width - 1; x++) {
      final index = y * width + x;
      final laplacian = (4 * values[index]) -
          values[index - 1] -
          values[index + 1] -
          values[index - width] -
          values[index + width];
      sum += laplacian;
      sumSquares += laplacian * laplacian;
      count++;
    }
  }
  final mean = sum / count;
  return (sumSquares / count) - (mean * mean);
}

bool _hasMajorClippedRegion(List<double> values, int width, int height) {
  final dark = List<bool>.generate(
    values.length,
    (index) =>
        values[index] <=
        DeterministicFoodPhotoPreprocessor.clippedDarkLuminance,
    growable: false,
  );
  final light = List<bool>.generate(
    values.length,
    (index) =>
        values[index] >=
        DeterministicFoodPhotoPreprocessor.clippedLightLuminance,
    growable: false,
  );
  return _hasFramingComponent(dark, width, height) ||
      _hasFramingComponent(light, width, height);
}

bool _hasFramingComponent(List<bool> clipped, int width, int height) {
  final total = clipped.length;
  final visited = Uint8List(total);
  final queue = List<int>.filled(total, 0);
  final required =
      (total * DeterministicFoodPhotoPreprocessor.minimumClippedComponentRatio)
          .ceil();

  for (var start = 0; start < total; start++) {
    if (!clipped[start] || visited[start] != 0) continue;
    var head = 0;
    var tail = 0;
    var componentSize = 0;
    var minX = width;
    var minY = height;
    var maxX = -1;
    var maxY = -1;
    var borderCount = 0;
    queue[tail++] = start;
    visited[start] = 1;
    while (head < tail) {
      final index = queue[head++];
      componentSize++;
      final x = index % width;
      final y = index ~/ width;
      minX = math.min(minX, x);
      minY = math.min(minY, y);
      maxX = math.max(maxX, x);
      maxY = math.max(maxY, y);
      if (x == 0 || x == width - 1 || y == 0 || y == height - 1) {
        borderCount++;
      }
      if (x > 0) {
        tail = _enqueue(index - 1, clipped, visited, queue, tail);
      }
      if (x + 1 < width) {
        tail = _enqueue(index + 1, clipped, visited, queue, tail);
      }
      if (y > 0) {
        tail = _enqueue(index - width, clipped, visited, queue, tail);
      }
      if (y + 1 < height) {
        tail = _enqueue(index + width, clipped, visited, queue, tail);
      }
    }
    if (componentSize < required || borderCount == 0) continue;
    final componentRatio = componentSize / total;
    final componentWidthRatio = (maxX - minX + 1) / width;
    final componentHeightRatio = (maxY - minY + 1) / height;
    if (componentRatio > 0.75) continue;
    final touchesCorner =
        (minX == 0 || maxX == width - 1) && (minY == 0 || maxY == height - 1);
    final isBorderBand =
        componentWidthRatio >= 0.30 || componentHeightRatio >= 0.30;
    final boundingBoxArea = (maxX - minX + 1) * (maxY - minY + 1);
    final boundingBoxOccupancy = componentSize / boundingBoxArea;
    final denseSpanningObstruction = boundingBoxOccupancy >=
            DeterministicFoodPhotoPreprocessor
                .minimumClippedBoundingBoxOccupancy &&
        (touchesCorner || isBorderBand) &&
        (touchesCorner ||
            componentWidthRatio >= 0.85 ||
            componentHeightRatio >= 0.85);
    if (denseSpanningObstruction) return true;
  }
  return false;
}

int _enqueue(
  int index,
  List<bool> clipped,
  Uint8List visited,
  List<int> queue,
  int tail,
) {
  if (!clipped[index] || visited[index] != 0) return tail;
  visited[index] = 1;
  queue[tail] = index;
  return tail + 1;
}
