import 'dart:async';
import 'dart:collection';

/// This queue passes the elements in the queue to the callback function at regular time intervals, achieving smooth queue processing.
class GracefulQueue<T> {
  final Queue<T> _queue = Queue<T>();
  bool finished = false;
  Timer? _timer;

  void add(T item) {
    _queue.add(item);
  }

  void dispose() {
    _timer?.cancel();
  }

  Future<void> listen(
      Duration duration, Function(List<T> items) callback) async {
    Completer<void> completer = Completer<void>();
    _timer = Timer.periodic(duration, (timer) {
      if (_queue.isNotEmpty) {
        List<T> items = [];
        for (var i = 0; i < _queue.length; i++) {
          items.add(_queue.removeFirst());
        }

        callback(items);
      } else if (finished) {
        // print(_queue.length);
        timer.cancel();
        completer.complete();
      }
    });

    return completer.future;
  }

  void finish() {
    finished = true;
  }
}