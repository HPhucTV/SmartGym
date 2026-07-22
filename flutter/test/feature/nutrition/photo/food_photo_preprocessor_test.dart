import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import 'package:gym_app/feature/nutrition/photo/food_photo_preprocessor.dart';

void main() {
  final preprocessor = DeterministicFoodPhotoPreprocessor();

  test('rejects a decoded image whose dimensions are below 640 px', () async {
    final result = await preprocessor.prepare(_fixture(500, 500));

    expect(result.upload, isNull);
    expect(result.issues, contains(PhotoQualityIssue.tooSmall));
  });

  test('rejects a very dark image with local recapture guidance', () async {
    final result = await preprocessor.prepare(_fixture(800, 800, color: 12));

    expect(result.upload, isNull);
    expect(result.issues, contains(PhotoQualityIssue.tooDark));
  });

  test('rejects a uniform image as too blurry', () async {
    final result = await preprocessor.prepare(_fixture(800, 800, color: 145));

    expect(result.upload, isNull);
    expect(result.issues, contains(PhotoQualityIssue.tooBlurry));
  });

  test('rejects a contiguous clipped region as a major occlusion', () async {
    final result = await preprocessor.prepare(
      _fixture(800, 800, obstruction: true),
    );

    expect(result.upload, isNull);
    expect(result.issues, contains(PhotoQualityIssue.majorOcclusion));
  });

  test('accepts clear black-on-white label content away from the frame',
      () async {
    final image = _solidImage(900, 800, 120);
    for (var y = 150; y < 550; y++) {
      for (var x = 100; x < 800; x++) {
        image.setPixelRgb(x, y, 0, 0, 0);
      }
    }

    final result = await preprocessor.prepare(_encode(image));

    expect(result.accepted, isTrue);
  });

  test('accepts a clear bright plate against a neutral background', () async {
    final image = _solidImage(900, 800, 100);
    for (var y = 160; y < 640; y++) {
      for (var x = 180; x < 760; x++) {
        image.setPixelRgb(x, y, 255, 255, 255);
      }
    }

    final result = await preprocessor.prepare(_encode(image));

    expect(result.accepted, isTrue);
  });

  test('accepts a legitimate thin dark frame', () async {
    final image = _solidImage(900, 800, 140);
    for (var x = 0; x < 40; x++) {
      for (var y = 0; y < image.height; y++) {
        image.setPixelRgb(x, y, 0, 0, 0);
        image.setPixelRgb(image.width - 1 - x, y, 0, 0, 0);
      }
    }
    final result = await preprocessor.prepare(_encode(image));

    expect(result.accepted, isTrue);
  });

  test('rejects an oversized PNG header before pixel allocation', () async {
    final result = await preprocessor.prepare(_oversizedPngHeader());

    expect(result.upload, isNull);
    expect(result.issues, contains(PhotoQualityIssue.tooSmall));
  });

  test('rejects a dimension just above the practical decode boundary',
      () async {
    final result = await preprocessor.prepare(
      _pngHeaderWithDimensions(4097, 1000),
    );

    expect(result.upload, isNull);
    expect(result.issues, contains(PhotoQualityIssue.tooSmall));
  });

  test('rejects a pixel count just above the practical decode boundary',
      () async {
    final result = await preprocessor.prepare(
      _pngHeaderWithDimensions(4096, 1954),
    );

    expect(result.upload, isNull);
    expect(result.issues, contains(PhotoQualityIssue.tooSmall));
  });

  test('rejects a 16-bit RGBA header above the decoded-byte budget', () async {
    final result = await preprocessor.prepare(
      _pngHeaderWithDimensions(2048, 2049, bits: 16, colorType: 6),
    );

    expect(result.upload, isNull);
    expect(result.issues, contains(PhotoQualityIssue.tooSmall));
  });

  test('rejects animated input instead of decoding multiple frames', () async {
    final animated = _fixtureImage(800, 800, color: 120);
    final second = _fixtureImage(800, 800, color: 130);
    animated.addFrame(second);

    final result = await preprocessor.prepare(img.encodePng(animated));

    expect(result.upload, isNull);
    expect(result.issues, contains(PhotoQualityIssue.tooSmall));
  });

  test('accepts a real static WebP and decodes frame zero', () async {
    final result = await preprocessor.prepare(_staticWebpFixture());

    expect(result.accepted, isTrue);
    expect(img.decodeJpg(result.upload!.bytes), isNotNull);
  });

  test('composites transparent 8-bit RGBA onto white without hidden RGB leak',
      () async {
    final image = _detailedColorImage(
      format: img.Format.uint8,
      numChannels: 4,
      hiddenRgb: const [255, 0, 0],
    );

    final result = await preprocessor.prepare(_encodePng(image));

    expect(result.accepted, isTrue);
    final output = img.decodeJpg(result.upload!.bytes)!;
    final transparentCorner = output.getPixel(20, 20);
    expect(transparentCorner.r, greaterThan(220));
    expect(transparentCorner.g, greaterThan(220));
    expect(transparentCorner.b, greaterThan(220));
  });

  test('normalizes 16-bit RGB PNG channels before quality and color checks',
      () async {
    final image = _detailedColorImage(
      format: img.Format.uint16,
      numChannels: 3,
    );

    final result = await preprocessor.prepare(_encodePng(image));

    expect(result.accepted, isTrue);
    final center = img.decodeJpg(result.upload!.bytes)!.getPixel(400, 400);
    expect(center.r, closeTo(65, 18));
    expect(center.g, closeTo(135, 18));
    expect(center.b, closeTo(210, 18));
  });

  test('normalizes 16-bit RGBA and composites alpha using normalized values',
      () async {
    final image = _detailedColorImage(
      format: img.Format.uint16,
      numChannels: 4,
      hiddenRgb: const [65535, 0, 0],
    );

    final result = await preprocessor.prepare(_encodePng(image));

    expect(result.accepted, isTrue);
    final output = img.decodeJpg(result.upload!.bytes)!;
    final transparentCorner = output.getPixel(20, 20);
    expect(transparentCorner.r, greaterThan(220));
    expect(transparentCorner.g, greaterThan(220));
    expect(transparentCorner.b, greaterThan(220));
    final center = output.getPixel(400, 400);
    expect(center.r, closeTo(65, 18));
    expect(center.g, closeTo(135, 18));
    expect(center.b, closeTo(210, 18));
  });

  test('uses a bounded decode budget appropriate for multiple pixel copies',
      () {
    expect(
      DeterministicFoodPhotoPreprocessor.maximumDecodedDimensionPixels,
      4096,
    );
    expect(
      DeterministicFoodPhotoPreprocessor.maximumDecodedPixels,
      8 * 1000 * 1000,
    );
    expect(
      DeterministicFoodPhotoPreprocessor.maximumDecodedPixelBytes,
      32 * 1024 * 1024,
    );
  });

  test('accepts sparse full-frame label geometry', () async {
    final image = _solidImage(900, 800, 120);
    for (var x = 0; x < image.width; x++) {
      for (var y = 80; y < 100; y++) {
        image.setPixelRgb(x, y, 0, 0, 0);
      }
      for (var y = 680; y < 700; y++) {
        image.setPixelRgb(x, y, 0, 0, 0);
      }
    }
    for (var y = 80; y < 700; y++) {
      for (var x = 80; x < 100; x++) {
        image.setPixelRgb(x, y, 0, 0, 0);
      }
      for (var x = 800; x < 820; x++) {
        image.setPixelRgb(x, y, 0, 0, 0);
      }
    }
    final result = await preprocessor.prepare(_encode(image));

    expect(result.accepted, isTrue);
  });

  test('rejects a thick diagonal obstruction spanning the frame', () async {
    final image = _solidImage(900, 800, 120);
    for (var y = 0; y < image.height; y++) {
      for (var x = 0; x < image.width; x++) {
        if ((x - y).abs() < 110 || (x + y - image.width).abs() < 110) {
          image.setPixelRgb(x, y, 0, 0, 0);
        }
      }
    }
    final result = await preprocessor.prepare(_encode(image));

    expect(result.issues, contains(PhotoQualityIssue.majorOcclusion));
  });

  test('accepts a clear lit image as metadata-free JPEG under 5 MB', () async {
    final result =
        await preprocessor.prepare(_fixture(1200, 900, detailed: true));

    expect(result.accepted, isTrue);
    final upload = result.upload!;
    expect(upload.filename, 'food-analysis.jpg');
    expect(upload.mimeType, 'image/jpeg');
    expect(upload.bytes.length, lessThan(5 * 1024 * 1024));
    expect(upload.bytes.take(2), orderedEquals([0xff, 0xd8]));
    final decoded = img.decodeJpg(upload.bytes);
    expect(decoded, isNotNull);
    expect(decoded!.width, 1200);
    expect(decoded.height, 900);
    expect(decoded.exif.isEmpty, isTrue);
    expect(decoded.iccProfile, isNull);
  });

  test('strips input EXIF and does not retain replaceable source bytes',
      () async {
    final sourceImage = img.decodeJpg(_fixture(900, 800, detailed: true))!;
    sourceImage.exif.imageIfd['ImageDescription'] = 'private meal note';
    sourceImage.exif.imageIfd['Orientation'] = 6;
    final source = Uint8List.fromList(img.encodeJpg(sourceImage, quality: 90));
    expect(img.decodeJpg(source)!.exif.isEmpty, isFalse);

    final result = await preprocessor.prepare(source);
    final outputBeforeReplacement = result.upload!.bytes;
    source.fillRange(0, source.length, 0);

    final outputAfterReplacement = result.upload!.bytes;
    expect(outputAfterReplacement, orderedEquals(outputBeforeReplacement));
    expect(img.decodeJpg(outputAfterReplacement)!.exif.isEmpty, isTrue);
    expect(img.decodeJpg(outputAfterReplacement)!.width, 800);
    expect(img.decodeJpg(outputAfterReplacement)!.height, 900);
  });

  test('caps the output long edge at 1600 px', () async {
    final result =
        await preprocessor.prepare(_fixture(2200, 900, detailed: true));

    expect(result.accepted, isTrue);
    final decoded = img.decodeJpg(result.upload!.bytes)!;
    expect(decoded.width, 1600);
    expect(decoded.height, lessThanOrEqualTo(1600));
  });
}

