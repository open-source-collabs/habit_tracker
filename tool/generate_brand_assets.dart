// Regenerates every raster app icon from the AppLogoPainter brand mark.
//
// Run from the project root:
//   flutter test tool/generate_brand_assets.dart
//
// Outputs: assets/branding/png, Android legacy mipmaps, iOS AppIcon set,
// macOS AppIcon set, web icons + favicon, and the Windows .ico.
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/core/theme/app_colors.dart';
import 'package:habit_tracker/core/widgets/app_logo.dart';

/// Mark scale for unmasked full-bleed icons (iOS, web, store).
const double _fullScale = 1.4;

/// Mark scale inside the macOS-style rounded tile.
const double _roundedScale = 1.12;

const AppLogoPainter _full = AppLogoPainter(
  palette: AppLogoPalette.dusk,
  backdrop: AppLogoBackdrop.fullBleed,
  markScale: _fullScale,
);
const AppLogoPainter _fullDawn = AppLogoPainter(
  palette: AppLogoPalette.dawn,
  backdrop: AppLogoBackdrop.fullBleed,
  markScale: _fullScale,
);
const AppLogoPainter _maskable = AppLogoPainter(
  palette: AppLogoPalette.dusk,
  backdrop: AppLogoBackdrop.fullBleed,
);
const AppLogoPainter _rounded = AppLogoPainter(
  palette: AppLogoPalette.dusk,
  backdrop: AppLogoBackdrop.rounded,
  markScale: _roundedScale,
);
const AppLogoPainter _foreground = AppLogoPainter(palette: AppLogoPalette.dusk);
const AppLogoPainter _monochrome = AppLogoPainter(
  palette: AppLogoPalette.monochrome(AppColors.white),
);

void main() {
  testWidgets('generate brand assets', (tester) async {
    await tester.runAsync(() async {
      Future<void> png(
        AppLogoPainter painter,
        int px,
        String path, {
        bool alpha = false,
      }) async {
        final rgba = await _render(painter, px);
        _write(path, _encodePng(rgba, px, alpha: alpha));
      }

      // Brand masters.
      await png(_full, 1024, 'assets/branding/png/app_icon_1024.png');
      await png(_fullDawn, 1024, 'assets/branding/png/app_icon_dawn_1024.png');
      await png(
        _foreground,
        1024,
        'assets/branding/png/app_icon_foreground_1024.png',
        alpha: true,
      );
      await png(
        _monochrome,
        1024,
        'assets/branding/png/app_icon_monochrome_1024.png',
        alpha: true,
      );
      await png(_full, 512, 'assets/branding/store/play_store_icon_512.png');

      // Android legacy (pre-API 26) launcher bitmaps.
      const mipmaps = {
        'mdpi': 48,
        'hdpi': 72,
        'xhdpi': 96,
        'xxhdpi': 144,
        'xxxhdpi': 192,
      };
      for (final entry in mipmaps.entries) {
        await png(
          _rounded,
          entry.value,
          'android/app/src/main/res/mipmap-${entry.key}/ic_launcher.png',
          alpha: true,
        );
      }

      // iOS: opaque, no alpha channel (App Store requirement).
      const iosDir = 'ios/Runner/Assets.xcassets/AppIcon.appiconset';
      const ios = {
        'Icon-App-20x20@1x.png': 20,
        'Icon-App-20x20@2x.png': 40,
        'Icon-App-20x20@3x.png': 60,
        'Icon-App-29x29@1x.png': 29,
        'Icon-App-29x29@2x.png': 58,
        'Icon-App-29x29@3x.png': 87,
        'Icon-App-40x40@1x.png': 40,
        'Icon-App-40x40@2x.png': 80,
        'Icon-App-40x40@3x.png': 120,
        'Icon-App-60x60@2x.png': 120,
        'Icon-App-60x60@3x.png': 180,
        'Icon-App-76x76@1x.png': 76,
        'Icon-App-76x76@2x.png': 152,
        'Icon-App-83.5x83.5@2x.png': 167,
        'Icon-App-1024x1024@1x.png': 1024,
      };
      for (final entry in ios.entries) {
        await png(_full, entry.value, '$iosDir/${entry.key}');
      }

      // macOS.
      for (final px in [16, 32, 64, 128, 256, 512, 1024]) {
        await png(
          _rounded,
          px,
          'macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_$px.png',
          alpha: true,
        );
      }

      // Web / PWA.
      await png(_full, 32, 'web/favicon.png');
      await png(_full, 192, 'web/icons/Icon-192.png');
      await png(_full, 512, 'web/icons/Icon-512.png');
      await png(_maskable, 192, 'web/icons/Icon-maskable-192.png');
      await png(_maskable, 512, 'web/icons/Icon-maskable-512.png');

      // Windows: multi-resolution .ico with embedded PNGs.
      final icoImages = <int, Uint8List>{};
      for (final px in [16, 24, 32, 48, 64, 128, 256]) {
        icoImages[px] = _encodePng(
          await _render(_rounded, px),
          px,
          alpha: true,
        );
      }
      _write('windows/runner/resources/app_icon.ico', _encodeIco(icoImages));
    });
  });
}

