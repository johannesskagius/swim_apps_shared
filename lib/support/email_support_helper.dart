import 'dart:io' show Platform;

import 'package:swim_apps_shared/objects/user/user.dart';
import 'package:url_launcher/url_launcher.dart';

class EmailSupportHelper {
  static const String supportEmail = 'support@swim-suite.com';

  static Future<void> openSupportEmail({required AppUser user}) async {
    final platform = Platform.isIOS
        ? 'iOS'
        : Platform.isAndroid
        ? 'Android'
        : Platform.isMacOS
        ? 'macOS'
        : Platform.isWindows
        ? 'Windows'
        : Platform.isLinux
        ? 'Linux'
        : 'Unknown';

    final osVersion = Platform.operatingSystemVersion;

    final body =
        '''
Hello Swim-Suite Support 👋,

I need help with…

----------------------------------------
👤 User Info
----------------------------------------
Name: ${user.name}
Email: ${user.email}
User ID: ${user.id}
Role: ${user.userType.name}

----------------------------------------
📱 Device & App Info
----------------------------------------
Platform: $platform
OS Version: $osVersion

----------------------------------------
📝 Issue Description
----------------------------------------
1. What were you trying to do?

2. What went wrong?

3. Steps to reproduce:

----------------------------------------
📎 Additional Notes (optional)
----------------------------------------
''';

    final subject = 'Swim-Suite Support Request';

    // ⚠️ Must be encoded manually
    final Uri uri = Uri.parse(
      'mailto:$supportEmail'
      '?subject=${Uri.encodeComponent(subject)}'
      '&body=${Uri.encodeComponent(body)}',
    );

    // 🚀 Launch directly without checking canLaunch (iOS returns false incorrectly)
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