Uint8List _fixture(
  int width,
  int height, {
  int color = 120,
  bool detailed = false,
  bool obstruction = false,
}) {
  final image = _fixtureImage(width, height, color: color, detailed: detailed);
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final isObstruction = obstruction && x < width ~/ 2 && y < height ~/ 2;
      final value = isObstruction ? 255 : image.getPixel(x, y).r;
      image.setPixelRgb(
        x,
        y,
        value,
        isObstruction ? value : (value * 0.9).round(),
        isObstruction ? value : (value * 0.75).round(),
      );
    }
  }
  return Uint8List.fromList(img.encodeJpg(image, quality: 90));
}

img.Image _fixtureImage(
  int width,
  int height, {
  int color = 120,
  bool detailed = false,
}) {
  final image = img.Image(width: width, height: height);
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final value = detailed ? (60 + ((x * 31 + y * 17) % 170)) : color;
      image.setPixelRgb(
          x, y, value, (value * 0.9).round(), (value * 0.75).round());
    }
  }
  return image;
}

img.Image _detailedColorImage({
  required img.Format format,
  required int numChannels,
  List<int>? hiddenRgb,
}) {
  final max = format == img.Format.uint16 ? 65535 : 255;
  final image = img.Image(
    width: 800,
    height: 800,
    format: format,
    numChannels: numChannels,
  );
  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
      final transparent = x < 100 && y < 100;
      final variation = ((x * 31 + y * 17) % 15) - 7;
      final red = ((65 + variation) * max / 255).round();
      final green = ((135 + variation) * max / 255).round();
      final blue = ((210 + variation) * max / 255).round();
      final alpha = transparent ? 0 : max;
      if (numChannels == 4) {
        image.setPixelRgba(
          x,
          y,
          transparent ? hiddenRgb![0] : red,
          transparent ? hiddenRgb![1] : green,
          transparent ? hiddenRgb![2] : blue,
          alpha,
        );
      } else {
        image.setPixelRgb(x, y, red, green, blue);
      }
    }
  }
  return image;
}

img.Image _solidImage(int width, int height, int color) {
  final image = img.Image(width: width, height: height);
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      image.setPixelRgb(x, y, color, color, color);
    }
  }
  return image;
}

Uint8List _encode(img.Image image) =>
    Uint8List.fromList(img.encodeJpg(image, quality: 90));

Uint8List _encodePng(img.Image image) =>
    Uint8List.fromList(img.encodePng(image));

Uint8List _staticWebpFixture() => Uint8List.fromList(
      base64Decode(_staticWebpBase64),
    );

