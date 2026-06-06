mixin Identifiable {
  String get id;

  bool isSameAs(Identifiable other) => id == other.id;
}

extension IdentifiableIterable<T extends Identifiable> on Iterable<T> {
  bool includes(T item) => any(item.isSameAs);

  bool overlaps(Iterable<T> others) => any(others.includes);

  Iterable<T> withoutId(String id) => where((e) => e.id != id);

  T? byId(String id) {
    for (final item in this) {
      if (item.id == id) return item;
    }
    return null;
  }

  Map<String, T> toMapById() => {for (final item in this) item.id: item};
}

extension IdentifiableMap<T extends Identifiable> on Map<String, T> {
  Map<String, T> upsert(T item) => {...this, item.id: item};

  Map<String, T> upsertAll(Iterable<T> items) =>
      {...this, for (final item in items) item.id: item};

  Map<String, T> removeById(String id) => {...this}..remove(id);

  Map<String, T> updateById(String id, T Function(T current) update) {
    final current = this[id];
    if (current == null) return this;
    return {...this, id: update(current)};
  }
}
