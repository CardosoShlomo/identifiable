# Identifiable

Mixin and id-based collection helpers for Dart, generic over the id type.

```dart
import 'package:identifiable/identifiable.dart';

class User with Identity {  // Identity = Identifiable<String>
  User(this.id);
  @override
  final String id;
}

final users = [User('a'), User('b')];
users.byId('a');                 // User?
users.withoutId('a');            // Iterable<User>
users.updateById('a', (u) => u); // List<User> — replace by id
users.toMapById();               // Map<String, User>
// also: includes, overlaps, indexWhereById; Map: upsert, upsertAll, removeById, updateById
```

For other id types use `Identifiable<I>` — e.g. a record as a compound key: `class Chat with Identifiable<(String, String)>` (id `=> (adId, userId)`).
