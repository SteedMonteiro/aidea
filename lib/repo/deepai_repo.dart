import 'dart:convert';

import 'package:askaide/helper/constant.dart';
import 'package:askaide/helper/platform.dart';
import 'package:askaide/repo/data/settings_data.dart';
import 'package:http/http.dart' as http;

class DeepAIRepository {
  late String serverURL;
  late String apiKey;
  late bool selfHosted;

  Map<String, String> _headers = {};
  late String language;

  final SettingDataProvider settings;

  DeepAIRepository(this.settings) {
    selfHosted = settings.getDefaultBool(settingDeepAISelfHosted, false);
    language = settings.getDefault(settingLanguage, 'en');

    _reloadServerConfig();

    settings.listen((settings, key, value) {
      selfHosted = settings.getDefaultBool(settingDeepAISelfHosted, false);
      language = settings.getDefault(settingLanguage, 'en');

      _reloadServerConfig();
    });
  }

  void _reloadServerConfig() {
    if (selfHosted) {
      serverURL = settings.getDefault(settingDeepAIURL, defaultDeepAIServerURL);
      apiKey = settings.getDefault(settingDeepAIAPIToken, '');
      _headers = {};
    } else {
      apiKey = settings.getDefault(settingAPIServerToken, '');
      serverURL = apiServerURL;

      _headers = {
        'X-CLIENT-VERSION': clientVersion,
        'X-PLATFORM': PlatformTool.operatingSystem(),
        'X-PLATFORM-VERSION': PlatformTool.operatingSystemVersion(),
        'X-LANGUAGE': language,
      };
    }
  }

  // static List<Model> supportModels() {
  //   return [
  //     Model(
  //       'text2img',
  //       'deepai',
  //       category: modelTypeDeepAI,
  //       description: 'Generate images based on text description',
  //     ),
  //     Model(
  //       'cute-creature-generator',
  //       'deepai',
  //       category: modelTypeDeepAI,
  //       description: 'Generate cute animal images',
  //     ),
  //     Model(
  //       'fantasy-world-generator',
  //       'deepai',
  //       category: modelTypeDeepAI,
  //       description: 'Generate fantasy world images',
  //     ),
  //     Model(
  //       'cyberpunk-generator',
  //       'deepai',
  //       category: modelTypeDeepAI,
  //       description: 'Generate futuristic cyberpunk images',
  //     ),
  //     Model(
  //       'anime-portrait-generator',
  //       'deepai',
  //       category: modelTypeDeepAI,
  //       description: 'Generate anime character images',
  //     ),
  //     Model(
  //       'old-style-generator',
  //       'deepai',
  //       category: modelTypeDeepAI,
  //       description: 'Generate vintage style images',
  //     ),
  //     Model(
  //       'renaissance-painting-generator',
  //       'deepai',
  //       category: modelTypeDeepAI,
  //       description: 'Generate renaissance style images',
  //     ),
  //     Model(
  //       'abstract-painting-generator',
  //       'deepai',
  //       category: modelTypeDeepAI,
  //       description: 'Generate abstract style images',
  //     ),
  //     Model(
  //       'impressionism-painting-generator',
  //       'deepai',
  //       category: modelTypeDeepAI,
  //       description: 'Generate impressionism style images',
  //     ),
  //     Model(
  //       'surreal-graphics-generator',
  //       'deepai',
  //       category: modelTypeDeepAI,
  //       description: 'Generate surreal style images',
  //     ),
  //     Model(
  //       '3d-objects-generator',
  //       'deepai',
  //       category: modelTypeDeepAI,
  //       description: 'Generate 3D object images',
  //     ),
  //     Model(
  //       'origami-3d-generator',
  //       'deepai',
  //       category: modelTypeDeepAI,
  //       description: 'Generate origami style images',
  //     ),
  //     Model(
  //       'hologram-3d-generator',
  //       'deepai',
  //       category: modelTypeDeepAI,
  //       description: 'Generate hologram images',
  //     ),
  //     Model(
  //       '3d-character-generator',
  //       'deepai',
  //       category: modelTypeDeepAI,
  //       description: 'Generate 3D character images',
  //     ),
  //     Model(
  //       'watercolor-painting-generator',
  //       'deepai',
  //       category: modelTypeDeepAI,
  //       description: 'Generate watercolor style images',
  //     ),
  //     Model(
  //       'pop-art-generator',
  //       'deepai',
  //       category: modelTypeDeepAI,
  //       description: 'Generate pop art style images',
  //     ),
  //     Model(
  //       'contemporary-architecture-generator',
  //       'deepai',
  //       category: modelTypeDeepAI,
  //       description: 'Generate modern architecture images',
  //     ),
  //     Model(
  //       'future-architecture-generator',
  //       'deepai',
  //       category: modelTypeDeepAI,
  //       description: 'Generate futuristic architecture images',
  //     ),
  //     Model(
  //       'watercolor-architecture-generator',
  //       'deepai',
  //       category: modelTypeDeepAI,
  //       description: 'Generate watercolor architecture images',
  //     ),
  //     Model(
  //       'fantasy-character-generator',
  //       'deepai',
  //       category: modelTypeDeepAI,
  //       description: 'Generate fantasy character images',
  //     ),
  //     Model(
  //       'steampunk-generator',
  //       'deepai',
  //       category: modelTypeDeepAI,
  //       description: 'Generate steampunk style images',
  //     ),
  //     Model(
  //       'logo-generator',
  //       'deepai',
  //       category: modelTypeDeepAI,
  //       description: 'Generate logo images',
  //     ),
  //     Model(
  //       'pixel-art-generator',
  //       'deepai',
  //       category: modelTypeDeepAI,
  //       description: 'Generate pixel art style images',
  //     ),
  //     Model(
  //       'street-art-generator',
  //       'deepai',
  //       category: modelTypeDeepAI,
  //       description: 'Generate street art style images',
  //     ),
  //     Model(
  //       'surreal-portrait-generator',
  //       'deepai',
  //       category: modelTypeDeepAI,
  //       description: 'Generate surreal portrait images',
  //     ),
  //     Model(
  //       'anime-world-generator',
  //       'deepai',
  //       category: modelTypeDeepAI,
  //       description: 'Generate anime world images',
  //     ),
  //     Model(
  //       'fantasy-portrait-generator',
  //       'deepai',
  //       category: modelTypeDeepAI,
  //       description: 'Generate fantasy portrait images',
  //     ),
  //     Model(
  //       'comics-portrait-generator',
  //       'deepai',
  //       category: modelTypeDeepAI,
  //       description: 'Generate comics portrait images',
  //     ),
  //     Model(
  //       'cyberpunk-portrait-generator',
 //       'deepai',
  //       category: modelTypeDeepAI,
  //       description: 'Generate futuristic sci-fi character images',
  //     ),
  //   ];
  // }

