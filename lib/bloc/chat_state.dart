part of 'chat_message_bloc.dart';

@immutable
abstract class ChatMessageState {}

class ChatMessageInitial extends ChatMessageState {}

// Load all chat records
class ChatMessagesLoaded extends ChatMessageState {
  final List<Message> _messages;
  final bool processing;
  final Object? _error;
  final ChatHistory? chatHistory;

  ChatMessagesLoaded(
    this._messages, {
    Object? error,
    this.processing = false,
    this.chatHistory,
  }) : _error = error;

  get messages => _messages;
  get error => _error;
}

class ChatMessageError extends ChatMessageState {
  final String message;

  ChatMessageError(this.message);
}

class ChatMessageUpdated extends ChatMessageState {
  final Message message;

  /// Whether new messages are being processed
  final bool processing;

  ChatMessageUpdated(this.message, {this.processing = false});
}

class ChatAnywhereInited extends ChatMessageState {
  final int chatId;

  ChatAnywhereInited(this.chatId);
}