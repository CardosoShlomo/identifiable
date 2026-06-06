# Identifiable

Identifiable mixin and id-based collection helpers for Dart.

## Usage

```dart
import 'package:identifiable/identifiable.dart';

class User with Identifiable {
  User(this.id);

  @override
  final String id;
}

void main() {
  final users = [User('a'), User('b')];

  // Iterable helpers
  users.byId('a');             // User?
  users.withoutId('a');        // Iterable<User>
  var map = users.toMapById(); // Map<String, User> keyed by id

  // Map helpers — immutable; each returns a new map
  map = map.upsert(User('c'));
  map = map.removeById('a');
  map = map.updateById('b', (u) => u);
}
```
