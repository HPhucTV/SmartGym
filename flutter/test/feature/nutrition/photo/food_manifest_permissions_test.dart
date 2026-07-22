import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('app manifest explicitly removes camera plugin audio and storage', () {
    final manifest =
        File('android/app/src/main/AndroidManifest.xml').readAsStringSync();

    expect(
      manifest,
      contains(
        'android:name="android.permission.RECORD_AUDIO"\n'
        '        tools:node="remove"',
      ),
    );
    expect(
      manifest,
      contains(
        'android:name="android.permission.WRITE_EXTERNAL_STORAGE"\n'
        '        tools:node="remove"',
      ),
    );
    expect(
      RegExp(
        r'<uses-permission\s+android:name="android.permission.(RECORD_AUDIO|WRITE_EXTERNAL_STORAGE)"\s*/>',
      ).hasMatch(manifest),
      isFalse,
    );
    expect(
      RegExp(
        r'<uses-permission\s+android:name="android.permission.CAMERA"\s*/>',
      ).hasMatch(manifest),
      isTrue,
    );
    expect(
      RegExp(
        r'<uses-permission\s+android:name="android.permission.INTERNET"\s*/>',
      ).hasMatch(manifest),
      isTrue,
    );
  });

  test('negative manifest fixtures exercise required and forbidden checks', () {
    const missingCamera = '''
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
  <uses-permission android:name="android.permission.INTERNET" />
</manifest>''';
    const forbiddenMerged = '''
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
  <uses-permission android:name="android.permission.CAMERA" />
  <uses-permission android:name="android.permission.INTERNET" />
  <uses-permission android:name="android.permission.RECORD_AUDIO" />
</manifest>''';

    expect(_hasRequiredPermissions(missingCamera), isFalse);
    expect(_hasRequiredPermissions(forbiddenMerged), isTrue);
    expect(_hasNoForbiddenPermissions(forbiddenMerged), isFalse);
    expect(_hasNoForbiddenPermissions(missingCamera), isTrue);
  });

  test('debug merged manifest keeps required permissions when available', () {
    final candidates = [
      File(
        'build/app/intermediates/merged_manifest/debug/processDebugMainManifest/AndroidManifest.xml',
      ),
      File(
        'build/app/intermediates/merged_manifests/debug/processDebugMainManifest/AndroidManifest.xml',
      ),
      File(
        'build/app/intermediates/merged_manifests/debug/processDebugManifest/AndroidManifest.xml',
      ),
    ];
    File? merged;
    for (final candidate in candidates) {
      if (candidate.existsSync()) {
        merged = candidate;
        break;
      }
    }
    if (merged == null) return;

    final contents = merged.readAsStringSync();
    expect(_hasRequiredPermissions(contents), isTrue);
    expect(_hasNoForbiddenPermissions(contents), isTrue);
  });
}

bool _hasRequiredPermissions(String manifest) {
  return _positivePermission(manifest, 'CAMERA') &&
      _positivePermission(manifest, 'INTERNET');
}

bool _positivePermission(String manifest, String permission) {
  return RegExp(
    '<uses-permission\\s+android:name="android.permission.$permission"\\s*/>',
  ).hasMatch(manifest);
}

bool _hasNoForbiddenPermissions(String manifest) {
  return !RegExp(
    r'android:name="android.permission.(RECORD_AUDIO|WRITE_EXTERNAL_STORAGE)"',
  ).hasMatch(manifest);
}
