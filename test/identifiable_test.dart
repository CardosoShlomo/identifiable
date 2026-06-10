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

class _Chat with Identifiable<(String, String)> {
  _Chat(this.adId, this.userId);

  final String adId;
  final String userId;

  @override
  (String, String) get id => (adId, userId);
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
  });

  group('typed id (record key)', () {
    final chats = [_Chat('ad1', 'u1'), _Chat('ad1', 'u2')];

    test('byId / withoutId with a record id', () {
      expect(chats.byId(('ad1', 'u1'))?.userId, 'u1');
      expect(chats.byId(('ad1', 'zz')), isNull);
      expect(chats.withoutId(('ad1', 'u1')).map((c) => c.userId), ['u2']);
    });

    test('isSameAs compares the record id', () {
      expect(_Chat('ad1', 'u1').isSameAs(_Chat('ad1', 'u1')), isTrue);
      expect(_Chat('ad1', 'u1').isSameAs(_Chat('ad1', 'u2')), isFalse);
    });

    test('toMapById is keyed by the record', () {
      expect(chats.toMapById()[('ad1', 'u2')]?.userId, 'u2');
    });
  });
}
