import 'package:askaide/helper/constant.dart';
import 'package:askaide/repo/api_server.dart';
import 'package:askaide/repo/model/model.dart' as mm;
import 'package:askaide/repo/openai_repo.dart';
import 'package:askaide/repo/settings_repo.dart';

/// Model aggregation, used to aggregate models from multiple vendors
class ModelAggregate {
  static late SettingRepository settings;

  static void init(SettingRepository settings) {
    ModelAggregate.settings = settings;
  }

  /// Supported model list
  static Future<List<mm.Model>> models() async {
    final List<mm.Model> models = [];
    final isAPIServerSet =
        settings.stringDefault(settingAPIServerToken, '') != '';
    final selfHostOpenAI = settings.boolDefault(settingOpenAISelfHosted, false);

    if (isAPIServerSet && !selfHostOpenAI) {
      models.addAll((await APIServer().models())
          .map(
            (e) => mm.Model(
              e.id.split(':').last,
              e.name,
              e.category,
              description: e.description,
              isChatModel: e.isChat,
              disabled: e.disabled,
              category: e.category,
              tag: e.tag,
            ),
          )
          .toList());
    } else {
      models.addAll(OpenAIRepository.supportModels());
    }

    // if (isAPIServerSet ||
    //     settings.stringDefault(settingDeepAIAPIToken, '') != '') {
    //   models.addAll(DeepAIRepository.supportModels());
    // }

    // TODO Replace with StabilityAI API
    // if (isAPIServerSet ||
    //     settings.stringDefault(settingStabilityAIAPIToken, '') != '') {
    //   models.addAll(StabilityAIRepository.supportModels());
    // }

    return models;
  }

  /// Find model by unique id
  static Future<mm.Model> model(String uid) async {
    if (uid.split(':').length == 1) {
      uid = '$modelTypeOpenAI:$uid';
    }

    final supportModels = await models();
    // if (uid.startsWith('$modelTypeOpenAI:')) {
    //   models.addAll(OpenAIRepository.supportModels());
    // }

    // if (uid.startsWith('$modelTypeDeepAI:')) {
    //   models.addAll(DeepAIRepository.supportModels());
    // }

    // if (uid.startsWith('$modelTypeStabilityAI:')) {
    //   models.addAll(StabilityAIRepository.supportModels());
    // }

    return supportModels.firstWhere(
      (element) => element.uid() == uid,
      orElse: () => mm.Model(defaultChatModel, defaultChatModel, 'openai',
          category: modelTypeOpenAI),
    );
  }
}