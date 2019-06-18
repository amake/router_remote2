import 'dart:async';

class Debounce<S> extends StreamTransformerBase<S, S> {
  final Duration delay;

  Debounce([this.delay = const Duration(milliseconds: 1000)]);

  @override
  Stream<S> bind(Stream<S> stream) =>
      Stream.eventTransformed(stream, (sink) => TimerSink(delay, sink));
}

class TimerSink<T> extends EventSink<T> {
  final Duration delay;
  final EventSink<T> outSink;

  TimerSink(this.delay, this.outSink);

  Timer _timer;

  @override
  void add(T event) {
    _timer?.cancel();
    _timer = Timer(delay, () => outSink.add(event));
  }

  @override
  void close() {
    _timer?.cancel();
    outSink.close();
  }

  @override
  void addError(Object error, [StackTrace stackTrace]) {
    outSink.addError(error, stackTrace);
  }
}
