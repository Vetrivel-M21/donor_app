class AppVersionInfo {
  final String latestVersion;
  final int versionCode;
  final String minSupportedVersion;
  final int minVersionCode;
  final bool forceUpdate;
  final String updateTitle;
  final String updateMessage;
  final String storeUrl;

  const AppVersionInfo({
    required this.latestVersion,
    required this.versionCode,
    required this.minSupportedVersion,
    required this.minVersionCode,
    required this.forceUpdate,
    required this.updateTitle,
    required this.updateMessage,
    required this.storeUrl,
  });

  factory AppVersionInfo.fromJson(Map<String, dynamic> json) {
    return AppVersionInfo(
      latestVersion: json['latest_version']?.toString() ?? '1.0.0',
      versionCode: json['version_code'] is int ? json['version_code'] : (int.tryParse('${json['version_code']}') ?? 1),
      minSupportedVersion: json['min_supported_version']?.toString() ?? '1.0.0',
      minVersionCode: json['min_version_code'] is int ? json['min_version_code'] : (int.tryParse('${json['min_version_code']}') ?? 1),
      forceUpdate: json['force_update'] == true,
      updateTitle: json['update_title']?.toString() ?? 'Update Available',
      updateMessage: json['update_message']?.toString() ?? 'A new update is available on Google Play.',
      storeUrl: json['store_url']?.toString() ?? 'https://play.google.com/store/apps/details?id=in.armssinfo.trust_donor_app',
    );
  }
}
