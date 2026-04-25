import 'dart:typed_data';

final class SecureKey {
  SecureKey._(this._bytes);

  factory SecureKey.fromBytes(Uint8List bytes) =>
      SecureKey._(Uint8List.fromList(bytes));

  Uint8List _bytes;
  bool _disposed = false;

  bool get isDisposed => _disposed;

  Uint8List get bytes {
    if (_disposed) throw StateError('SecureKey accessed after zeroise()');
    return Uint8List.fromList(_bytes);
  }

  void zeroise() {
    _bytes.fillRange(0, _bytes.length, 0);
    _disposed = true;
  }
}
