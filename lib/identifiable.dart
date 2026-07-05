import 'package:meta/meta.dart';

import 'package:canon_codec/canon_codec.dart';

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
}

/// Marks the HAND-WRITTEN enum that is an app's id-space: each row is an identity
/// carrying its [Codec] — how its key serialises in a URL. Nothing is generated;
/// the enum IS the holder. Other grammar trees (canon's `@screens`, ledger's
/// `@stores`) reference these rows by dot-shorthand and read `row.codec` to
/// encode/decode and to validate a screen `id` or a store key against them.
///
/// Applied as `@IDs()`. There is deliberately no lowercase `const ids`: the
/// natural name for the enum is `Ids`, and generated nav code uses `ids`
/// pervasively as an identifier, so a top-level `ids`/`Ids` would shadow it.
class IDs {
  const IDs();
}

/// The contract an `@ids` enum wears: every row carries a [codec]. The node IS a
/// [Codec] (it delegates to its inner one), so a screen can bind it straight into
/// a `Codec? id` field (`id: .user`) and a store can key by it — the SAME node
/// across both grammar trees. Generators read `node.codec` to recover the value
/// type (the node itself erases to `Codec<Object?>`).
///
/// A node may be COMPOSITE ([compose]) — an identity made of 2–16 atomic nodes.
/// A composite lets an `inherit` from a screen keyed by it match ONE component
/// by node identity (`author.inherit(review)` finds the `author` component).
abstract mixin class IdNode implements Codec<Object?> {
  const IdNode();

  Codec get codec;

  @override
  Object? decode(String token) => codec.decode(token);

  @override
  String encode(Object? value) => codec.encode(value);

  /// A COMPOSITE id-node from 2–16 atomic nodes:
  /// `static const IdNode review = .compose(product, author);`. Const, so it
  /// can key a screen's enum-constant id; `inherit` from a screen keyed by it
  /// matches one component by node identity.
  const factory IdNode.compose(IdNode n1, IdNode n2,
      [IdNode? n3, IdNode? n4, IdNode? n5, IdNode? n6, IdNode? n7, IdNode? n8,
      IdNode? n9, IdNode? n10, IdNode? n11, IdNode? n12, IdNode? n13,
      IdNode? n14, IdNode? n15, IdNode? n16]) = CompositeId;
}

/// See [IdNode.compose]. Component nodes are individual fields — a const
/// constructor can't build a list — so the signature itself caps the arity at
/// 16 (à la `Object.hash`); generators read the `n*` fields directly.
///
/// Marks the hand-written enum that is an app's ENTITY SPACE: each row binds an
/// entity TYPE to its id-NODE, and a `static final graph = EntityGraph({...})`
/// declares OWNERSHIP as a tree — `review({comment})` means a comment belongs
/// to exactly one review (its state lives inside it; removing the review
/// removes its comments by construction). The same child kind may appear under
/// several parents (`image({reactor}), moment({reactor})`): instances still
/// have exactly one owner, of either kind. Roots are the aggregate boundaries —
/// stores attach to roots only.
class Entities {
  const Entities();
}

const entities = Entities();

/// Authoring marker: what an [EntityGraph] set literal may hold — a bare row
/// (a leaf) or a row with children (`review({comment})`).
abstract interface class EntityTreeNode {}

/// The contract an `@entities` enum wears: every row carries the entity [type]
/// and the id-node ([key]) its instances are identified by. `call({children})`
/// declares the row's OWNED children in the graph.
mixin EntityNode<Self extends EntityNode<Self>> on Enum
    implements EntityTreeNode {
  Type get type;
  /// Null = a UNIT entity: cardinality one, keyless — for entities whose
  /// identity is the session (the wire sends their facts without an id).
  IdNode? get key;

  /// This entity with its owned children — `review({comment})`.
  EntityTreeNode call([Set<EntityTreeNode> children = const {}]) =>
      EntityBranch(this, children);

  /// A MERGE EDGE: this row's per-key READ SURFACE consults [source] through
  /// [projection] — `user.merge(viewer, const ViewerSupportsUser())`. The
  /// receiver owns the surface; the source speaks at its own [Identifiable]
  /// id. Chainable (`.merge(a, pa).merge(b, pb)` — resolution in declaration
  /// order), and composes with children: `user.merge(...)({image, moment})`.
  ///
  /// [projection] is a ledger `Projection` — held untyped here (this package
  /// sits below ledger); the generator emits the fully typed wiring.
  EntityMerge merge(Self source, Object projection) =>
      EntityMerge(this, [(source, projection)]);
}

