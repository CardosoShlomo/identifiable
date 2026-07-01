mixin Identifiable<I> {
  I get id;

  bool hasSameId(Identifiable<I> other) => id == other.id;

  bool isSameAs(Identifiable<I> other) =>
      runtimeType == other.runtimeType && id == other.id;
}

typedef Identity = Identifiable<String>;

typedef IdentifiableMap<K, E extends Identifiable<K>> = Map<K, E>;

typedef IdentityMap<T extends Identity> = Map<String, T>;

extension IdentifiableIterable<T extends Identifiable<I>, I> on Iterable<T> {
  bool includes(T item) => any(item.isSameAs);

  bool includesId(I id) => any((e) => e.id == id);

  bool overlaps(Iterable<T> others) => any(others.includes);

  T? byId(I id) {
    for (final item in this) {
      if (item.id == id) return item;
    }
    return null;
  }

  Iterable<T> withoutId(I id) => where((e) => e.id != id);

  List<T> updateById(I id, T Function(T current) update) =>
      [for (final item in this) item.id == id ? update(item) : item];

  Map<I, T> toMapById() => {for (final item in this) item.id: item};
}

extension IdentifiableList<T extends Identifiable<I>, I> on List<T> {
  int indexWhereById(I id) => indexWhere((e) => e.id == id);

  List<T> withoutId(I id) => [for (final e in this) if (e.id != id) e];

  List<T> appendOrReplaceOnOverlap(List<T> page) => overlaps(page) ? page : [...this, ...page];
}

extension IdentifiableMapExtension<T extends Identifiable<I>, I> on Map<I, T> {
  Map<I, T> upsert(T item) => {...this, item.id: item};

  Map<I, T> upsertAll(Iterable<T> items) =>
      {...this, for (final item in items) item.id: item};

  Map<I, T> removeById(I id) => {...this}..remove(id);

  Map<I, T> updateById(I id, T Function(T current) update) {
    final current = this[id];
    if (current == null) return this;
    return {...this, id: update(current)};
  }
}
