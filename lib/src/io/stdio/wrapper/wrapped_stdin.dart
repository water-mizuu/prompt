import "dart:async";
import "dart:convert";
import "dart:io" as io;

final WrappedStdin stdin = WrappedStdin(io.stdin);

class WrappedStdin implements io.Stdin {
  const WrappedStdin(this.stdin);

  final io.Stdin stdin;

  @override
  bool get echoMode => stdin.echoMode;

  @override
  set echoMode(bool echoMode) => stdin.echoMode = echoMode;

  @override
  bool get echoNewlineMode => stdin.echoNewlineMode;

  @override
  set echoNewlineMode(bool echoNewlineMode) => stdin.echoNewlineMode = echoNewlineMode;

  @override
  bool get lineMode => stdin.lineMode;

  @override
  set lineMode(bool lineMode) => stdin.lineMode = lineMode;

  @override
  Future<bool> any(bool Function(List<int> element) test) => stdin.any(test);

  @override
  Stream<List<int>> asBroadcastStream({
    void Function(StreamSubscription<List<int>> subscription)? onListen,
    void Function(StreamSubscription<List<int>> subscription)? onCancel,
  }) =>
      stdin.asBroadcastStream(onListen: onListen, onCancel: onCancel);

  @override
  Stream<E> asyncExpand<E>(Stream<E>? Function(List<int> event) convert) =>
      stdin.asyncExpand(convert);

  @override
  Stream<E> asyncMap<E>(FutureOr<E> Function(List<int> event) convert) => stdin.asyncMap(convert);

  @override
  Stream<R> cast<R>() => stdin.cast<R>();

  @override
  Future<bool> contains(Object? needle) => stdin.contains(needle);

  @override
  Stream<List<int>> distinct([bool Function(List<int> previous, List<int> next)? equals]) =>
      stdin.distinct(equals);

  @override
  Future<E> drain<E>([E? futureValue]) => stdin.drain(futureValue);

  @override
  Future<List<int>> elementAt(int index) => stdin.elementAt(index);

  @override
  Future<bool> every(bool Function(List<int> element) test) => stdin.every(test);

  @override
  Stream<S> expand<S>(Iterable<S> Function(List<int> element) convert) => stdin.expand(convert);

  @override
  Future<List<int>> get first => stdin.first;

  @override
  Future<List<int>> firstWhere(
    bool Function(List<int> element) test, {
    List<int> Function()? orElse,
  }) =>
      stdin.firstWhere(test, orElse: orElse);

  @override
  Future<S> fold<S>(S initialValue, S Function(S previous, List<int> element) combine) =>
      stdin.fold(initialValue, combine);

  @override
  Future<void> forEach(void Function(List<int> element) action) => stdin.forEach(action);

  @override
  Stream<List<int>> handleError(Function onError, {bool Function(dynamic error)? test}) =>
      stdin.handleError(onError, test: test);

  @override
  bool get hasTerminal => stdin.hasTerminal;

  @override
  bool get isBroadcast => stdin.isBroadcast;

  @override
  Future<bool> get isEmpty => stdin.isEmpty;

  @override
  Future<String> join([String separator = ""]) => stdin.join(separator);

  @override
  Future<List<int>> get last => stdin.last;

  @override
  Future<List<int>> lastWhere(
    bool Function(List<int> element) test, {
    List<int> Function()? orElse,
  }) =>
      stdin.lastWhere(test, orElse: orElse);

  @override
  Future<int> get length => stdin.length;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) =>
      stdin.listen(
        onData,
        onError: onError,
        onDone: onDone,
        cancelOnError: cancelOnError,
      );

  @override
  Stream<S> map<S>(S Function(List<int> event) convert) => stdin.map(convert);

  @override
  Future<dynamic> pipe(StreamConsumer<List<int>> streamConsumer) => stdin.pipe(streamConsumer);

  @override
  int readByteSync() => stdin.readByteSync();

  @override
  String? readLineSync({Encoding encoding = io.systemEncoding, bool retainNewlines = false}) =>
      stdin.readLineSync(encoding: encoding, retainNewlines: retainNewlines);

  @override
  Future<List<int>> reduce(List<int> Function(List<int> previous, List<int> element) combine) =>
      stdin.reduce(combine);

  @override
  Future<List<int>> get single => stdin.single;

  @override
  Future<List<int>> singleWhere(
    bool Function(List<int> element) test, {
    List<int> Function()? orElse,
  }) =>
      stdin.singleWhere(test, orElse: orElse);

  @override
  Stream<List<int>> skip(int count) => stdin.skip(count);

  @override
  Stream<List<int>> skipWhile(bool Function(List<int> element) test) => stdin.skipWhile(test);

  @override
  bool get supportsAnsiEscapes => stdin.supportsAnsiEscapes;

  @override
  Stream<List<int>> take(int count) => stdin.take(count);

  @override
  Stream<List<int>> takeWhile(bool Function(List<int> element) test) => stdin.takeWhile(test);

  @override
  Stream<List<int>> timeout(
    Duration timeLimit, {
    void Function(EventSink<List<int>> sink)? onTimeout,
  }) =>
      stdin.timeout(timeLimit, onTimeout: onTimeout);

  @override
  Future<List<List<int>>> toList() => stdin.toList();

  @override
  Future<Set<List<int>>> toSet() => stdin.toSet();

  @override
  Stream<S> transform<S>(StreamTransformer<List<int>, S> streamTransformer) =>
      stdin.transform(streamTransformer);

  @override
  Stream<List<int>> where(bool Function(List<int> event) test) => stdin.where(test);
}
