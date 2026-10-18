import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Installed app version, e.g. "1.0.0 (1)".
final appVersionProvider = FutureProvider<String>((ref) async {
  try {
    final info = await PackageInfo.fromPlatform();
    return '${info.version} (${info.buildNumber})';
  } catch (_) {
    return '';
  }
});

/// Opens [uri] outside the app (browser, mail app, store), telling the user
/// when nothing can handle it.
Future<void> openExternalLink(BuildContext context, Uri uri) async {
  final messenger = ScaffoldMessenger.of(context);
  var opened = false;
  try {
    opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    opened = false;
  }
  if (!opened) {
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          uri.scheme == 'mailto'
              ? 'No email app found. Write to ${uri.path}.'
              : "Couldn't open the link.",
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
