import 'package:dartx/dartx.dart';
import 'package:meta/meta.dart';
import 'package:sembast/sembast.dart';
import 'package:time_machine/time_machine.dart';

import 'db.dart';

const memberBloc = MemberBloc();

@immutable
class MemberBloc {
  const MemberBloc();

  _MemberService get _service => const _MemberService();

  Stream<Member> getMember(int id) => _service.getMember(id);
  Future<void> createMember(Member member) => _service.createMember(member);
}

@immutable
class _MemberService {
  const _MemberService();

  static final _store = intMapStoreFactory.store('members');

  Stream<Member> getMember(int id) =>
      _store.record(id).onSnapshot(db).map((s) => Member.fromJson(id, s.value));
  Stream<Member> getNextMember() {
    return _store
        .query(
          finder: Finder(
            limit: 1,
            filter: Filter.greaterThan('start', Instant.now().epochSeconds),
          ),
        )
        .onSnapshots(db)
        .map((m) => m.firstOrNull)
        .map((m) => m == null ? null : Member.fromJson(m.key, m.value));
  }

  Future<void> createMember(Member member) async {
    assert(member != null);

    await _store.record(member.id).update(db, member.toJson());
  }
}

class Member {
  const Member(
    this.id, {
    this.username,
  }) : assert(id != null);

  Member.fromJson(int id, Map<String, dynamic> json)
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
