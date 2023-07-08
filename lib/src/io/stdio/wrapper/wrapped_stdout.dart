import "dart:async";
import "dart:convert";
import "dart:io" as io;

final WrappedStdout stdout = WrappedStdout(io.stdout);
final WrappedStdout stderr = WrappedStdout(io.stderr);

class WrappedStdout implements io.Stdout {
  const WrappedStdout(this.stdout);

  final io.Stdout stdout;

  @override
  Encoding get encoding => stdout.encoding;

  @override
  set encoding(Encoding encoding) => stdout.encoding = encoding;

  @override
  void add(List<int> data) {
    stdout.add(data);
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) {
    stdout.addError(error, stackTrace);
  }

  @override
  bool get hasTerminal => stdout.hasTerminal;

  @override
  io.IOSink get nonBlocking => stdout.nonBlocking;

  @override
  bool get supportsAnsiEscapes => stdout.supportsAnsiEscapes;

  @override
  int get terminalColumns => stdout.terminalColumns;

  @override
  int get terminalLines => stdout.terminalLines;

  @override
  void write(Object? object) {
    stdout.write(object);
  }

  @override
  void writeAll(Iterable<dynamic> objects, [String sep = ""]) {
    stdout.writeAll(objects, sep);
  }

  @override
  void writeCharCode(int charCode) {
    stdout.writeCharCode(charCode);
  }

  @override
  void writeln([Object? object = ""]) {
    stdout.writeln(object);
  }

  void flush$() {
    unawaited(flush());
  }

  @override
  Future<dynamic> addStream(Stream<List<int>> stream) => stdout.addStream(stream);

  @override
  Future<dynamic> flush() => stdout.flush();

  @override
  Future<dynamic> close() => stdout.close();

  @override
  Future<dynamic> get done => stdout.done;
}
