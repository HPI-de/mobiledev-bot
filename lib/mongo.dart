import 'package:meta/meta.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_text_patterns.dart';

class MdDb {
  MdDb() : _db = Db(_connectionString);
  static const _connectionString = 'mongodb://localhost:27017/mobileDev';

  final Db _db;
  DbCollection get _meetings => _db.collection('meetings');

  Future<void> init() async => _db.open();

  Future<Meeting> getNextMeeting() async {
    final json = await _meetings.findOne();
    return json == null ? null : Meeting.fromJson(json);
  }
}

class Meeting {
  const Meeting({
    @required this.time,
    @required this.participantUsernames,
  })  : assert(time != null),
        assert(participantUsernames != null);

  Meeting.fromJson(Map<String, dynamic> json)
      : this(
          time: _timePattern.parse(json['time']).value,
          participantUsernames: (json['participantUsernames'] as List<dynamic>)
              .cast<String>()
              .toSet(),
        );

  static final _timePattern = InstantPattern.general;

  final Instant time;
  final Set<String> participantUsernames;

  Map<String, dynamic> toJson() {
    return {
      'time': _timePattern.format(time),
      'participantUsernames': participantUsernames.toList(),
    };
  }
}
