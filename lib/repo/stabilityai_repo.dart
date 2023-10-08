import 'dart:convert';
import 'package:askaide/helper/constant.dart';
import 'package:askaide/helper/platform.dart';
import 'package:askaide/repo/data/settings_data.dart';
import 'package:http/http.dart' as http;

/// StabilityAI Model
class StabilityAIRepository {
  final SettingDataProvider settings;

  late String serverURL;
  late String apiKey;
  late String organization;
  late String language;

  late bool selfHosted;

  Map<String, String> _headers = {};

  StabilityAIRepository(this.settings) {
    selfHosted = settings.getDefaultBool(settingStabilityAISelfHosted, false);
    language = settings.getDefault(settingLanguage, 'zh');

    _reloadServerConfig();

    settings.listen((settings, key, value) {
      selfHosted = settings.getDefaultBool(settingStabilityAISelfHosted, false);
      language = settings.getDefault(settingLanguage, 'zh');

      _reloadServerConfig();
    });
  }

  void _reloadServerConfig() {
    if (selfHosted) {
      serverURL =
          settings.getDefault(settingStabilityAIURL, defaultStabilityAIURL);
      organization = settings.getDefault(settingStabilityAIOrganization, '');
      apiKey = settings.getDefault(settingStabilityAIAPIToken, '');

      _headers = {};
    } else {
      apiKey = settings.getDefault(settingAPIServerToken, '');
      organization = "";
      serverURL = apiServerURL;

      _headers = {
        'X-CLIENT-VERSION': clientVersion,
        'X-PLATFORM': PlatformTool.operatingSystem(),
        'X-PLATFORM-VERSION': PlatformTool.operatingSystemVersion(),
        'X-LANGUAGE': language,
      };
    }
  }

  /// Create request headers
  Map<String, String> _buildRequestHeaders() {
    var headers = <String, String>{
      'Authorization': 'Bearer $apiKey',
    };

    headers.addAll(_headers);

    if (organization.isNotEmpty) {
      headers['Organization'] = organization;
    }

    return headers;
  }

  /// Default model list
  // static List<Model> supportModels() {
  //   return [
  //     // Model(
  //     //   'esrgan-v1-x2plus',
  //     //   modelTypeStabilityAI,
  //     //   category: modelTypeStabilityAI,
  //     //   description: 'Real-ESRGAN_x2plus upscaler model',
  //     // ),
  //     Model(
  //       'stable-diffusion-v1',
  //       modelTypeStabilityAI,
  //       category: modelTypeStabilityAI,
  //       description: 'Stability-AI Stable Diffusion v1.4',
  //     ),
  //     Model(
  //       'stable-diffusion-v1-5',
  //       modelTypeStabilityAI,
  //       category: modelTypeStabilityAI,
  //       description: 'Stability-AI Stable Diffusion v1.5',
  //     ),
  //     Model(
  //       'stable-diffusion-512-v2-0',
  //       modelTypeStabilityAI,
  //       category: modelTypeStabilityAI,
  //       description: 'Stability-AI Stable Diffusion v2.0',
  //     ),
  //     Model(
  //       'stable-diffusion-768-v2-0',
  //       modelTypeStabilityAI,
  //       category: modelTypeStabilityAI,
  //       description: 'Stability-AI Stable Diffusion 768 v2.0',
  //     ),
  //     Model(
  //       'stable-diffusion-512-v2-1',
  //       modelTypeStabilityAI,
  //       category: modelTypeStabilityAI,
  //       description: 'Stability-AI Stable Diffusion v2.1',
  //     ),
  //     Model(
  //       'stable-diffusion-768-v2-1',
  //       modelTypeStabilityAI,
  //       category: modelTypeStabilityAI,
  //       description: 'Stability-AI Stable Diffusion 768 v2.1',
  //     ),
  //     Model(
  //       'stable-diffusion-xl-beta-v2-2-2',
  //       modelTypeStabilityAI,
  //       category: modelTypeStabilityAI,
  //       description: 'Stability-AI Stable Diffusion XL Beta v2.2.2',
  //     ),
  //     // Model(
  //     //   'stable-inpainting-v1-0',
  //     //   modelTypeStabilityAI,
  //     //   category: modelTypeStabilityAI,
  //     //   description: 'Stability-AI Stable Inpainting v1.0',
  //     // ),
  //     // Model(
  //     //   'stable-inpainting-512-v2-0',
  //     //   modelTypeStabilityAI,
  //     //   category: modelTypeStabilityAI,
  //     //   description: 'Stability-AI Stable Inpainting v2.0',
  //     // ),
  //   ];
  // }

  /// Query model list
  // Future<List<Model>> models() async {
  //   var resp = await http.get(
  //     Uri.parse('$serverURL/v1/engines/list'),
  //     headers: <String, String>{
  //       'Accept': 'application/json',
  //     }..addAll(_buildRequestHeaders()),
  //   );

  //   if (resp.statusCode != 200) {
  //     return Future.error('Failed to load models: ${resp.body}');
  //   }

  //   var models = <Model>[];
  //   for (var item in jsonDecode(resp.body) as List) {
  //     if ((item['type'] as String).toLowerCase() != 'picture') {
  //       print(item);
  //       continue;
  //     }

  //     models.add(Model(
  //       item['id'],
  //       modelTypeStabilityAI,
  //       category: modelTypeStabilityAI,
  //       description: item['description'],
  //     ));
  //   }

  //   return models;
  // }

  /// Create image and return the base64 encoding of the image
  /// Different models have different pricing: https://platform.stability.ai/docs/getting-started/credits-and-billing#pricing-table
  /// width,height+steps+engine determine the price
  Future<List<String>> createImageBase64(
    String engine,
    List<StabilityAIPrompt> prompts, {
    int width = 0,
    int height = 0,
    int cfgScale = 7,
    int samples = 1,
    int seed = 0,
    int steps = 30,
    // 3d-model analog-film anime cinematic comic-book digital-art enhance fantasy-art
    // isometric line-art low-poly modeling-compound neon-punk origami photographic
    // pixel-art tile-texture
   