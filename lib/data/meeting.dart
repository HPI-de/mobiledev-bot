import 'package:dartx/dartx.dart';
import 'package:meta/meta.dart';
import 'package:rxdart/rxdart.dart';
import 'package:sembast/sembast.dart';
import 'package:time_machine/time_machine.dart';

import '../utils.dart';
import 'db.dart';

const meetingBloc = MeetingBloc();

@immutable
class MeetingBloc {
  const MeetingBloc();

  _MeetingService get _service => const _MeetingService();

  /// Returns a stream of the next meeting. If no next meeting exists, may
  /// contain `null`.
  Stream<Meeting> getNextStream() => _service.getNextMeeting();

  /// Returns the next meeting or `null` if it doesn't exist.
  // TODO(marcelgarus): Is this true or does it simply never complete when no meeting exists?
  Future<Meeting> getNext() => getNextStream().first;

  /// Creates a new meeting.
  Future<void> create(Meeting meeting) => _service.createMeeting(meeting);

  /// Adds a participant to the meeting with the given id.
  Future<Meeting> addParticipant(int meetingId, int participantId) {
    return _update(
      meetingId,
      (m) => m.copyWith(
        participantIds: m.participantIds.union({participantId}),
      ),
    );
  }

  /// Removes a participant from the meeting with the given id.
  Future<Meeting> removeParticipant(int meetingId, int participantId) {
    return _update(
      meetingId,
      (m) => m.copyWith(
        participantIds: m.participantIds.difference({participantId}),
      ),
    );
  }

  /// Saves the id of the message for a certain meeting.
  Future<Meeting> saveMessageId(int meetingId, int messageId) {
    return _update(
      meetingId,
      (m) => m.copyWith(messageId: messageId),
    );
  }

  /// Updates a meeting.
  Future<Meeting> _update(
    int meetingId,
    Meeting Function(Meeting oldItem) updater,
  ) async {
    final oldMeeting = await _service.getMeeting(meetingId).first;
    final newMeeting = updater(oldMeeting);
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

  /// Returns the next meeting, or the current meeting if one is currently
  /// running.
  Stream<Meeting> getNextMeeting() {
    // Because the filter depends on the current time, we also execute the query
    // every two minutes, so that even if the underlying document in the
    // database doesn't change, we still get the correct meeting.
    return Stream<void>.periodic(Duration(seconds: 5))
        .switchMap((_) => _store
            .query(
              finder: Finder(
                // limit: 1,
                filter: Filter.greaterThan('end', Instant.now().epochSeconds),
                sortOrders: [SortOrder('start')],
              ),
            )
            .onSnapshots(db)
            .distinctUnique()
            .doOnData(
              (meeting) => logger.d(
                  'New meeting ${meeting.map((m) => m['start']).toList()} discovered.'),
            )
            .map((m) => m.firstOrNull))
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
    @required this.end,
    @required this.participantIds,
    this.messageId,
  })  : assert(start != null),
        assert(participantIds != null);

  Meeting.fromJson(Map<String, dynamic> json)
      : this(
          start: Instant.fromEpochSeconds(json['start']),
          end: Instant.fromEpochSeconds(json['end']),
          participantIds:
              (json['participantIds'] as List<dynamic>).cast<int>().toSet(),
          messageId: json['messageId'],
        );

  int get id => start.epochSeconds;
  final Instant start;
  final Instant end;
  bool get isOver => Instant.now() > end;
  final Set<int> participantIds;
  final int messageId;

  Meeting copyWith({
    Set<int> participantIds,
    int messageId,
  }) {
    return Meeting(
      start: start,
      end: end,
      participantIds: participantIds ?? this.participantIds,
      messageId: messageId ?? this.messageId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'start': start.epochSeconds,
      'end': end.epochSeconds,
      'participantIds': participantIds.toList(),
      'messageId': messageId,
    };
  }
}
