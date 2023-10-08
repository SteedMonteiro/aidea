/// Server-supported capability information
class Capabilities {
  /// Whether Apple Pay is supported
  final bool applePayEnabled;

  /// Whether Alipay is supported
  final bool alipayEnabled;

  /// Whether translation is supported
  final bool translateEnabled;

  /// Whether email is supported
  final bool mailEnabled;

  /// Whether OpenAI is supported
  final bool openaiEnabled;

  /// Models information displayed on the home page
  final List<HomeModel> homeModels;

  Capabilities({
    required this.applePayEnabled,
    required this.alipayEnabled,
    required this.translateEnabled,
    required this.mailEnabled,
    required this.openaiEnabled,
    required this.homeModels,
  });

  factory Capabilities.fromJson(Map<String, dynamic> json) {
    return Capabilities(
      applePayEnabled: json['apple_pay_enabled'] ?? false,
      alipayEnabled: json['alipay_enabled'] ?? false,
      translateEnabled: json['translate_enabled'] ?? false,
      mailEnabled: json['mail_enabled'] ?? false,
      openaiEnabled: json['openai_enabled'] ?? false,
      homeModels: ((json['home_models'] ?? []) as List<dynamic>)
          .map((e) => HomeModel.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'apple_pay_enabled': applePayEnabled,
      'alipay_enabled': alipayEnabled,
      'translate_enabled': translateEnabled,
      'mail_enabled': mailEnabled,
      'openai_enabled': openaiEnabled,
      'home_models': homeModels.map((e) => e.toJson()).toList(),
    };
  }
}

/// Model information displayed on the home page
class HomeModel {
  /// Model name
  final String name;

  /// Model ID
  final String modelId;

  /// Model description
  final String desc;

  /// Model representative color
  final String color;

  /// Whether it is a powerful model
  final bool powerful;

  HomeModel({
    required this.name,
    required this.modelId,
    required this.desc,
    required this.color,
    this.powerful = false,
  });

  factory HomeModel.fromJson(Map<String, dynamic> json) => HomeModel(
        name: json["name"],
        modelId: json["model_id"],
        desc: json["desc"] ?? '',
        color: json["color"] ?? 'FF67AC5C',
        powerful: json['powerful'] ?? false,
      );

  Map<String, dynamic> toJson() => {
        "name": name,
        "model_id": modelId,
        "desc": desc,
        "color": color,
        "powerful": powerful,
      };
}