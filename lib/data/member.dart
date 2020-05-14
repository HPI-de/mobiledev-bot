import 'package:dartx/dartx.dart';
import 'package:meta/meta.dart';
import 'package:sembast/sembast.dart';
import 'package:teledart/model.dart';

import '../main.dart';
import 'db.dart';

const memberBloc = MemberBloc();

@immutable
class MemberBloc {
  const MemberBloc();

  _MemberService get _service => const _MemberService();

  /// Returns a stream of the member with the given [id]. If the member does not
  /// exist, the stream will be empty. If the member joins later on, it also
  /// appears in streams that were created before.
  Stream<Member> getStream(int id) => _service.getStream(id);

  /// Returns a member if it exists, or `null` otherwise.
  Future<Member> get(int id) async =>
      await doesExist(id) ? _service.getStream(id).first : null;

  /// Checks if a member exists.
  Future<bool> doesExist(int id) => _service.doesExist(id);

  /// Creates a new member or updates an existing member if it already exists.
  Future<void> update(Member member) async {
    if (!await _service.doesExist(member.id)) {
      await _service.create(member);
    } else {
      final previous = await get(member.id);
      final updated = previous.copyWith(
        username: member.username,
        name: member.name,
        privateChatId: member.privateChatId,
      );
      await _service.update(updated);
    }
  }

  // Future<Member> updatePrivateChatId(int memberId, int privateChatId) async {
  //   if (!await _service.doesMemberExist(memberId)) {
  //     return null;
  //   }
  //   final oldMember = await _service.getMember(memberId).first;
  //   final newMember = oldMember.copyWith(privateChatId: privateChatId);
  //   await _service.updateMember(newMember);
  //   return newMember;
  // }
}

@immutable
class _MemberService {
  const _MemberService();

  static final _store = intMapStoreFactory.store('members');

  Future<bool> doesExist(int id) => _store.record(id).exists(db);
  Stream<Member> getStream(int id) => _store
      .record(id)
      .onSnapshot(db)
      .map((s) => s == null ? null : Member.fromJson(id, s.value));

  /// Actually creates a member or throws if one already exists.
  Future<void> create(Member member) async {
    assert(member != null);
    await _store.record(member.id).add(db, member.toJson());
  }

  /// Updates an existing member. Throws if the member doesn't exist.
  Future<void> update(Member member) async {
    await _store.record(member.id).put(db, member.toJson());
  }
}

/// A member of the MobileDev club.
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

  Member.fromUser(User user)
      : this(user.id, username: user.username, name: user.first_name);

  Member.fromMessage(Message message)
      : this(
          message.from.id,
          username: message.from.username,
          name: message.from.first_name,
          // If the message got sent in the MobileDev group, we ignore it.
          // Otherwise, we assume it got sent privately and we save the chat id
          // as the user's private chat id.
          privateChatId:
              message.chat.id == mobileDevGroupChatId ? null : message.chat.id,
        );

  final int id;
  final String username;
  final String name;
  final int privateChatId;

  Member copyWith({
    String username,
    String name,
    int privateChatId,
  }) {
    return Member(
      id,
      username: username ?? this.username,
      name: name ?? this.name,
      privateChatId: privateChatId ?? this.privateChatId,
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
