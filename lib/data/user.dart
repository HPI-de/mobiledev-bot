import 'package:dartx/dartx.dart';
import 'package:meta/meta.dart';
import 'package:sembast/sembast.dart';
import 'package:time_machine/time_machine.dart';

import 'db.dart';

const userBloc = UserBloc();

@immutable
class UserBloc {
  const UserBloc();

  _UserService get _service => const _UserService();

  Stream<User> getUser(int id) => _service.getUser(id);
  Future<void> createUser(User user) => _service.createUser(user);
}

@immutable
class _UserService {
  const _UserService();

  static final _store = intMapStoreFactory.store('users');

  Stream<User> getUser(int id) =>
      _store.record(id).onSnapshot(db).map((s) => User.fromJson(id, s.value));
  Stream<User> getNextUser() {
    return _store
        .query(
          finder: Finder(
            limit: 1,
            filter: Filter.greaterThan('start', Instant.now().epochSeconds),
          ),
        )
        .onSnapshots(db)
        .map((m) => m.firstOrNull)
        .map((m) => m == null ? null : User.fromJson(m.key, m.value));
  }

  Future<void> createUser(User user) async {
    assert(user != null);

    await _store.record(user.id).update(db, user.toJson());
  }
}

class User {
  const User(
    this.id, {
    this.username,
  }) : assert(id != null);

  User.fromJson(int id, Map<String, dynamic> json)
      : this(
          id,
          username: json['username'],
        );

  final int id;
  final String username;

  Map<String, dynamic> toJson() {
    return {
      'username': username,
    };
  }
}
