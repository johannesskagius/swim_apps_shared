import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:swim_apps_shared/objects/user/coach.dart';
import 'package:swim_apps_shared/objects/user/user.dart';

class SupportController extends ChangeNotifier {
  final AppUser user;
  final bool isAccountHolder;
  final List<Coach> coaches;

  SupportController({
    required this.user,
    required this.isAccountHolder,
    required this.coaches,
  }) {
    _reportedForUserId = user.id;
    _reportedForName = user.name;
    loadClientMeta();
  }

  // ------------------------------------------------------------
  // STATE
  // ------------------------------------------------------------

  final TextEditingController messageController = TextEditingController();

  bool loading = false;

  final List<String> categories = const [
    'Bug / Technical Issue',
    'Feature Request',
    'Billing / Subscription',
    'Club Management',
    'Login / Account',
    'Other',
  ];

  String selectedCategory = 'Bug / Technical Issue';

  String? _reportedForUserId;
  String? _reportedForName;

  Map<String, dynamic> clientMeta = {};

  String? get reportedForUserId => _reportedForUserId;

  String? get reportedForUserName => _reportedForName;

  bool get canReportForOthers => isAccountHolder && coaches.isNotEmpty;

  // ------------------------------------------------------------
  // CLIENT META
  // ------------------------------------------------------------

  Future<void> loadClientMeta() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final deviceInfo = DeviceInfoPlugin();

    String platform = 'unknown';
    String deviceModel = 'unknown';
    String osVersion = 'unknown';

    if (kIsWeb) {
      platform = 'web';
      final info = await deviceInfo.webBrowserInfo;
      deviceModel = info.userAgent ?? 'browser';
      osVersion = info.appVersion ?? '';
    } else if (Platform.isAndroid) {
      platform = 'android';
      final info = await deviceInfo.androidInfo;
      deviceModel = '${info.manufacturer} ${info.model}';
      osVersion = 'Android ${info.version.release}';
    } else if (Platform.isIOS) {
      platform = 'ios';
      final info = await deviceInfo.iosInfo;
      deviceModel = info.utsname.machine;
      osVersion = '${info.systemName} ${info.systemVersion}';
    } else if (Platform.isMacOS) {
      platform = 'macos';
      final info = await deviceInfo.macOsInfo;
      deviceModel = info.model;
      osVersion = 'macOS ${info.osRelease}';
    }

    clientMeta = {
      'appVersion': packageInfo.version,
      'platform': platform,
      'deviceModel': deviceModel,
      'osVersion': osVersion,
    };

    notifyListeners();
  }

  // ------------------------------------------------------------
  // RICH TEXT HELPERS
  // ------------------------------------------------------------

  void wrapSelection(String prefix, String suffix) {
    final text = messageController.text;
    final selection = messageController.selection;

    if (!selection.isValid) return;

    final before = selection.textBefore(text);
    final selected = selection.textInside(text);
    final after = selection.textAfter(text);

    final newText = '$before$prefix$selected$suffix$after';
    final newSelectionStart = (before + prefix + selected + suffix).length;

    messageController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newSelectionStart),
    );
  }

  void insertBullet() {
    final text = messageController.text;
    final selection = messageController.selection;

    final before = selection.textBefore(text);
    final after = selection.textAfter(text);

    const insert = '\n- ';
    final newText = '$before$insert$after';

    messageController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: (before + insert).length),
    );
  }

  // ------------------------------------------------------------
  // ON BEHALF OF
  // ------------------------------------------------------------

  void selectReportedUser(String userId) {
    if (userId == user.id) {
      _reportedForUserId = user.id;
      _reportedForName = user.name;
    } else {
      final coach = coaches.firstWhere((c) => c.id == userId);
      _reportedForUserId = coach.id;
      _reportedForName = coach.name;
    }
    notifyListeners();
  }

  // ------------------------------------------------------------
  // SEND SUPPORT
  // ------------------------------------------------------------

  Future<String?> sendSupportRequest() async {
    final message = messageController.text.trim();

    if (message.isEmpty) {
      return "Please enter a message";
    }

    loading = true;
    notifyListeners();

    try {
      final callable = FirebaseFunctions.instanceFor(
        region: "europe-west1",
      ).httpsCallable("sendSupportRequest");

      final result = await callable.call({
        "userId": user.id,
        "email": user.email,
        "name": user.name,
        "role": user.userType.name,
        "message": message,
        "category": selectedCategory,
        "reportedForUserId": _reportedForUserId,
        "reportedForName": _reportedForName,
        "clientMeta": clientMeta,
      });

      if (result.data["success"] == true) {
        return null; // success
      } else {
        return result.data["message"] ?? "Unknown error";
      }
    } catch (e) {
      return e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void setCategory(String value) {
    selectedCategory = value;
    notifyListeners();
  }
}
