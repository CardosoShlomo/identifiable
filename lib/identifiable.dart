import 'package:meta/meta.dart';

/// Entities are VALUES: folds produce new instances; a mutated entity
/// corrupts before/after events and optimistic refolds — enforced here for
/// every class that wears the mixin.
@immutable
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

  /// The immutable predicate removal — drops every entry [test] matches.
  /// The cascade-deletion idiom: a composite-keyed collection sheds all
  /// entries referencing a gone entity in one expression.
  Map<I, T> withoutWhere(bool Function(I id, T item) test) =>
      {for (final e in entries) if (!test(e.key, e.value)) e.key: e.value};

  /// Transform every value, keys untouched.
  Map<I, T> mapValues(T Function(I id, T item) transform) =>
      {for (final e in entries) e.key: transform(e.key, e.value)};
}
