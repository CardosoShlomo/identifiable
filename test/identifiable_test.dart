import 'package:identifiable/identifiable.dart';
import 'package:test/test.dart';

class _Thing with Identity {
  _Thing(this.id, [this.label = '']);

  @override
  final String id;
  final String label;
}

class _Other with Identity {
  _Other(this.id);

  @override
  final String id;
}

class _Review with Identifiable<(String, String)> {
  _Review(this.productId, this.authorId);

  final String productId;
  final String authorId;

  @override
  (String, String) get id => (productId, authorId);
}

void main() {
  group('Identity (String id)', () {
    test('hasSameId compares ids regardless of type', () {
      expect(_Thing('a').hasSameId(_Thing('a')), isTrue);
      expect(_Thing('a').hasSameId(_Thing('b')), isFalse);
      expect(_Thing('a').hasSameId(_Other('a')), isTrue);
    });

    test('isSameAs requires the same type and id', () {
      expect(_Thing('a').isSameAs(_Thing('a')), isTrue);
      expect(_Thing('a').isSameAs(_Thing('b')), isFalse);
      expect(_Thing('a').isSameAs(_Other('a')), isFalse);
    });
  });

  group('IdentifiableIterable', () {
    final list = [_Thing('a'), _Thing('b')];

    test('byId / withoutId / toMapById', () {
      expect(list.byId('a')?.id, 'a');
      expect(list.byId('z'), isNull);
      expect(list.withoutId('a').map((e) => e.id), ['b']);
      expect(list.toMapById().keys.toSet(), {'a', 'b'});
    });

    test('includes / includesId / overlaps', () {
      expect(list.includes(_Thing('a')), isTrue);
      expect(list.includes(_Thing('z')), isFalse);
      expect(list.includesId('a'), isTrue);
      expect(list.includesId('z'), isFalse);
      expect(list.overlaps([_Thing('b'), _Thing('z')]), isTrue);
      expect(list.overlaps([_Thing('z')]), isFalse);
    });

    test('updateById replaces only the matching item', () {
      final updated = list.updateById('a', (t) => _Thing('a', 'x'));
      expect(updated.byId('a')?.label, 'x');
      expect(updated.byId('b')?.label, '');
      expect(list.updateById('z', (t) => _Thing('z')).map((e) => e.id), ['a', 'b']);
    });

    test('indexWhereById', () {
      expect(list.indexWhereById('b'), 1);
      expect(list.indexWhereById('z'), -1);
    });

    test('withoutId on a List returns a List', () {
      final result = list.withoutId('a');
      expect(result, isA<List<_Thing>>());
      expect(result.map((e) => e.id), ['b']);
      expect(list.withoutId('z').map((e) => e.id), ['a', 'b']);
    });

    test('appendOrReplaceOnOverlap appends a fresh page', () {
      final result = list.appendOrReplaceOnOverlap([_Thing('c'), _Thing('d')]);
      expect(result.map((e) => e.id), ['a', 'b', 'c', 'd']);
    });

    test('appendOrReplaceOnOverlap replaces on overlap', () {
      final page = [_Thing('a', 'fresh'), _Thing('c')];
      final result = list.appendOrReplaceOnOverlap(page);
      expect(result.map((e) => e.id), ['a', 'c']);
      expect(result.byId('a')?.label, 'fresh');
    });
  });

  group('IdentifiableMap', () {
    test('upsert / upsertAll / updateById / removeById', () {
      var m = <String, _Thing>{}.upsert(_Thing('a', 'x'));
      expect(m['a']?.label, 'x');
      m = m.upsert(_Thing('a', 'y'));
      expect(m.length, 1);
      expect(m['a']?.label, 'y');
      m = m.upsertAll([_Thing('b'), _Thing('c')]);
      expect(m.keys.toSet(), {'a', 'b', 'c'});
      m = m.updateById('a', (t) => _Thing(t.id, 'z'));
      expect(m['a']?.label, 'z');
      m = m.removeById('a');
      expect(m.containsKey('a'), isFalse);
    });

    test('updateById no-ops on a missing id', () {
      final m = <String, _Thing>{}.upsert(_Thing('a', 'x')).updateById('z', (t) => _Thing(t.id, 'y'));
      expect(m.containsKey('z'), isFalse);
      expect(m['a']?.label, 'x');
    });

    test('withoutWhere drops every matching entry (cascade deletion)', () {
      final reviews = <(String, String), _Review>{}
          .upsert(_Review('shoe', 'ana'))
          .upsert(_Review('shoe', 'ben'))
          .upsert(_Review('bag', 'ana'));
      // the product is delisted — all its reviews go in one expression.
      final without = reviews.withoutWhere((id, _) => id.$1 == 'shoe');
      expect(without.keys.toSet(), {('bag', 'ana')});
    });

    test('mapValues transforms every value, keys untouched', () {
      final m = <String, _Thing>{}
          .upsert(_Thing('a', 'x'))
          .upsert(_Thing('b', 'y'));
      final upper = m.mapValues((id, t) => _Thing(id, t.label!.toUpperCase()));
      expect(upper.keys.toSet(), {'a', 'b'});
      expect(upper['a']?.label, 'X');
      expect(upper['b']?.label, 'Y');
    });
  });

  group('typed id (record key)', () {
    final reviews = [_Review('p1', 'a1'), _Review('p1', 'a2')];

    test('byId / withoutId with a record id', () {
      expect(reviews.byId(('p1', 'a1'))?.authorId, 'a1');
      expect(reviews.byId(('p1', 'zz')), isNull);
      expect(reviews.withoutId(('p1', 'a1')).map((r) => r.authorId), ['a2']);
    });

    test('isSameAs compares the record id', () {
      expect(_Review('p1', 'a1').isSameAs(_Review('p1', 'a1')), isTrue);
      expect(_Review('p1', 'a1').isSameAs(_Review('p1', 'a2')), isFalse);
    });

    test('toMapById is keyed by the record', () {
      expect(reviews.toMapById()[('p1', 'a2')]?.authorId, 'a2');
    });
  });
}
