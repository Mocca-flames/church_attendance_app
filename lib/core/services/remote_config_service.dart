import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:church_attendance_app/core/network/api_constants.dart';

class RemoteConfigService {
  static final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;

  static Future<void> initialize() async {
    await _remoteConfig.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: const Duration(minutes: 30),
      ),
    );

    await _remoteConfig.setDefaults({
      'api_base_url': 'UNSET',
    });

    try {
      await _remoteConfig.fetchAndActivate();
    } catch (e) {
      // If fetch fails, fallback to ApiConstants.baseUrl at call site
    }
  }

  static String get apiBaseUrl {
    final value = _remoteConfig.getString('api_base_url');
    return value == 'UNSET' ? ApiConstants.baseUrl : value;
  }
}
