sealed class Result<T, E> {
  const Result();

  bool get isOk => this is Ok<T, E>;
  bool get isErr => this is Err<T, E>;

  T get value => (this as Ok<T, E>).value;
  E get error => (this as Err<T, E>).error;

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
