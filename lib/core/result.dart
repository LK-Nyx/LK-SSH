sealed class Result<T, E> {
  const Result();

  bool get isOk => this is Ok<T, E>;
  bool get isErr => this is Err<T, E>;

  T get value {
    if (this case Ok<T, E>(value: final v)) return v;
    throw StateError('Result.value called on Err — use when() instead');
  }

  E get error {
    if (this case Err<T, E>(error: final e)) return e;
    throw StateError('Result.error called on Ok — use when() instead');
  }

  R when<R>({
    required R Function(T value) ok,
    required R Function(E error) err,
  }) =>
      switch (this) {
        Ok<T, E>(value: final v) => ok(v),
        Err<T, E>(error: final e) => err(e),
      };
}

final class Ok<T, E> extends Result<T, E> {
  const Ok(this.value);
  @override
  final T value;
}

final class Err<T, E> extends Result<T, E> {
  const Err(this.error);
  @override
  final E error;
}
