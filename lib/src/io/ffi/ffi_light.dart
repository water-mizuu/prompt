// ignore_for_file: always_specify_types

import "dart:ffi";
import "dart:io";

// Note that ole32.dll is the correct name in both 32-bit and 64-bit.
final DynamicLibrary stdlib =
    Platform.isWindows ? DynamicLibrary.open("ole32.dll") : DynamicLibrary.process();

typedef PosixCallocNative = Pointer Function(IntPtr num, IntPtr size);
typedef PosixCalloc = Pointer Function(int num, int size);
final PosixCalloc posixCalloc = stdlib.lookupFunction<PosixCallocNative, PosixCalloc>("calloc");

typedef PosixFreeNative = Void Function(Pointer);
typedef PosixFree = void Function(Pointer);
final PosixFree posixFree = stdlib.lookupFunction<PosixFreeNative, PosixFree>("free");

typedef WinCoTaskMemAllocNative = Pointer Function(Size cb);
typedef WinCoTaskMemAlloc = Pointer Function(int cb);
final WinCoTaskMemAlloc winCoTaskMemAlloc =
    stdlib.lookupFunction<WinCoTaskMemAllocNative, WinCoTaskMemAlloc>(
  "CoTaskMemAlloc",
);

typedef WinCoTaskMemFreeNative = Void Function(Pointer pv);
typedef WinCoTaskMemFree = void Function(Pointer pv);
final WinCoTaskMemFree winCoTaskMemFree =
    stdlib.lookupFunction<WinCoTaskMemFreeNative, WinCoTaskMemFree>("CoTaskMemFree");

/// Manages memory on the native heap.
///
/// Initializes newly allocated memory to zero.
///
/// For POSIX-based systems, this uses `calloc` and `free`. On Windows, it uses
/// `CoTaskMemAlloc` and `CoTaskMemFree`.
class _CallocAllocator implements Allocator {
  const _CallocAllocator();

  /// Fills a block of memory with a specified value.
  void _fillMemory(Pointer destination, int length, int fill) {
    var ptr = destination.cast<Uint8>();
    for (var i = 0; i < length; i++) {
      ptr[i] = fill;
    }
  }

  /// Fills a block of memory with zeros.
  ///
  void _zeroMemory(Pointer destination, int length) => _fillMemory(destination, length, 0);

  /// Allocates [byteCount] bytes of zero-initialized of memory on the native
  /// heap.
  ///
  /// For POSIX-based systems, this uses `malloc`. On Windows, it uses
  /// `CoTaskMemAlloc`.
  ///
  /// Throws an [ArgumentError] if the number of bytes or alignment cannot be
  /// satisfied.
  @override
  Pointer<T> allocate<T extends NativeType>(int byteCount, {int? alignment}) {
    Pointer<T> result;
    if (Platform.isWindows) {
      result = winCoTaskMemAlloc(byteCount).cast();
    } else {
      result = posixCalloc(byteCount, 1).cast();
    }
    if (result.address == 0) {
      throw ArgumentError("Could not allocate $byteCount bytes.");
    }
    if (Platform.isWindows) {
      _zeroMemory(result, byteCount);
    }
    return result;
  }

  /// Releases memory allocated on the native heap.
  ///
  /// For POSIX-based systems, this uses `free`. On Windows, it uses
  /// `CoTaskMemFree`. It may only be used against pointers allocated in a
  /// manner equivalent to [allocate].
  @override
  void free(Pointer pointer) {
    if (Platform.isWindows) {
      winCoTaskMemFree(pointer);
    } else {
      posixFree(pointer);
    }
  }
}

/// Manages memory on the native heap.
///
/// For POSIX-based systems, this uses `calloc` and `free`. On Windows, it uses
/// `CoTaskMemAlloc` and `CoTaskMemFree`.
const Allocator calloc = _CallocAllocator();