const _staticWebpBase64 =
    'UklGRkhFAABXRUJQVlA4IDxFAABQPgGdASogAyADPp1IoUylo64iIvjJGcATiU3fj5M8L5kcf61+QfkHVR7H/Yv2h/wP7Z/KLwnzXeUvsf6u/uH7d/I7/geVfSX+u9BflH/T/1/+0/9/+bf//6zf0//Q/y3+qfrX9A/zh/r/z7+gD+v/0L/M/1P/F/8D/Hf/////in/peqH94vUB/Yv8Z/0/87/7v/////qb/2v/J/6HuR/2fqAf7//b/+v2X/9H/5vz/+gb+wf4H/0+4L/Nf7X/2PW1/7v+h/f36Gv7d/rv/P/mf9t//PoS/qf+V/6f7c////hfQB/2v//7AH/R////k9wD/p///3R+q3+A/rv7JebL9W/639f8k/Hv881+/j353818ePvD8/e4L5APIP9t/3/QC/LP5H6AzxtwF/LZo/3nmb/LeoB/zPI3/j+Ab94/7vsBfzX9tPZv/yP/l/s/Ob/CeoX/Zf7x//v3r9+7//+3v95//n7vn7S//8DA2AbLrBSZbBbcWhOj66KK2+EYmmP/WS6Tib5DZK/FrSBPlNT9cFZWOjry0vgjj/3ONcrcuq23x/m1Pj1m2cdmZCogHQKP2svELluY5oIULmmcrKuGe3mNaVdcdaQW/mFOkC6R6GntmsyJJL0BdUvN9mZqiwygVaBifeAOgVbgLSqX7SG3c94A31Qm2olcK8Z8C/g6GQSnQgjv68HGfLV+bNsU8Xvng2Q7B8HEtIwrxnwCwrOtKoyADigIEvaZqFRoqmNoU2+BQz4G8ryKHu6TOYnr2/YVNElK/++4MtKe+5KkofS/+jEAnHJNTNRoqmNoU2+BQz4GcPLB/BLPYshS//Hzhl4hnuCiRoA534VhZOAjV3+iFr8qmMpPuQqiAdBCpjC39mITFxY3Qt9sEGYaTGfclSUPpgRhhiAGb6a0DY9RSnvqtdBCqIB0EDlSyHpvfYK8lWPfZEA4dx1nflPWM+BhNj0+pPAG0IahgsGcWdsYtdBCqIB0CrY4b80D0EnUWj7iMAShZzOURh2GcXAhoql/ooAOw2MFdBCh/cGWlUxtqKU99FU7nCeFZq+6qd6ZuW4W3uwsHrbrjpn3gDngdsogUkamaiANwrxnwM4uGfALBYM4vmBcxigQa5Asuxa31Qm2olFQij+ArVMndcajW8uGfAzi4Z0tupKH0uKwENF7BAZsMylzwWXHDWCGiqY2hQTKADCzeyvh37gy0qmNtRSnvoqmNoU24WQkdTXAKjswJfsFxLsLBnFna4pPAG0Ia1fz9wZaVTG2opT30VTG0Kbe/pYCGAzY3PQLmxpBGIReopT30Q0eBQIarXQQqiAdBA5lfFwwsEpVL/Q+uREJHIFyZJOsuoK8p76KpjaFNvgUM+BnFwwsCM+BhNoRx1pBze+JstsaA4bHv7joYf1gUM6W6BZxcM+BnFna/KpjKT7kKofTDDhYkHeINE7DE3eOMZ4nEZVEAbhXjPgZxcM+AWCwZxZ2xi10EDmV6rI2q/R8NI0ASORjlPQdNXwHJKIA3CvGfAzi4Z8AsFgziztjFroIHMr4ukKExlu20af1pY8m4d+4MtKpjbUUp76KpjaFNvgUM6W3UlD53VfQxBMPjSUZIoJhzNmOtKpjbUUha/KpjKT7kKofTAjPgYTdhY5pYCXT1NmOqvuVI9SUQDoIVQqNFUxtCm3wKGdLbqSh9MCNR9TBN7hY2U13rx7KEFEtli10EKogHQKtj1FKe+q10EKH9YFDOlt1JS5DjLX9AqAwbWXrmg3QxXZKIB0EKoVGiqY2hTb4FDOlt1JQ+mBGfAwHpxAvn9aqnPXFdKD8a0wWQ7kKogHQKtj1FKe+q10EKH9YFDOlt1JQ+l/9FZ5bv4NeyS8v3skf2OvG2opT30VTG0KbfAoZ0tupKH0wIz4GE3KnUku55nOc79iVHTOUNX03xcM6W3UlD6YJSqY2hTNRAN9UJtqJXEbeMqxzSwpc61Q3C9KpjaFM1EA31SPUlD6YEZ8DCbHqKU997oGcPMOEKofTAjPgYTaEcdaQtflUxlJ3XHWVxG3jbUUqmNs6amgDnfh2646yuEA6CBzK+LhhYUsEKogHQQqYi/KpjKT7kKofTAjPgYTY9RSnvvdAzi4Z8DOHfrAoZ0t0Czi4ENFUxtCmaiAb6rBlUQDoIVQ+mBGfAwm0I460ha/KohP+IP6x73ZXKCRuB+ieFXFtZOoUmJ7I5aKC2CTXH62HD0zJigoZb/sUtZtqKVTG0KZqIBvqkepKH0wIz2w0Pt4NuIQoC4hNf4s3p+YYfKIw/SRYgl9gIE7wIrQLGavMBiLTxh/eGgLYKvEM+BnFwzpbdSUPpglKpjaFM1D4Lhu7MLBJM3MIq0/KoCnQgAvSdYL3Yrw3EC7mkRJNY5Gwk5BMTAQfXZfmg8mNtRSqMh4IVQqNVroIUP6wJ/tJwqVIkT+80xgllwXOIVF0bZQjI4l5pv1cag494NaftyFVdCrpoeNx6WuFYdHS4clW1m2opVL+m6kofTBKVTG0KZqHwXvqfjXO9nNp4GauLhtSEFzbknVdYFhdhdmyFAL2xsb0whvSSQ2pR8bnJtGR6CB/9ZVltA3EXQZxcM+BnDv1gUM6W6BZxcCGiqXvjrRGzpETrcsaulzgILGWVa5xE/PR89jj/NcIAwCsBcqdANKhzoC6FIiSDLx7frAwe38cXDPgZw79X8RbWxK+CGq10EKH9YE/1b41g+6cS1mJl5bjzU8AmR4ugADsOBOoiwyohzMJx1FHfMyOjANzXHWlUxtnTUzVgDUGS74uGFgRntfipgyXoCVVeBKMT2qKJAAAI1a7B77LiZgUOI61GL6Q5rWuT0mmbailUxtnTU0Ac78O3XHWVwgHOhme+ie/zvE4K6ISp3BJjEAAMt7m8I6eR46A7AAVWcaLAMYSl7oIVRAOgVbHqKU99VroIUP6wJ/oGxcuTiOB3A03V/QAZCE4ADIMYABJoY2S71Q9gbIQSL8211yMXDPgZxcCGiqY2hTb4FDOlt1JKozD6cBGrUq14CUHUq7h615kOZSAAhEOKjZBxUuphAH3sIzNU8BcjFwz4GcXAhoqmNoU2+BQzpbdSSywSruTnloORhOb3nRUlyAAAAAA1TVSscNYDyvCsTnM1GL3BG2opVMbQpmogG+qR6kofTAjPgAh3gyD2xx9fqGW8VGW1zHmliCS26QJmMZ8DOLhnS26kofTBKVTG0KZqIBvq2dfUsf31hRy8bailUv6bqSh9MEpVMbQpmogG+qE21EriNvG2opVMbZ01NAHO/Dt1x1lcIB0EDmbMdaQtrP4GcXDPgZqiV8XDCwSlUxtCmaiAb6pHqShUb3QM4uGfAzh36wKGdLdAs4uBDRVMbQpt8ChhYUsEKogHQQqYi/KpjKT7kKofTAjPgYTaEcdZXEbeNtPAAD9M+D22NgO6pEghA2I7LKqUzM/ySTnTTXZgbkMBqEZCaZy3//Ar/BKo/fcT57JCDpftK8M3fgEhnbmX/VpirCW1Guz15ZTAnRDNjZmyG9E9+U2+iMI000ahUrRfmlQ+4l1JHN3LiFUZw/UMiIUIg9zI32jU0SYSUHTtktYOwaV+1ShvcBkFwgJ2SjFh8fL3VB6q45Rx4ket97M875wn9DMKpljvxSPmtgVeNGHEuVXi3fWdgA5QNrRHf+IMpbwToKDV07fW4Rtfeq1NwCXqcnpUQTQte0nm1hdcGdwOd/1UZ9MXnFnI28UlTRJhJKhmc1w6wqueCLh9yE9A6Y+xRKgJwerEN+9uaxsbBHZgGAS/GfwPj4KyxfoeJk+9GPIJx6gSlS8B5DTixtTjnZfOW6mSjnyQzP9n7nT9qJCa/pbjSJ742b43adNOFbONvWz3lgLjIHcnHOfNTokig+pe8uix4Ve5W3GDgJnNcOsKrnbmUceJHrf72cociLhEPtMfHlhqSnzRGEXTC3zSUfQHE8SOebfAyxD7lNYdku4hTnzr8LeU4TXAhsD8CiWMdULpSSf4yn3NGjEfkfj6gyZ4LNtyj0M4+xRKf8qrE3PScg7xhFOBvucNN+lVmP2TYSeL0LASMjRokM3c9c87H0pjxz7p3gn40NTeAAH1u/w5Ne503/o80goxFl9EAU2DwiffcQLAOiOnHFPNh4EhpB/4uBfU+4N2rrzDGvQPhHpgk5RFE7vN57krbjBmPsUSoCcHqwoG4C+rLIcn5AUP/ljIAWRF1NT40/ICh/8sclB1rUJgUPlLqkhnC+Yxo2XNbmTqooG6mpb3fLP+SDXQ+eSKt3jHhqpqF2OlR61BkRCk/ahgh+FFarZ9JuFmYSK0n0OKdKrMTC5NB/85ZfxNTfZT4MF9nO7VtrSvo1NmvDqaAenLTHJbNe4JVr9nUEuuElBTHya7ON3uyjf7lHF8tHMyh/9yjKoQBUP5HtHxi3H8/Tf5dnX4O4mYO0R5fl7m8U846uaNaepHN+PUdzwperuy8N6m0Wm3oPGbQg6JCcDKq2i52dQS7B3oD9eQ+ub/qMz9hwqY7AW7INJQy2V2Hmyk3mB4rZJGzHQP6SZxYgoRIpdOmQ0kR7Bn0Mw1cQNXJ0WEHBLscithuTE9A4xjAfTm4Raw2Vrw55ceae15WZ1PBuhMpMAXK/BiWVnJdGfuTzkUhQHyptI4nh+Fu/0DVrUjbcPaktp9lVcIrXQrPPOqO4diHIfT/5JJzppp3pCmL+jnACLztD74UPUXldslEWaNWHj1AbYUehwBbS5BKCOQomeShFcdGt/8S2/pUaO6k09nQeutuvW2jxANROrfZ4YIL8euTlUP0S8R4HJJYnd4+L4IQ9JqkU8PwsPa3wQAHQYz9RgpzLJ0sUS1QcTA6EfVd94dWaIQQy+bZIMFjlc+6Ifxxd0Oxx8a45q5L04ErDKP63WnO6V5T2RFARqmhtyskHAOE91AwNwZSIk0mafFuDkofoyH1GQ+I5Oc63ECmNHi2iV5cDpqSbZE+9PS+wRRHtF1hpmkKrVoa4DXT4/LQqZjKHPlVDLuPPaaLjUaZDcZFt7ZzjU3WP8NaE+pyCMJER8w08IvG67WQEgwMq88czUJvgbW0Rzj6fJ6LTAHsdGZLujxQUXcFsvx5rt2kGOQjAAIyd77AS4Oru70wGDO1BU+o08Q/zRO9e5/bA0BxobTqJfylzOkqeiJK9iupIMDtLPqQT+rROSjVNO9tjRAw17H+DuQyqEu4/u48VMXIU6bHe+MdKhzvxIlZr1atDXPxQVqy5H0NPwBC6vdFKfb5sZiNdovzkfh7ln3Je+WpjnfiRKp0sbT39Y0nUO2+6Tnm4vtVB5cD9jvormZz6Sv1Hvi3DswS8U0Z86jTe4xasBYyqejk5dFtre2tonTdMwUaPREE8b1N/jlpOHiQhrs/MNzkfAN5nZDrXHBZtBGpamxZljZNKzMMOHQfDu+8VL5EKtenC/aCw6WXKtbKAUKf61yW60BruqPICO0LHKGXfOsDAXpzbWhZtZvLFDk1SDTvhfDH/pY5Ty/+cyurXpxL0dHKLCtjQ0ZA0JtZNoFMp6e+Zp0QP6fZ8C7E91IrSlLtZ2BJJjAe0tpGZOY1ZHbX2oZZMBLxqnb3P17vpnITDPU5eiByyCx7ozFHAvTQK6TRfS7G1WJzBlbw2/CkNhy/yUhzwkYkAGe+YXUip3Z+Ddx1J5tKQFi+uQ9VxOXbBP80iCV55wxcTIDWx7r5v6iENf+33qVAs2GGzZgbuhJoFQ/P8Zae7KP8uPpC1kJeF4mSSCOO4vdIQfbc6W6xNsiJ6GCS43gs7iMLXDfbWOu+5nxb6InAP4E9jSDzTJy8VricvRAc0B4LHuh3Zhv/uMQLvaOoG/BZTqXPmttVrWvNfaLgDC3hrc5eX2KIF/dqKa4/3RcY5qo0orelA7xvBZ+21T0cp7PRNb21tFeKSOBcPdtp1Y+PGI7i9sjy4oZi7XFqTm5oa8ko3hNEelOtt1OUYVXqknrRxPB8TQeYWebPcZ/rpO5zavAPJmuLFh4yEaY2gBId6b81kv9Go/RWw+Thvfnem9bT8TMC8cW8tTrm2u5TtUBEPrnHNye+mAsO8qY4kFUaQ6ytzuNukN354KXX6LRDSxPRyGw5f5KQ54U7xcDTeE6xPRt3pdbAAPe1iff1bJhvxX2uc6acMEeQcr6HpUNTCq6tjIHuCAHpdatJwtFfmwCSJ+2qVBKDH4OxtO+VIigE535aGkh9dLt8eA2BbhRHX1V63traMdwgoBHJF/vc97DOl1jgWrYol+CqIXmKiiU8f3QthydtW8wWZaHbvMvxjO1gYvX6sk64mcxdLbXom8Yh2wfalwLHjbct44JnGm0ICEmEPIRttpQ2jf+6ZF6Lh5hU2z6bjWXyqAOV2Vgjrb7Q1Ly6DvA/lO1a+7P5eGoF7jsK9pWYQw0/qL9Y/3ishmp5mnRAqNeNK5aE1HH+RvUGjnTRlX5+v6TT7wwcAGvcHRChwetqHS7sHMPCSC9Z+ONKdz5wCTEBPiWxgyXj6VipDNpK6fGu6G7mpBZGV9Xoa6yq9Kud2OWsMuLSy+nxqcdFio/FTIsOW8+mQeMxcPgXXhaRgWoxTDEYx8OU5UF38dDzHN8xacw48bQnjWdCkjj1YAThAEYxpK6PYKrMIYaf1F+sf7xWQzU8y6kHnZzpek9WWsE1AJtxNqm4qPzB6SGgQbv9v7w46RMdqNcesW7KXxsbpn1PJnXfJvzOcglgGz8IpVAJ879pUV9ejBleC6zhrxNdSLsJIhpL1EPo7vu63unwzddMsUDe/ZpG+0uq3ypMt/Ne+wgOF49uqMjZ84CrWzjMTSXhCTNWZGtsKHjjNwfrhMmv6j5lVqByR7mqmgtkqN0gajSEFpFcxHmnSRc0/K9tKhhtJTWz6bjWkOLgEPhy8GwGUyfr4H/d6xpnuUaeIsiEAqD2nKT9G5nxb4lZ0qbJ8cgZvTw17U6+bNcVzmn78Jy9EEU6pV8vsUQL/BGZwk0b1wkyNQQ/A4tU/Fxa219RK6WW/uuHQAsvx5cakrWbh88vjaxsQBWdfcQXcCvBM9LqtwKcK+2O4i0eXFrPpbbRfwYttpQkk3yX62oWg53dcanKE9EHKQ4yJZmFsjwOfM5RGK9xWAOhWpyEBe9Ik/SmP6p49usUOrG7oLrR6F75WOeYVNs+m41rVSRw0jn+819ouAMLdWTmn78Jy9EBlTWPnu9p0tdjlI1ZL7ZcqJ0LQxyCAKN/vn9gBg815tf/4seuabdlVrt8MM9Tl6IKhZgx6RvCMSFmA7lKA5EaMVs7vncr63tEDYuJ90zlsLJyopY3BWs3D55fG1hcWdXpRD6O81IE8v6MGh75NyLuPCDTa2WquD+tsKd0bRHJP07tRhUo6oHQuyP3rqbS7rCAUfkrevW1AiQ5AGU21T62ZlF1e9OIGgNxTUHGLx8NbRAX9bTLC45cLBIeGEQqZldj0BL8XB3j9U/hhnqcvRAYK60v8tMn692g7RJ3xHJP07/nvF781UJYkdVV8hQvsjhFClYxCpCpyopUuXZC14pwN/CCHG8/8eGLdaA1eqPYALKIiEEONy1a5LdaA5Q1b0FvhrKt6c1+t14AZy0TjAY8G+91qF/vSf+bG82FHvYvPPr3pxA0Br6NrViRpqFr6HLGwzjQtUO2m8qNAw5tQD2/dh+LX/FFLKG+3FY8Bf1tM2cidUilECyK7efnnnyZ5whLlFQUJmc1HKwklpVrhiFv92t/9nIBw98kozjWneI9wNDQUkcMU1f/YhXeTuF7WdCG4gbIblLaOEEONy1a5LdaA4l5iXgYTDS5+f5qmmNARU9jNGfe2Vc0qTJyDl2yXtsz3RLRtQLS/2au+pm+nZdOT+j6O8m47j1lvcsGyVmFboKXC6vJOy/5L7gVH6xXcpzCBv9vV+h94fFVVnSZjbMzO74SxzTn/+qCFWYQxyNSbX/tMfYZpDA7nlHYq5V5nj7I3igHt+7D7x7VsVkM1PM06ICiG6Y6E93w+0JeT64ytiP6uiCPOGWCxR2QJVeNVAOAe79CMFc0EyY8vTa5hjeRsdVmPVn2uHm9/FGRZ7N1cZLo7uNDB8j/zmmx2upVEwQDBRaGAx/LjqMZKa4YMFwOfMirKm0FgFf4QgCO67SKMihz4pcifXlaEXw+0HxgT4iRK8vMMHSkFIRAkNALEMUY8LZ/gse6SctUqK7P6+eoVTKv5M0q/jmAoc/N2lOXRZfXRgsIfhBQgb5vCpyhNk6PcmXS+t7p7yedZ1LJGYbz1HZY52lbgilh7ZVpD+FTQsW0vqhB/O/R0L6V65lw/VUDV+FEhtAVND4fc69w3Y7NkHY13MOp54M0LOwya7pi9zS6WCZUDMsaMVrMBU/5BDAmcAqgHAORBKosMRTIm/bKAVOCV9Mnr3TTt9p8wIt7TFQETBOdWtywu1GPjIIlMMsYKsdZcQ2B9rKr0q53Y5ao1eOj8RqulnURbmjcBwMxHO8RwXweTBrNdpAVP/dtbTOCy+fBvdPgzfF101bIKMGOr8zzREk7k/2dJjG/8XlWF4+G3z/wTXeOe6kjhijwhmF0c6UfYn+hFHDUKKuL0kO6Pb4/qkiK8iRLP5GFx4c41Z+/CcvRAgBiTJS11a1jgXtZRSvBFiEQdcSRTS+E/Lrm1CqexpB62+/ix65pt2VVVjAF/cuQlFjfoy26SxVrHWv0d14AZwtrhMmv6j5dbBR03nmb4uukvrbCCdFPPJExFFvNaI9KcPHUdIDIJ7oC6OtsiFJkevm6MWajrlM82ZJITgmeuaGyrC4mPlPCqAcBBQVF8VOGJc027KYWpMJEyQht2WNEJOTzHeNOI/gu95jLb1bzyRmEZQ2BH0glL3I3cZZXVZKcjESt0UkcpQwsa9U3dacbNJXIIr2AUCxM8KakYzF99R+oVFM4ywWhuPG4dQQ85ZfSdHaZvATb4mzZ0th+H/t5ZUkcMUcLgAx6dmgHZ74pb7/tQqemtVR0IK65FlPkaqr4sLJ2iOMXN6DBABPWDCeZNfz9L0iXE53uTsAODuik5MIogT3ebUhlmESANocA/o0oZHk8y/vFc2wC1/alMIUeznBYNlAuh5PDHg4zddek1gzQs6l1Lrr0msGaFnUiAoAzKATUBgwtffH7KJP6QizfwwVMum2MTXcxCP5hoW5b1FXza5NawsJGuJ1xM5i6W2vvTfa8nxj+77YOZpNYjMnVEFZY/Js2AJ0kr5vGNJiBLpcpYfitkka+UtlHTdoaBky45E+kuiLCdpn1Pr2dRn32Sb/xeU1kzZ3VmbrOKvJ6PM+FaoP2AgeTWQpSFYVWYQw0/qL9eSJ/NO32jwy6QfRDURpdZCnqZ9kv9zjKuiFEtF0AMJeE2OZ7DjdsxHxBSqz5ejXE64mcxdLbYTkPe5XLWHQPvTYgf8MXEBb/9vvLuiE/4NHJOyU+XbB9qXAsp++zkr+ihM9ZZ86StveRPy3yoj30H5mk1iMydUQVlj8mzYAnSFFDJef0khLsyIU7y40DKAcSMh1iLbaGUa49abn4P8CWMcr6b5IhVw7nJfLf8U/fXdbYNJPeoXSdK5jx603PzqMMJ6zAI96b/wK0RdjI86uwsc+04KMA942Ae1x15he3suDdNmEO17F62aWfOKOeWCi3xNKiDLvHdZcVywyRHOSYxnzAK8YRaZ8czz9AAp02xia7mIR/OF3utSKesq+INOcuPWyNFfuxf5bFQ8ZDIIg6yseE3/mmQPM9WHQX2LwvZovoDOSHp/V+cAf3WNG3zwgOfSwmJTVYejQM1BUkE/mmIB/1mAT28Ot2pkT65RkgaAFZdh91MrM3WcVeT0eZ8K1QfsBA8mshYNP+yG050/nL3m14rY//LmkNb2XgQEttjfh5OLV+4MYwHYgyjJwZHGRz+YhLsDcC5L0iGiNMeD5Mn33UjFe6d1LfGUlBslZBYvH9TeynaeGMRf01ujKpvv+0mMs01Ghg4a/6Qizfwxcz8LLWk13MQj+flzYK9B2Sm7fpWRXBZTU/OTKFvklVfXdUxoCM0/tNThO6WneKIjVplzlVssmPL/xYbYVjHx/unkT6ah1CK6Q4vRwXnUtmwwOubNsVfe93MM937mkNb21YwaRp/v1Zt5bV8doP9YRSCaf6rwAH9+D85YCepj6SuQAeLNOY+N5Dv4JYhQJuxkqEswVV3wljmo5WN6T2xgs2s3lih5VVnSZ5+VaN5CQvpzAtBzaI0tqJw/ZURW2gnAngt82BwF8OTV8Pocmr4fI5NXw+hyavh8kBp54DAG7uUILIlS7mXr31G+ZERsze4npZx5NUQ0ajPoRz5fMTx+bHaCPHyBYT5qJ3+VaWC0gOKHtc3IUhc1rFGfDwCBYTlp1R+6/jVRTd1U9aDbxXs1E61TBw61t1Em5LXhpuklEhGMJUv5fL+zV6JOUwP6PljWBiaDk6UxryhKLurm3PrqegwVgpGKH13J8J9jZoxjIOBQ3sOoj6vB7GBFC4+0+cwUzVfR0bJqXknmsUntRr1UOKfXnTzp07xcxat49MLRzcTdiIS8TfQZ81QovMQYrSHRTom4ltk4lPwOvvmE4cXqDBuc0Qm5rf4JOCkWR/Uagi7/BiFEi2rNBbO6uUpqIvbFmgTFsl+CIciYU2BGcgtrYLNwNkeKLa3+RtmPpoXQkY9HhTanqoZMfBmDBp/BoCRjuYjt92LtRLHtVfrb9O3wLzDFjtFf+Hm5rKVsd9PjWxB5TGEv7scDt7emxZOuvnY/5VJrnkysdbcg4aXjDqL/umrE250ILPukzjQ9uefX+NRU8xxRa1YCSPd+3/gBt02YzZ49Ziz1c+uwpF0O5E5gnfKPTNJxf2c9wrmxzN0af4KHfUj6jV5FOrgrukX9apOIDts/ikQlInO9CW7TU9/r9TlGmH/rQlj+oRjMt2QgaFMsm+NLVXxvxXqHaas3Az863avBT8pc6icMz127vRfOZwK0B4OHzxAisruwh6LAbWwvGpsdmVzyd1pnEUfEJjYJMfvivpIJrRqXZwrozfdnBwiZx4BSXjioAuAl0XDPFr7JUja9iY62Z8uareWY/BmtRTQy8Cvb/xMgvl0Yk8MJ7MXtiJQz6QbGiZtC7yOowkJnbfX45rYdU1ckBotjhpL/QAGKRG+Lj0pC3mrRxvr7XMpEZH+nlMCPN3LW8QSYDBm3tPyGPJqnVS5ZIZqOeNix9uqi61sp0BuWozrtKIik7vaO616lsgwl7VJ9Ua8OeWXjg0GNceq9OBdx8zXmpnUIrRS/fwuscRNO7KiLQBOFPQRs21RiqEMLjlIx3vF0hibCpFoiSeNQ5o9rhPoIg3NQIJBXPeWy6V5+RNp+1RXOg9wG3FZk9WNsIW0yU3MHSWBT2D9meOCurBJgl4q5Vcuka3X6TAanb7o/7qsoRvUzMvCVTB3LyB8f2XOU5SswfW+L0t5R9/dPG6FF43/vHCFZaxzvWYQ0XH9KEbxu9ZwGQgcODsWJ9QB139jM83QEPvO1OXdNrohw76bwvbEzyqx3i5MotxDZ1v0vwNfGRWPDn2Of8AnzkdR0VzWY12D1JKFsmcIcKVORzYX+Ffykhto5IKYFk30TYYCtyVOsalzBH9ZvT0/gRMP4eIbnevgd6S20x6uJpIwdWzU72RT7erqYNmk2BOeVdFqYjfOcS84CfVhaNvvMbpBnLnFVk7aC62dyx+ouLo1XGt+Ke4hOaQlvsMtZSEd3wBT3EFmMxESbJGhprxmKxAs67W9iLutjLR3r4fnYfHvUk3Lq+ljmZzV4Pv9WKZOW7rOMiZ1tGP8edNcncmeluv0YyB0ZS7/SBWSAhak4AMNErCuK+6YAapwLfApZuwh9CoE/teKNYjc6SGPcKcs+opGVI0fQt3wn8gg/KgamlkafBrX5s7Tsjpx1DPzilFEoWfv6BVPE0PSXOFe3K3GlLE00aR7EGcCcPaCO9XXgh8qbnixBQPg+T/NNVwegUHV7q84DDntvFBdoWVRTs5WCg98r5857PxSXVIVYi7AwoR/6pSi9jFML5YmDxsHN+XDLAJu9uajaZjLhGCbPg3FU1F5MYLwV6HJ/zcBaFFRnD3movF05mSgnmvarmnMaz8iyuTzje3ZMomROMt/03mr46fyjLGpYaObmFB4qfg9pSJ0zWTww0K4OP2febXytpngd6u9i1d5HS40k9mB6CLHCKZV+S/87gJ3zIDXcDGncsPHuq/rddmAIQwt9e8IaNWxi8rKDYXy1BaVnifjLXvlK+GSbZySAB4QPPP1aFndOydvRSMDN+p2LMOHnT0u0eyNNoEikm4wk3kMI98p3e6Mw0uwWbs3A2Z/LnhI/euBcEWcIWg8/Q5OOSSsE+gXboPZ45wUxLEhMMoFjwg83q4+lI+xxxaBcAUFSB6bX1cQnakmo++adlM90uQPCqrn3tytni/GAUlia4FVxS8UgiFzQ0I8aCC1KV5I6O4+ditLRlpD3WS39ZTK+CF6kDkwlYgtrvJ4ddA6ATIvDN03n/d5wldjSZnH/pgK9govxMZ8qzhwdLuxIrAAT+rI41JJKu6aCYnRJo+vqj8HGpY1adREFCaRpsaSx7qHg9e/xGq0xNCznhTUoCktduFgl59/iWO92ym+HVwz9OAb6WGtRPdWLC7i+9s5YDEIHb3N6UMtJsiXhlr2zkTd2KM6mmy1T64HG/YII3IxfpCX+B5e6RheIltYZI93JlF2vwWwjRtvF1xau0IYocPuFULL74ghcmepOA3Iwxy1/UUxvhQbFT2ILo1p1UnyxxZkBFR6C5htKZUz0uHuDFw4OTOFKjKeUSpO3KU6oT6cvVEbYvrAaCUQHiXYntVzEmiYASrE/fggwCWwYogejKexBxDmoS22igl+crePXNqNsNK2dWTkqbPRDvvIaXWI1/+L90LfUrh4C5KetBII8z/a4VyCm9nYLn7wmKSFvI64QmdPfn78jeyZho/RxiVznWVVw/ykxn6sn+aOAJOkzs1S5nv+j4cFBPcjBa8z4h2kGPWOA9ABZinSWyHGHlJNguh91o3wykX1UxOz37ac7LALD/ci4e8NJCnUX3X8tWAvVAbB12Oehv097uM6uQTQ3JsoEEoRECPOcbpBroiJBManSAgyl5mcd4ltDgoSthOvRG+DgZQH/74ULIZTFQMmPkv6YQMGi22h9mTLZF12YXFGIhYxmRHjLeW1iDCjhSVBPboeataP1mAoMOTY2BUuAp/9k54qzFu7y4riQvAwR+bzN5V+vqha6Lyn7Y1sTf+afj5fcUwSpgDQv8Cz6aRw+K4HKg1Bd1ZGnAjaeHZXn35cCBTb8ET6BLMwcJEsAB3Ru8mRgErm1ZKF9yj/bqfIaY/T785anPriMXhCSlN954fYEiVQPuesOmmC2jFdT3aLfgA74rjk1aKD6HhgRakMWACgeLSJjv4IEQbhD+yT33hKv2idQleGE/9cvmVvNeEEf9qklvRjwMqFcTGEFNlkP3CpH+LQcHVhx5KnlyzrIpzF/aiehSdYCvjqcOoZVJ0qVtiguO0Iq01Snwno+Td5sbDXS5ZnYNpMVsQBZ9FlGx+XqbDyDeHslC9Lw+jbv3sebVGj2VaQ+zDL/2W3uQTtCUIuBeJbN8uDiZ5LHmDfyEsHFPnx4ozZ2G6y6jQvI/aV/32Kh6CiCf7YenIH29OtAhtccF2V+uM28NluuA1pl903OLCZDun7seQjlwEruq3ODCQf/BIimFVcTfiXyFknlRl2h27gcEw7F2jOxGssJbwRMM/vdveDytf9Fs6KjZFWKnVVZ8KtGAFNtiJCFleiqxebwEtLJxZipoSPggCBgTVSOa6FDSq9cMEqywMWEbebjecO3io16K3NRC4xKDLr1EkjDH2LimqDOZ7mOZpoB97IIDrSRt9zNdKR1kVJ3KNbvG2VqASfqHcB94YrckPO8krKWZCmpq6himjdEXchDbdBcB2a7254A1EvHlyBSSMO06spfhLjaXPmqTPgnlvHZr3x4DvvacHHFqhS6BlppmarWHs9dDHf6lfv26j/f/XIPGnEYkS9ZKIewT/AJMqOHJBYVXHcIxpS3P/AOfEl5tuioQ+0VnOs+PVWchtCwzEaAJogaQ9Ej+PpcIixfbA7ZTerNUaAwPAc/PgYxTtG8tpIvi10EVYCQbp0JNZMnOnWKoOqlCpsSC0DwC2rce8OQzQ7BPo4jmvKJb4Sniz1mPXaS3qYehS+i0WShYN2m6f2Ro8CL1YQAqyReVv+hLPPZzas2wMUfQozCT77xgSPpjzxkrnFsjytEE6Y5y7aCxLT83NP0bTqyQckWPSt9+zZQ5dtpHJ0dxgwisEEMcUc1gyQMxnaw6dnXyEVY1YC8fJzOkLcETLh7dP+YebdWBJzv/7YeyIALwgLJf6CJJmL2HsScvJbE/sNDIwjQV/ix6LXaYlAS622IaejVMFdT07BsqfcYeGzpQsQlYdJ3N3sReR+rVC+0bovBwzttl7TuaOsPKDZAvi85XADVUymMMlpFdj5dRor7rCxCM3E1Ir5FLEsAynm9qUxefT0CtvsEiNkgwndDCJvhkbHTePG0Os0NHArbSsLflFggMhV0qTy0Ll9cUzHguBRstC41TllmG1GhdDAkPlgs4dofg6f9fnh5KuZP5tPBLfOF7nobcZ7rz2qMb/ZaBOiH+iLa2uHn2LL0eEY4Ur5wZlwSEF4ku/dU/cRTnHm7jvaJTHqI/nXwno03Hcr9JNMr51Ecu5noU9kZab3c//J0P5HwkXQCfl7cttmcdqY3l4Q+a0e/rl7WjgfQY9rlg0KggWXkhwaLNz4rnE9VAvdSTXkjENSjeoaRuWdms3sFUKpde1vhdagZDgXfAjRBlWxSD0yn5peaaq52UdIG1z7B4UinSChX+zxKC7yTm/FSfXx7fn5cVya9/X2GnHeQcClJvfFe/ckpRuoKnvkrE7s3eIdennAaq1FsEx1sg4YTtmEo0dv1KFa3irygaEV0HFBDFnVP4xad1YXI/qEfcR2nrGp/1bbuVyPRhH4rgT+tB1M8R7QIXuioS60N9qJZHmQyiZoUZy6jDSpkmVcp2f4KJSbBu1Fe0Mtrxmtdkk6q/MwxTLkqlpyfh1xNCE9QezrzGUD4oh3Rsfchl38T21VB7wt2K5Jm1yFelVhVaYn0armSi7c6IpY990arOMmR3dkNVhF1z+PvAsNtA3Em+iOVZ6XZg0bkog/6r/3kOuGbGQdWQgo+GOgFg8HQKwH4d8e1TSdMqeVRtGGv0yCFHtKluk8cQbLJph7/2wdchY6WiYHpU+hJpHlf5/8YlWQSpaRDQzLGs5eH/zWVaNDUSRKKTSUpveDp610tpFsqhr3kOT1lk2M6dB89I2lCmjIimp2eMF426nOy60SungIR+K1tw+ooUkteuenRPaAI7BYrniQgHQcFgH/Y78ZwndcUEwxSZ0Y3C9HlT3rKQHP1C4cZlnVVlZVk7PtIiQs+j9wwAaYl+DRPalJ4x/s4ESqR0vLo/gAMxUh6hVFJo4LEh0up7emQqVncbLmU0RUNtYh+wC+Rt8mo7fIcJPhYbQuN1wb/MNdY9z/b/x+7IGaIX6ftBAU+NEvPJBWugT7KRKAso7Q2sHrG1TFTjOz+e2lRWiGz8dC5HQELX7vElhLBzhdvJZz1PTuiURIcASWW8GnRDNUEObSGlGvbZwjg70xRi5s2XynzrO136HbihDxk3041U0RXNg12B6nbSK/oQi8XfJwDVnJ0lgzlJD59PA+bemrYMrQ5z4e7B1rAHewfh/NEec8JeykyGnl04g3rbfpImRfu1kHdutZc6H4c7TxUVptJWWcBYbs1daX6RNCVQlThMez9H5MvtO2OmTeCrKKAcAE7GxSLLf0tORj+uNQoEpblZ7GfNSO8wXDXiGWsC5nhsdX5/OB/DByLBMSl4I/qvHv2Ml36cl0Uzab+SNG94OpXE13n9uNk2AOobyONewUrg9wolnYC0f2MCGcdxYHLZLqwrGoQN16IT4HWoX9OVtAWfpyeAFBMc8RBqsaA5DI37D+jy0TuCKFi927YCAal+sZBJQSW62TiMl3NLt8HWr2zeordwX74OsPI7aQUa1S1YF/o7MApMTWqS1EkybVGcPmQ1VSlo2knogtWlRr6+i9P3+pBXT5V5gp3ZxW4Y+BhLJNbWnX5MfRoml4omxXqu7HF83zwlGg3wvgpATXH/w8cd36mS495vRe/OM4Cpz6DPXReE+trObn0PWEBWFffLpyK77y9RG/W6DU5zfdSuTkAxj+XHiAROmu2NIxrWsHZ4S5BNfR3U0BufDOkm75gSYOlAh4+ouFRFVi9J7pVDEtCjO+l40mSRNfxv9nJi6JuUX/A8oqJ8PqQz4sXUmNLxlwF0coiN/SFnt3ydzUhwuxjfL6HvDEwfDuIS1zeTd9XP+m5mxfla0QwPAo9aygNVFuSIrvo6k33yEw8QT8sGyAlE1OfuZqLg0L0Vrq6N7bgIVzdh5V3WdJA4EQMC6DDbcF+K7S7llqPd3AwPcVRLhgJCdxvHBd8S7dP/wGk1wBdGssxD2dh07X3pOo9J9vhgE+1bdWBJsX4oypYakuuHXzFzvItQchF8ZAzxSbAfb/AWb/Mqez0JjuNWF5GEyuIDHdgvcQzHPQU3mOgo+F6DiQjIdIAz1E5xvrW3TzbS58H9hjLy6NsC5ziGIhFaddsddLlfFNCIOOzmSyXHq1Ls3A2ZufcQkKjPvl9EyUjYYfEr12UvbiJRZ9LDX/odvV7pnPMJZU5jiBLklJSVbmHWvLNthGYjmu+/Disq+LZySo19XWltPd/FjZf7KdBAZIhWJpKvq/LS74HYKaQ1598brb+dkx+RX8BD5iFHIVbBHpQSr14qyHdCPA20bZZyyy0Vk81oDk9yBjf6EAtsddQ/g+K+us5dZLhc2rcttHxHeNe2IpO2ESU9HWv4kakvxjSrD+s+1GWOXRlr4+W2JwbB8U92gvTpRMHl+x6/TnVZMJW+jb4fOvzYM2rQm3wxWnNTUhm3K6hvQUoA3axI+t2tDNhUeEt4GxzE/o8cfQclyLH/09v5OCByE0urCgX0xetSdWexCAND0bz6vjvbMKKX490MYKSBFRCpmwsbqKn4ixU7HRDfKzcFHJMiCF5TxeOIRGrE0hgxg4CMdc86jUFhSvz6ecP5LQF6NKGgz0mKWzSLQ1AaQpnRqdEFudfUZ6ifDTLRv70z4aW2xO8tlnhdapJSUUR7SOs3KaiQGGUsovV52GET/dcz2pk5FJY+814HiphNiSZviRHRiQdQ5dPAzixCGhMsuqRWGNcquc0X7Xv/6dOWSzsXQqFCbaQYtv6RxkatWlPMUo4lOFZnSKjGXk1ukWvLtqQ1dnkSLN6H97o6tpymR3Hdbz3TELjMp17b+WgjL/qY0X4PSZIu4PGHpS3NZaOKpzxUt2p7PR2mcnkIKzzXimOo0DDbzP4dfAbSD2VL+dmjwR+63J9re4l5S7B4PXupYhU9/WNJ7PXOQ2HlnJademWzRLkn5urHqywAt9pqfyeJ2BbK13s/UIebcOulEMzwgzUKdbfTGuJOOl7pOp28fBfIHo/8ofDgyFhDMFO3y90CqJ/404FZfxu0awO1TYAl3u3LG+yMCO1/C1t/lMi9UPrVLj4RHy8H/vcbYBr3EHVN0p6ecuPVHt6Ju6YYJQRzADyGfDkkObMPThjH9VoUaJmq2MEgymbZXFX4BpEbGB7kHATmE20bV867oFsREHf9tYLiALIhCl8qxmBxpudtk2w5ql4YZCqPqOSbnT1tTvi9WJEIa33XSIZNS4Od3XB9UI9GNIaDZA5VpI4Gldthc6uKIqHLmtxi0SgwtPb9qyHT6wm/7hpPz21ADhSE2WpcYGU/XoWjHzNQijdr+FqWKMY/0gcIC8S/v61PDGfMoa1163llTR4ptLLr3TCuPRlfpoEsC3ifjQjQwsNy8DsJFL7tK7NEU30JUlj21RhzSyliTsEdcscp1e+cvyEkkdRiFQaX2TzUItMWPCR3W/pOnDsrxppxZVeSBvSBA4IWSzVmSNfs0ex4pS+eD+oF3ipSQ6cAR0zz5eGr/TaPNyU1l6PCao7wRBWt+eFCUvIJbx9T2gB27+eeyGD+TN+sDgOB2qKI6ih6QG5wmhMKWLFgOE2tTzUGmVtynfTX1HrpN628RLq/r1WZLGR23IJoo4NbJuVHdCJjZR9IjM3QpTEVtlVR5HyRhIIzxW6y2OE7ISNzm+XBbctNT7RPk+PP4Cw70sDt4d/fnqU41GoD5LEIipAPTJ+ljuc4TFzLV3e44oyvS8RpBtm8Yp1EKWusaXvghIaFYw9AXhWk32oVIHQgxGPHFZp6JPK8TFLp2tthc5on3U8boqDuL7wd8/s8nA0N8F0OsX0Z7r7qF3zoQG2p9+SDGgFEZbOppYwKD/xuLSkUAx9UVtPjTa6q337WI0LtQ4yQY3HpfaSGiueW0XPPSn/GPEAb8qqUpk/mWgdFeXqmwpE7GPqDJW8T4yIM6Ci9w9I7gDOuutns4RMUYFov6gNgdfJBexTXVnFnGopHFAKuOGIo+Oed8yFW1yptBKoftj2XPBBaccvpOWly76quhlsN6YtlIrIFXsQ9hhtsyrDyaJq59fZPSUoxOTIVHQk97uK3Ix+QBYD8hq0tgp+LimOVqAQgRFmYdLfLjW1P8bLvaFxWU8tNG2iIfy2mJgiKWgto/0L0YOQic34fizYkQX+STGGf1wxwDtdTk9jCPHgi4Tf8l7QtRmSoXKKhDBa22DeexaDlFNntv3EhuJzVHGoQGmgYmldVWefX3ahrle0itQ972D7I8hYZkCMMyksdmXulWJvI5ZxOIXtFEJ87wo6M2KkbrV8e9qlXd53mzxl2ucpwnRP5Kf34JiNZsbnxeycQZL6im+noEwYxgkPzcF21U8G8soiWrp62Pig6/4Zoa4p73I0Kt8l6ugZoSTogSDmi9GkkA7xjfZqNWptWSsxoXHy5+rLIYrXXCkzuqBB8kbYByIlkolCvl6oL5Yu324TA1C1wxiwt8kAqsQwEVvu69EPBTOrb/B/4emkRhCF83Mw3M9p7xNamn21gSc4AN1LK59UDTpf239V7Jrh9PyVbohcRJ++Z/PAyRYE6IqAp3iZMoSVJDbQYv/zfjcxphjiWTM1f4WMIeoGs/xCY1fYipZNJ1QlqzRpC7iOX/hGJUdR45MI4P5Y5toFg9irvcmc/oiH4MZjnSK/PFtNIj62oQCsdtFmyF6JhHwjgqeLb5EZ0pYydvgwqM9M4O9RqI8MowHUdnUE+ZzFf6x8vwqHbtTXy8zy7iBP9erz1h9BEC8foWr4/QK9Lk+1TP11pMj6By6hiDKlPVKUss2CzCR3WBnOxxJ8zTNRlTb1LyeUVjtFH6N4pAE2pZyhEOp5xDCx5JGF6OZm2g7ZH7P5icYmIAI/SoPe2HhCbUqvva9iY8EmIbKIavgV4scK9dPkeH2bZKiWexdUjXsabISJPNyrCEa4U3iI7KnWC8gOYBTaYGu7xb1JLRZprLpsih4M8L6sBnjhH9WOd2ZW8mP5s/aLVaOYMX44wwhliZWyR+MDMQl/4+KwCnuaA+qD7d7iLUqIo9Ql7/htniq/OmScD0Cn6gqHnHsrKVwFtTqPmeuJQE7WQzV8TlNvS39WArJ1135WXZ/iptLWqjwe72OGoLp4FVo26XKsy1QlStqszSIQ33T3FGlbWiW0LNc3ZCdF3sm3/3VvVN48+yrJRhRw7GjyPgWMRoxU6qb8piAxxA276bluvr85JxxSq09Ur3GAVW3JWSpHLcGDZnMJ/2WGtl9OM3TzodfBjoJbW0f3EyqNFQq7hh/m/+u8INHnXHnLMzApMRByqMlCgtMYLKu/TcfjqQeac973lL0giLKgwMXyDwlvg8OBeoCek6OIspOSs2RFxcm+YLYzRuxc/9tBlzEuooeC8K53ZArEVA1wJ4BGiEr727d8WnhSbKvRkUzHVxQWjqnkg+NyfHPb+Xs4VScGi+zuU/mTluh3EHldnC+yTSISKhUim+dL8baEhpF4PhR73YTssiwNPMZXDJvflzgPgqZAHoSDEStGikyvhEmaDAIGuzrXojayByis3GWzh6Secp5HEew/Bx2b+ikHhonvQip2HnTV3ToePqDAX9rgELcM4msv5bktyPfPOePEex6isD1eID1tsc6NKE+dqGBlVgraHeW2beldrVeq3WDJjhIUaGiZVqgtWcAIVwQKVLsI7Q07oDYtzM0qoqhkRGvIl0/tlu6BWltIXzuZYk2IKfixIPu571AxaFSKesqyEVdmC7+6QqxNQLt+SgmK11FOSP6K2gTsuJX7o1lGh1MgQKeYeqrW1DzKyGdjPISk0TsaLRVUu3MiXjt5qgiC5UnFDqv1ukFyofxFOv4ceb0pslrSA9wNBTLP6c79U7b9DoBjr2gun0r5lnLpki1Rnni2fBRI1i/pJ/JXvjQRPG48RmxhNKwFbgUQMgPalu+tH5flz5kFoqX0StFnCIbdj4XJz2uBHDaHrZLm77Hql8yjHQDzVXEcFpEzpZulXLg+uxkVNb8Hihz0k9MOFuEIMzKLxnQTeOG9y5tbjpKlTJBFSLE7PNC/MH0Ews2Pmlc4gEkWfqYbbLcoVUnrXaEt+2PgwAgukFpbEeLLgF9n63wbx9Sbt9uaHf+3TcrRHHp2HaG+ityyCOeLJ9ssyw5vUXoPd19c8nxhf+DhhPrWta/j7apNt/qavjGDeQYBT9UK2UlhBixVPBqHOk+GlrQBHrAT8GAavhYiq/r05EYuJkd65ahyMMZdtxftRJRVfNzDpa7sSxRNU52sLls9a+GZrbDhT7CyWXzj6ndgMX3J00Ea/UH0qqJg5qrxvaShAKFkhCCoWMKpg7rxPkFohHYWPRgIxcWj4QuUehy/p7q04U62RVfVNWkE8+j1hvUVl1vODGyq9aCVFMd++NmZ2BJmviZOuTP0A8N4yIYDo4ShGwlquGHZQIMW9jnc7TB41uBYynOU1rkpFvSa/aby60414YoVZH1yJoPQwKWHie+X8AD39lhv0FaMuY56TVFeQLc0+co2yFm4G2m52z1o7lOwTTpkakzewijLPPQHS9uMsTEEtENqQl1hlD2wHztzkkBpaOyQg2yJT+3LMFshBdNzOX/Wv1AMWfE0lra6akiBFNppAxBpBLGKC7aVkTYkp5GJXyAvqfMWToRgJXRv7eJfDOyV4mH+3dVQo1hFzy+7OB08vUN5gR9Hd1U5fjeM3tamxDPExee9kuxGg3VT6jeUx0oTMq5qxP6NoSbXiCf7TKabDy5a7+ibGFzE6X3dZTCG+Byaa8rROZDVHi88mY8vW9rVxzdDxhu1IyImxntIc3dVCKj4bVk4Jglso1koc1Fo1lvrEz0rRhOwJ54qv046McuqgVs0/pFuiIp9ZQW2X4sdppYzonUoqHTfVJ6kHfZ71zZWIjKcQgzk+raMK8V43P7t2seXigI9sapgeKMO/YtmTU/kgt+Fm0wEcm/C1dIi5hEmohIPU8A0SFb3d/C9c5rwlNbZgSkxjXzpkXgcL2CURxzczau4F14OQ8035m/VUUVVBM/PGQzJvjS/MHCl8VThD82HjtcufC8d/zJQWtlANDnvzoS2kJbqdDzTnlik2e8uIiAvEl/Q9yjDB1rcFuS+x/WjFCnC85fHI/DwK9cY25IcY27LsOP2H8TfEPyL207+tzTYreaVYvHaR2nZwTSp/ZD3URzwJ1nz24ve/U04g9AtMv8sHMb0nNzg/Z08GmTdpPMe/35xoFvoblrKIMKtk/L1untfODk9KMAcGvPMe2KiVmTlfA+ByTZdYTFg1G3COtWLUq2yoH8FZRYfkXW4P7MVxME7Wy2KtFJoPBr3ZQWIuiNgMy1O8ThjKm8mT5JTo0buvgHuDsJkawBmMXrt89cnGAEOrniRyC9H8TqhXS+TA5Fb6Y7N8iy3CTBOc5NmA/n/N3ZOJdXlqzrh0qXN1D9YAQGGOOr3qyTOYopLBAPLqVONaax2iOv/mgy3S0nv5Vzef1u8IzyIlhjD5R6DdRXb/cHCfMXFYVO7rx6FtXUoHWPwgyA1qc2FjWPC7feKu7s/vj/dwIa4awzppSZYnGcnjByNgKphUdwCUNEBEheS8l/QuzhF1LIZ9xoOT7H/TL0WeXzaPjRs6TRWYIUcNb/HiUZw7yVBMkP2r4FYoaqJcGyhxObBgpZ6x0IwnimY4718HVVH5rjFkMGkNQyCZkTRKvBAKTs7IswhWwKpT2fmP0au2QUFicW97cJTpYKRftMMgLwh4gKEbmQ4R9MWXVYXLJuOt6qLMqTBf7prEYqHirtE3+JwyOm7OyGsjdMeKuQFiZX68NyzmUfamKVsdaaF/vucrd4CJNuRpFecpqdncbnBvryybd9T0gPc2QgbVhkYOYh3Sm1jwir6302GhziCpOwOd9UNn+sxOeUny7C1SY80tFDlMEJ0oCVvxiKvdXl7cjYRohtUzqaLzWaNIty+hu4UL7BhlNsqNfqJPRS/qylaw9Wt+3aFJ2k5kftd3Cxf8Rv5QUNFqbuDJB7X2BgA7Ks51PAr64yJz6juOSHeYvmeJTPS0QnKFAp8NY0D4dPkJXcfpdws4g6F/qS3QFbV2ABquWa8uZhXKh9220KdpbPN399vPZgyP+LY5+gN6nSXhYfReInIbgP8Mi8u3pLsGmTo9nPuw9rN+Z+PHm7Pqibf3xKpafYKQqPwwjaM8zp8ogDF++C/5+4awFQqTlQ+/Z/xoS7ovxgEO/OmiZbH/jhkW2mq1DfPHh2Ep0HlwGAT8dhUAAjb/WEK462g9nQzJH0B+NU+IkSGdIxPotpwDvHehpKWCr7WSuvv83LeArl3/G7K7ztvmwi7M7I2f/mJ6gx38g5IBF1RtPpjY+cH4G9Lx2MD3s9kzIGZ0/oMXIVnWYBLeB2NTOoKILASuTF7g8DmLlhY8hIP6i84d0XaOUQDHnE5k7B8O1ZJWx0fAJQnzwQ7Yuk9H8Mc2xt2Pw3dHcdK05g7j/NKfaPXd/y+dOGf9iLN0oeZJwHGvhtNV4dX0zZy5UkHHOsr5Tdcz9V7N692b3Wus9Wm8umSZW/w70Qry6EjQCr558cAXR7yYNFMSRrl7KCpYIWXI7z3QM9aM/QAC0D1duem1qeUu+AP4u8u26gVBB+HrnWWHsym7g+jqt3HYVGeOcm9xYqPkuejtbU7yEJDefzekTlORSbvwX+GBJk9A4wE4B3MIWcRDGJlVz2GDY7mn8y/iflzxj69fXKw5Oo+BnuvxKqSOUUkiQfh7iXGcBJWAil5mGhiVOfEt+igdYYzWfNoDNra8rKeyUq5AQtBITVvbe102bKwxOS05p+3cjjyA4ajH3DAYdKcOcuUiVDr7nyAm4l4YK2A9zzuOV/ndlvjBQjfUF88w+k84oZIuomH+LZocSokAEYfWIJ4W33EZfI3Qs+pya1swIVq/eRAzxiXWdDjRZ0OeCePdtGm5h3NL7OXP3kcRrnfHKGOOKkDZ8MFHR/LdMarjwqyODoy9Y8U9ny5ofHrVOCTqSq6IbF+cA5oO8sGRe+fwEncNLsZQXoY/dnWWdS2hv/H0scHrygsojl9TjiS+GiQUxUN4Li+AVerjHeKwKBaDyBGEkBOYFI+0ughBXc9Jl0EJfHfLoIQUZ0ugAA=';

