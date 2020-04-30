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

  Future<Member> updatePrivateChatId(int memberId, int privateChatId) async {
    final oldMember = await _service.getMember(memberId).first;
    final newMember = oldMember.copyWith(privateChatId: privateChatId);
    await _service.updateMember(newMember);
    return newMember;
  }
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

  Future<void> updateMember(Member member) async {
    await _store.record(member.id).put(db, member.toJson());
  }
}

class Member {
  const Member(
    this.id, {
    this.username,
    this.name,
    this.privateChatId,
  }) : assert(id != null);

  Member.fromJson(int id, Map<String, dynamic> json)
      : this(
          id,
          username: json['username'],
          name: json['name'],
          privateChatId: json['privateChatId'],
        );

  final int id;
  final String username;
  final String name;
  final int privateChatId;

  Member copyWith({
    int privateChatId,
  }) {
    return Member(
      id,
      privateChatId: this.privateChatId ?? privateChatId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'name': name,
      'privateChatId': privateChatId,
    };
  }
}
