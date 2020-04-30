import 'package:meta/meta.dart';
import 'package:dartx/dartx.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_io.dart';
import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_text_patterns.dart';

const _dbPath = 'db.json';
Database _db;
Database get db => _db;

Future<void> initDb() async {
  _db = await databaseFactoryIo.openDatabase(_dbPath);
}

final meetingBloc = MeetingBloc();

@immutable
class MeetingBloc {
  const MeetingBloc();

  static final _store = StoreRef<String, Map<String, dynamic>>('meetings');

  Stream<Meeting> getNextMeeting() {
    return _store
        .query(
          finder: Finder(
            limit: 1,
            filter: Filter.greaterThan(
              'start',
              Instant.now().epochSeconds,
            ),
          ),
        )
        .onSnapshots(db)
        .map((m) => m.firstOrNull)
        .map((m) => m == null ? null : Meeting.fromJson(m.value));
  }

  Future<String> createMeeting(Meeting meeting) {
    assert(meeting != null);

    return _store.add(db, meeting.toJson());
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

  final Instant start;
  final Set<String> participantUsernames;

  Map<String, dynamic> toJson() {
    return {
      'start': start.epochSeconds,
      'participantUsernames': participantUsernames.toList(),
    };
  }
}
