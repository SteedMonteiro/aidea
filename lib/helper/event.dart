class GlobalEvent {
  /// Singleton
  static final GlobalEvent _instance = GlobalEvent._internal();
  GlobalEvent._internal();

  factory GlobalEvent() {
    return _instance;
  }

  /// Event listeners
  final Map<String, List<Function(dynamic data)>> _listeners = {};

  /// Listen to an event
  void on(String event, Function(dynamic data) callback) {
    if (_listeners[event] == null) {
      _listeners[event] = [];
    }

    _listeners[event]!.add(callback);
  }

  /// Trigger an event
  void emit(String event, [dynamic data]) {
    if (_listeners[event] == null) {
      return;
    }

    for (var callback in _listeners[event]!) {
      callback(data);
    }
  }
}