import 'package:askaide/helper/constant.dart';
import 'package:askaide/helper/platform.dart';
import 'package:askaide/repo/api/info.dart';
import 'package:askaide/repo/settings_repo.dart';

class Ability {
  late final SettingRepository setting;
  late final Capabilities capabilities;

  init(SettingRepository setting, Capabilities capabilities) {
    this.setting = setting;
    this.capabilities = capabilities;
  }

  /// Singleton
  static final Ability _instance = Ability._internal();
  Ability._internal();

  factory Ability() {
    return _instance;
  }

  /// List of supported models on the home page
  List<HomeModel> get homeModels {
    return capabilities.homeModels;
  }

  /// Whether OpenAI is supported
  bool get enableOpenAI {
    return capabilities.openaiEnabled;
  }

  /// Whether Alipay is supported
  bool get enableAlipay {
    return capabilities.alipayEnabled;
  }

  /// Whether ApplePay is supported
  bool get enableApplePay {
    return capabilities.applePayEnabled;
  }

  /// Whether payment is supported
  bool get enablePayment {
    if (!enableApplePay && !enableAlipay) {
      return false;
    }

    if (PlatformTool.isIOS() && enableApplePay) {
      return true;
    }

    return enableAlipay;
  }

  /// Whether API Server is supported
  bool supportAPIServer() {
    return setting.stringDefault(settingAPIServerToken, '') != '';
  }

  /// Whether OpenAI custom settings are enabled
  bool supportLocalOpenAI() {
    return setting.boolDefault(settingOpenAISelfHosted, false);
  }

  /// Whether translation is supported
  bool supportTranslate() {
    return false;
    // return setting.stringDefault(settingAPIServerToken, '') != '';
  }

  /// Whether text-to-speech is supported
  bool supportSpeak() {
    // return setting.stringDefault(settingAPIServerToken, '') != '';
    return true;
  }

  /// Whether image uploading is supported
  bool supportImageUploader() {
    return supportImglocUploader() || supportQiniuUploader();
  }

  /// Whether Imgloc image uploading is supported
  bool supportImglocUploader() {
    return setting.boolDefault(settingImageManagerSelfHosted, false) &&
        setting.stringDefault(settingImglocToken, '') != '';
  }

  /// Whether Qiniu image uploading is supported
  bool supportQiniuUploader() {
    return setting.stringDefault(settingAPIServerToken, '') != '';
  }
}