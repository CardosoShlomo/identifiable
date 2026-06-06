import 'package:identifiable/identifiable.dart';

class User with Identifiable {
  User(this.id);

  @override
  final String id;
}

void main() {
  final users = [User('a'), User('b')];

  var byId = users.toMapById(); // {'a': ..., 'b': ...}
  byId = byId.upsert(User('c')); // add/replace by id
  byId = byId.removeById('a'); // drop by id

  print(byId.keys); // (b, c)
}
