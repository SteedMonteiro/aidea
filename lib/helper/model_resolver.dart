import 'dart:io';

import 'package:askaide/helper/constant.dart';
import 'package:askaide/helper/error.dart';
import 'package:askaide/helper/helper.dart';
import 'package:askaide/repo/api_server.dart';
import 'package:askaide/repo/deepai_repo.dart';
import 'package:askaide/repo/model/message.dart';
import 'package:askaide/repo/model/room.dart';
import 'package:askaide/repo/openai_repo.dart';
import 'package:askaide/repo/stabilityai_repo.dart';
import 'package:dart_openai/openai.dart';

/// Call different API interfaces based on the chat type
class ModelResolver {
  late final OpenAIRepository openAIRepo;
  late final DeepAIRepository deepAIRepo;
  late final StabilityAIRepository stabilityAIRepo;

  /// Initialize and set the model implementation
  void init({
    required OpenAIRepository openAIRepo,
    required DeepAIRepository deepAIRepo,
    required StabilityAIRepository stabilityAIRepo,
  }) {
    this.openAIRepo = openAIRepo;
    this.deepAIRepo = deepAIRepo;
    this.stabilityAIRepo = stabilityAIRepo;
  }

  ModelResolver._();
  static final instance = ModelResolver._();

  /// Convert audio to text
  Future<String> audioToText(File file) async {
    try {
      return await openAIRepo.audioTranscription(audioFile: file);
    } catch (error) {
      throw resolveErrorMessage(error);
    }
  }

  /// Send chat request
  Future request({
    required Room room,
    required List<Message> contextMessages,
    required Function(ChatStreamRespData value) onMessage,
    int? maxTokens,
  }) async {
    if (room.modelCategory() == modelTypeDeepAI) {
      return await _deepAIModel(
        room: room,
        message: contextMessages.last,
        contextMessages: contextMessages,
        onMessage: (value) {
          onMessage(ChatStreamRespData(content: value));
        },
      );
    } else if (room.modelCategory() == modelTypeStabilityAI) {
      return await _stabilityAIModel(
        room: room,
        message: contextMessages.last,
        contextMessages: contextMessages,
        onMessage: (value) {
          onMessage(ChatStreamRespData(content: value));
        },
      );
    } else {
      return await _openAIModel(
        room: room,
        contextMessages: contextMessages,
        onMessage: onMessage,
        maxTokens: maxTokens,
      );
    }
  }

  /// Call StabilityAI API
  Future<void> _stabilityAIModel({
    required Room room,
    required Message message,
    required List<Message> contextMessages,
    required Function(String value) onMessage,
  }) async {
    if (stabilityAIRepo.selfHosted) {
      var res = await stabilityAIRepo.createImageBase64(
        room.modelName(),
        [StabilityAIPrompt(message.text, 0.5)],
      );

      for (var data in res) {
        var path = await writeImageFromBase64(data, 'png');
        // print('Image path: $path');
        onMessage('\n![image]($path)\n');
      }
    } else {
      var taskId = await stabilityAIRepo.createImageBase64Async(
        room.modelName(),
        [StabilityAIPrompt(message.text, 0.5)],
      );

      await Future.delayed(const Duration(seconds: 10));
      await _waitForTasks(taskId, onMessage);
    }
  }

  Future<void> _waitForTasks(
    String taskId,
    Function(String value) onMessage, {
    int retry = 0,
  }) async {
    var res = await APIServer().asyncTaskStatus(taskId);
    if (res.status == 'success') {
      for (var data in res.resources!) {
        onMessage('\n![image]($data)\n');
      }
    } else if (res.status == 'failed') {
      throw 'Response failed: ${res.errors!.join("\n")}';
    } else {
      if (retry > 10) {
        throw 'Response timeout';
      }

      await Future.delayed(const Duration(seconds: 5));
      await _waitForTasks(taskId, onMessage, retry: retry + 1);
    }
  }

  /// Call DeepAI API
  Future<void> _deepAIModel({
    required Room room,
    required Message message,
    required List<Message> contextMessages,
    required Function(String value) onMessage,
  }) async {
    if (deepAIRepo.selfHosted) {
      var res = await deepAIRepo.painting(room.modelName(), message.text);
      onMessage('\n![${res.id}](${res.url})\n');
    } else {
      var taskId =
          await deepAIRepo.paintingAsync(room.modelName(), message.text);
      await Future.delayed(const Duration(seconds: 10));
      await _waitForTasks(taskId, onMessage);
    }
  }

  /// Call OpenAI API
  Future<void> _openAIModel({
    required Room room,
    required List<Message> contextMessages,
    required Function(ChatStreamRespData value) onMessage,
    int? maxTokens,
  }) async {
    // Image mode
    if (OpenAIRepository.isImageModel(room.modelName())) {
      var res = await openAIRepo.createImage(contextMessages.last.text, n: 2);
      for (var url in res) {
        onMessage(ChatStreamRespData(content: '\n![image]($url)\n'));
      }

      return;
    }

    // Chat model
    return await openAIRepo.chatStream(
      _buildRequestContext(room, contextMessages),
      onMessage,
      model: room.modelName(),
      maxTokens: maxTokens,
      roomId: room.isLocalRoom ? null : room.id,
    );
  }

  /// Build the request context for the chatbot
  List<OpenAIChatCompletionChoiceMessageModel> _buildRequestContext(
    Room room,
    List<Message> messages,
  ) {
    // // Messages within N hours as a context
    // var recentMessages = messages
    //     .where((e) => e.ts!.millisecondsSinceEpoch > lastAliveTime())
    //     .toList();
    var recentMessages = messages.toList();
    int contextBreakIndex = recentMessages.lastIndexWhere((element) =>
        element.isSystem() && element.type == MessageType.contextBreak);

    if (contextBreakIndex > -1) {
      recentMessages = recentMessages.sublist(contextBreakIndex + 1);
    }

    var contextMessages = recentMessages
        .where((e) => !e.isSystem() && !e.isInitMessage())
        .where((e) => !e.statusIsFailed())
        .map((e) => e.role == Role.receiver
            ? OpenAIChatCompletionChoiceMessageModel(
                role: OpenAIChatMessageRole.assistant, content: e.text)
            : OpenAIChatCompletionChoiceMessageModel(
                role: OpenAIChatMessageRole.user, content: e.text))
        .toList();

    if (contextMessages.length > room.maxContext * 2) {
      contextMessages =
          contextMessages.sublist(contextMessages.length - room.maxContext * 2);
    }

    if (room.systemPrompt != null && room.systemPrompt != '') {
      contextMessages.insert(
        0,
        OpenAIChatCompletionChoiceMessageModel(
          role: OpenAIChatMessageRole.system,
          content: room.systemPrompt!,
        ),
      );
    }

    return contextMessages;
  }
}