Future<Uint8List> _render(AppLogoPainter painter, int px) async {
  final recorder = ui.PictureRecorder();
  painter.paint(Canvas(recorder), Size.square(px.toDouble()));
  final image = await recorder.endRecording().toImage(px, px);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.rawStraightRgba);
  image.dispose();
  return bytes!.buffer.asUint8List();
}

void _write(String path, List<int> bytes) {
  File(path)
    ..parent.createSync(recursive: true)
    ..writeAsBytesSync(bytes);
  // ignore: avoid_print
  print('wrote $path');
}

/// Minimal PNG encoder: 8-bit RGB (color type 2) or RGBA (color type 6).
Uint8List _encodePng(Uint8List rgba, int size, {required bool alpha}) {
  final channels = alpha ? 4 : 3;
  final raw = BytesBuilder(copy: false);
  for (var y = 0; y < size; y++) {
    final row = Uint8List(1 + size * channels); // filter byte 0 = none
    for (var x = 0; x < size; x++) {
      final src = (y * size + x) * 4;
      final dst = 1 + x * channels;
      row[dst] = rgba[src];
      row[dst + 1] = rgba[src + 1];
      row[dst + 2] = rgba[src + 2];
      if (alpha) row[dst + 3] = rgba[src + 3];
    }
    raw.add(row);
  }

  final header = ByteData(13)
    ..setUint32(0, size)
    ..setUint32(4, size)
    ..setUint8(8, 8)
    ..setUint8(9, alpha ? 6 : 2);

  final out = BytesBuilder(copy: false)
    ..add([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);
  _chunk(out, 'IHDR', header.buffer.asUint8List());
  _chunk(out, 'IDAT', ZLibEncoder(level: 9).convert(raw.takeBytes()));
  _chunk(out, 'IEND', const []);
  return out.takeBytes();
}

void _chunk(BytesBuilder out, String type, List<int> data) {
  final typeBytes = type.codeUnits;
  out
    ..add((ByteData(4)..setUint32(0, data.length)).buffer.asUint8List())
    ..add(typeBytes)
    ..add(data)
    ..add(
      (ByteData(4)..setUint32(0, _crc32([...typeBytes, ...data])))
          .buffer
          .asUint8List(),
    );
}

final List<int> _crcTable = List<int>.generate(256, (n) {
  var c = n;
  for (var k = 0; k < 8; k++) {
    c = (c & 1) != 0 ? 0xEDB88320 ^ (c >>> 1) : c >>> 1;
  }
  return c;
});

int _crc32(List<int> bytes) {
  var crc = 0xFFFFFFFF;
  for (final b in bytes) {
    crc = _crcTable[(crc ^ b) & 0xFF] ^ (crc >>> 8);
  }
  return crc ^ 0xFFFFFFFF;
}

/// ICO container holding PNG-compressed entries (Windows Vista+).
Uint8List _encodeIco(Map<int, Uint8List> images) {
  final header = ByteData(6 + 16 * images.length)
    ..setUint16(2, 1, Endian.little)
    ..setUint16(4, images.length, Endian.little);
  var offset = header.lengthInBytes;
  var i = 0;
  for (final entry in images.entries) {
    final e = 6 + 16 * i++;
    final dim = entry.key >= 256 ? 0 : entry.key;
    header
      ..setUint8(e, dim)
      ..setUint8(e + 1, dim)
      ..setUint16(e + 4, 1, Endian.little)
      ..setUint16(e + 6, 32, Endian.little)
      ..setUint32(e + 8, entry.value.length, Endian.little)
      ..setUint32(e + 12, offset, Endian.little);
    offset += entry.value.length;
  }
  final out = BytesBuilder(copy: false)..add(header.buffer.asUint8List());
  for (final png in images.values) {
    out.add(png);
  }
  return out.takeBytes();
}
