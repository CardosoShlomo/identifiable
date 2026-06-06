import 'package:identifiable/identifiable.dart';
import 'package:test/test.dart';

class _Thing with Identifiable {
  _Thing(this.id, [this.label = '']);

  @override
  final String id;
  final String label;
}

void main() {
  test('isSameAs compares ids', () {
    expect(_Thing('a').isSameAs(_Thing('a')), isTrue);
    expect(_Thing('a').isSameAs(_Thing('b')), isFalse);
  });

  group('IdentifiableIterable', () {
    test('byId / withoutId / toMapById', () {
      final list = [_Thing('a'), _Thing('b')];
      expect(list.byId('a')?.id, 'a');
      expect(list.byId('z'), isNull);
      expect(list.withoutId('a').map((e) => e.id), ['b']);
      expect(list.toMapById().keys.toSet(), {'a', 'b'});
    });
  });

  group('IdentifiableMap', () {
    test('upsert replaces, updateById mutates, removeById drops', () {
      var m = <String, _Thing>{}.upsert(_Thing('a', 'x'));
      expect(m['a']?.label, 'x');
      m = m.upsert(_Thing('a', 'y'));
      expect(m.length, 1);
      expect(m['a']?.label, 'y');
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
}