  Future<DeepAIPaintResult> painting(
    String model,
    String prompt, {
    int gridSize = 1,
    int width = 512,
    int height = 512,
    String? negativePrompt,
  }) async {
    var params = <String, dynamic>{
      "text": prompt,
      "grid_size": gridSize.toString(),
      "width": width.toString(),
      "height": height.toString(),
    };
    if (negativePrompt != null) {
      params['negative_prompt'] = negativePrompt;
    }

    var url = selfHosted
        ? Uri.parse('$serverURL/api/$model')
        : Uri.parse('$serverURL/v1/deepai/images/$model/text-to-image');

    var headers = <String, String>{};
    headers.addAll(_headers);
    if (selfHosted) {
      headers['api-key'] = apiKey;
    } else {
      headers['Authorization'] = 'Bearer $apiKey';
    }

    var resp = await http.post(
      url,
      body: params,
      headers: headers,
    );

    if (resp.statusCode != 200) {
      return Future.error((resp.body as Map<String, dynamic>)['error']);
    }

    var ret = jsonDecode(resp.body) as Map<String, dynamic>;

    return Future.value(DeepAIPaintResult(ret['id'], ret['output_url']));
  }

  Future<String> paintingAsync(
    String model,
    String prompt, {
    int gridSize = 1,
    int width = 512,
    int height = 512,
    String? negativePrompt,
  }) async {
    var params = <String, dynamic>{
      "text": prompt,
      "grid_size": gridSize.toString(),
      "width": width.toString(),
      "height": height.toString(),
    };
    if (negativePrompt != null) {
      params['negative_prompt'] = negativePrompt;
    }

    var url =
        Uri.parse('$serverURL/v1/deepai/images/$model/text-to-image-async');

    var headers = <String, String>{};
    headers.addAll(_headers);
    headers['Authorization'] = 'Bearer $apiKey';

    var resp = await http.post(
      url,
      body: params,
      headers: headers,
    );

    if (resp.statusCode != 200) {
      return Future.error((resp.body as Map<String, dynamic>)['error']);
    }

    return Future.value(jsonDecode(resp.body)['task_id']);
  }
}

class DeepAIPaintResult {
  final String id;
  final String url;

  DeepAIPaintResult(this.id, this.url);
}
