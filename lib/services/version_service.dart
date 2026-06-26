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
  static const _anonKey =
      'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJyb2xlIjoiYW5vbiIsImlzcyI6InN1cGFiYXNlIn0.tiSYBtsxALGOt22WxGEVpvzHN3lW6Sgs7AopMpeAfA0';

  /// 检查服务器上是否有新版本（通过 Kong → Python 文件服务器）
  static Future<VersionInfo> check() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final current = 'v${packageInfo.version}';

      // 从服务器获取最新版本信息
      final response = await http.get(
        Uri.parse('$_serverUrl/update/version.json'),
        headers: {'apikey': _anonKey},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final latestRaw = data['version'] as String? ?? '';
        // 去掉服务器版本号可能带的 'v' 前缀，与本地格式对齐
        final latest = latestRaw.startsWith('v') ? latestRaw.substring(1) : latestRaw;
        final downloadUrl = '$_serverUrl/update/app-release.apk';

        if (latest.isNotEmpty && latest != current) {
          return VersionInfo(
            currentVersion: current,
            latestVersion: latestRaw,
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
