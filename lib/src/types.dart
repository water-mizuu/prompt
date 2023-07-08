typedef Predicate<T> = bool Function(T value);

typedef ParseFunction<T> = T? Function(String source);
typedef GuardFunction<T> = bool Function(T value);

typedef Guard<T> = (GuardFunction<T>, String);
typedef Parser<T> = (ParseFunction<T>, String);

typedef List2<E> = List<List<E>>;

typedef Lazy<T> = T Function();