Uint8List _oversizedPngHeader() {
  final bytes = Uint8List.fromList([
    137,
    80,
    78,
    71,
    13,
    10,
    26,
    10,
    0,
    0,
    0,
    13,
    73,
    72,
    68,
    82,
    0xff,
    0xff,
    0xff,
    0xff,
    0xff,
    0xff,
    0xff,
    0xff,
    8,
    2,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    73,
    69,
    78,
    68,
    0,
    0,
    0,
    0,
  ]);
  return bytes;
}

Uint8List _pngHeaderWithDimensions(
  int width,
  int height, {
  int bits = 8,
  int colorType = 2,
}) {
  final base = Uint8List.fromList(
    img.encodePng(img.Image(width: 1, height: 1)),
  );
  _writeUint32(base, 16, width);
  _writeUint32(base, 20, height);
  base[24] = bits;
  base[25] = colorType;
  _writeUint32(base, 29, _crc32(base.sublist(12, 29)));
  return base;
}

void _writeUint32(Uint8List bytes, int offset, int value) {
  bytes[offset] = (value >> 24) & 0xff;
  bytes[offset + 1] = (value >> 16) & 0xff;
  bytes[offset + 2] = (value >> 8) & 0xff;
  bytes[offset + 3] = value & 0xff;
}

int _crc32(List<int> bytes) {
  var crc = 0xffffffff;
  for (final byte in bytes) {
    crc ^= byte;
    for (var bit = 0; bit < 8; bit++) {
      crc = (crc & 1) == 0 ? crc >> 1 : (crc >> 1) ^ 0xedb88320;
    }
  }
  return crc ^ 0xffffffff;
}
