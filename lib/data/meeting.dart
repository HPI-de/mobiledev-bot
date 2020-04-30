import 'package:dartx/dartx.dart';
import 'package:meta/meta.dart';
import 'package:sembast/sembast.dart';
import 'package:time_machine/time_machine.dart';

import 'db.dart';

const meetingBloc = MeetingBloc();

@immutable
class MeetingBloc {
  const MeetingBloc();

  _MeetingService get _service => const _MeetingService();

  Stream<Meeting> getNextMeeting() => _service.getNextMeeting();
  Future<void> createMeeting(Meeting meeting) =>
      _service.createMeeting(meeting);

  Future<Meeting> addParticipant(int meetingId, String username) async {
    final oldMeeting = await _service.getMeeting(meetingId).first;
    final newMeeting = oldMeeting.copyWith(
      participantUsernames: oldMeeting.participantUsernames.union({username}),
    );
    await _service.updateMeeting(newMeeting);
    return newMeeting;
  }

  Future<Meeting> removeParticipant(int meetingId, String username) async {
    final oldMeeting = await _service.getMeeting(meetingId).first;
    final newMeeting = oldMeeting.copyWith(
      participantUsernames:
          oldMeeting.participantUsernames.difference({username}),
    );
    await _service.updateMeeting(newMeeting);
    return newMeeting;
  }
}

@immutable
class _MeetingService {
  const _MeetingService();

  static final _store = intMapStoreFactory.store('meetings');

  Stream<Meeting> getMeeting(int id) =>
      _store.record(id).onSnapshot(db).map((s) => Meeting.fromJson(s.value));
  Stream<Meeting> getNextMeeting() {
    return _store
        .query(
          finder: Finder(
            limit: 1,
            filter: Filter.greaterThan('start', Instant.now().epochSeconds),
          ),
        )
        .onSnapshots(db)
        .map((m) => m.firstOrNull)
        .map((m) => m == null ? null : Meeting.fromJson(m.value));
  }

  Future<void> createMeeting(Meeting meeting) async {
    assert(meeting != null);

    await _store.record(meeting.id).add(db, meeting.toJson());
  }

  Future<void> updateMeeting(Meeting meeting) async {
    await _store.record(meeting.id).put(db, meeting.toJson());
  }
}

class Meeting {
  const Meeting({
    @required this.start,
    @required this.participantUsernames,
  })  : assert(start != null),
        assert(participantUsernames != null);

  Meeting.fromJson(Map<String, dynamic> json)
      : this(
          start: Instant.fromEpochSeconds(json['start']),
          participantUsernames: (json['participantUsernames'] as List<dynamic>)
              .cast<String>()
              .toSet(),
        );

  int get id => start.epochSeconds;
  final Instant start;
  final Set<String> participantUsernames;

  Meeting copyWith({
    Set<String> participantUsernames,
  }) {
    return Meeting(
      start: start,
      participantUsernames: this.participantUsernames ?? participantUsernames,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'start': start.epochSeconds,
      'participantUsernames': participantUsernames.toList(),
    };
  }
}