/// A row carrying merge edges (and optionally children) — the tree-building
/// wrapper [EntityNode.merge] returns.
class EntityMerge implements EntityTreeNode {
  EntityMerge(this.entity, this.edges, [this.children = const {}]);

  final Enum entity;
  final List<(Enum, Object)> edges;
  final Set<EntityTreeNode> children;

  EntityMerge merge(Enum source, Object projection) =>
      EntityMerge(entity, [...edges, (source, projection)], children);

  EntityMerge call([Set<EntityTreeNode> children = const {}]) =>
      EntityMerge(entity, edges, children);
}

/// A row plus its owned children — the tree-building wrapper.
class EntityBranch implements EntityTreeNode {
  EntityBranch(this.entity, this.children);
  final Enum entity;
  final Set<EntityTreeNode> children;
}

/// The declared ownership tree. Structure is read both at build time (the
/// generator derives store legality, nested-map machinery, and path types from
/// it) and at runtime ([ownersOf]/[childrenOf] — the entity-scope resolution
/// surface).
class EntityGraph {
  EntityGraph(this.tree) {
    void walk(EntityTreeNode node, Enum? parent) {
      final (row, children) = switch (node) {
        EntityBranch(:final entity, :final children) => (entity, children),
        EntityMerge(:final entity, :final children, :final edges) => () {
            (_merges[entity] ??= []).addAll(edges);
            return (entity, children);
          }(),
        Enum() => (node as Enum, const <EntityTreeNode>{}),
        _ => throw ArgumentError.value(
            node, 'tree', 'not an entity row or branch'),
      };
      if (parent != null) {
        (_owners[row] ??= {}).add(parent);
      } else {
        _roots.add(row);
      }
      for (final c in children) {
        walk(c, row);
      }
    }

    for (final n in tree) {
      walk(n, null);
    }
    for (final r in _roots) {
      if (_owners.containsKey(r)) {
        throw StateError(
            '"${r.name}" is declared both as a root and as an owned child — '
            'an entity kind is either an aggregate root or owned, not both.');
      }
    }
  }

  final Set<EntityTreeNode> tree;
  final Set<Enum> _roots = {};
  final Map<Enum, Set<Enum>> _owners = {};
  final Map<Enum, List<(Enum, Object)>> _merges = {};

  /// The aggregate roots — the rows stores may attach to.
  Set<Enum> get roots => _roots;

  /// The owner KINDS of [row] — empty for a root. An instance is owned by
  /// exactly one instance of one of these.
  Set<Enum> ownersOf(Enum row) => _owners[row] ?? const {};

  /// Whether [row] is an aggregate root (not owned by anything).
  bool isRoot(Enum row) => !_owners.containsKey(row);

  /// The merge edges declared on [row]'s read surface, declaration order:
  /// (source row, projection instance).
  List<(Enum, Object)> mergesOf(Enum row) => _merges[row] ?? const [];
}

/// Why 16: a composite id is a composite PRIMARY KEY, and 16 is the strictest
/// column cap a mainstream database enforces on one (MySQL/InnoDB and SQL
/// Server key columns; PostgreSQL and Oracle allow 32) — so canon is never
/// more restrictive than a production database, while anything past ~4 is
/// already a modeling smell.
class CompositeId with IdNode {
  const CompositeId(this.n1, this.n2,
      [this.n3, this.n4, this.n5, this.n6, this.n7, this.n8, this.n9, this.n10,
      this.n11, this.n12, this.n13, this.n14, this.n15, this.n16]);

  final IdNode n1, n2;
  final IdNode? n3, n4, n5, n6, n7, n8, n9, n10, n11, n12, n13, n14, n15, n16;

  // A getter, not a const field: the language forbids instance creation with
  // parameter args in a const initializer (merely POTENTIALLY constant —
  // dart-lang/language#4571 would allow it). A node IS a Codec (it delegates),
  // so the nodes feed CompositeCodec directly.
  @override
  Codec get codec => CompositeCodec(n1, n2, n3, n4, n5, n6, n7, n8, n9, n10,
      n11, n12, n13, n14, n15, n16);
}
