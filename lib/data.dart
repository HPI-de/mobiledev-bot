import 'package:dartx/dartx.dart';
import 'package:meta/meta.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_io.dart';
import 'package:time_machine/time_machine.dart';

const _dbPath = 'db.json';
Database _db;
Database get db => _db;

Future<void> initDb() async {
  _db = await databaseFactoryIo.openDatabase(_dbPath);
}

const meetingBloc = MeetingBloc();

@immutable
class MeetingBloc {
  const MeetingBloc(); // : _service = const MeetingService();

  _MeetingService get _service => const _MeetingService();

  Stream<Meeting> getNextMeeting() => _service.getNextMeeting();
  Future<void> createMeeting(Meeting meeting) =>
      _service.createMeeting(meeting);
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

    await _store.record(meeting.id).update(db, meeting.toJson());
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
