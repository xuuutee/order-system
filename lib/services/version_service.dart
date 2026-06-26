import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

class VersionInfo {
  final String currentVersion;
  final String? latestVersion;
  final String downloadUrl;
  final bool hasUpdate;

  const VersionInfo({
    required this.currentVersion,
    this.latestVersion,
    this.downloadUrl = '',
    this.hasUpdate = false,
  });
}

class VersionService {
  static const _serverUrl = 'http://123.207.255.76:9000';

  static Future<VersionInfo> check() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final current = 'v${packageInfo.version}';

      final response = await http.get(
        Uri.parse('$_serverUrl/update/version.json'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final latest = data['version'] as String? ?? '';
        final downloadUrl = '$_serverUrl/update/app-release.apk';

        if (latest.isNotEmpty && latest != current) {
          return VersionInfo(
            currentVersion: current,
            latestVersion: latest,
            downloadUrl: downloadUrl,
            hasUpdate: true,
          );
        }
      }
      return VersionInfo(currentVersion: current);
    } catch (_) {
      return VersionInfo(currentVersion: 'unknown');
    }
  }
}
