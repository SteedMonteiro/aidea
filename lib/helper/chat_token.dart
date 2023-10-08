import 'package:askaide/helper/logger.dart';
import 'package:tiktoken/tiktoken.dart';

/// Calculate the number of tokens contained in the message
int tokenCount(String model, String message) {
  try {
    final encoding = encodingForModel(model);
    return encoding.encode(message).length;
  } catch (e) {
    Logger.instance.e(e);
    return -1;
  }
}