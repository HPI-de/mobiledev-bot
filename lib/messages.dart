import 'package:teledart/model.dart';
import 'package:time_machine/time_machine.dart';
import 'package:dartx/dartx.dart';
import 'package:time_machine/time_machine_text_patterns.dart';

import 'data.dart';
import 'main.dart';

// Because we can't initiate private chats with users, we welcome the user in
// the group and encourage them to text the bot privately.
Future<void> welcomeNewMemberInGroup(User newMember) async {
  await teledart.telegram.sendMessage(
    mobileDevGroupChatId,
    'Hi, ${newMember.first_name}! Welcome to the MobileDev club! 🐰🥚\n'
    'Please text me privately at @$botName.',
  );
}

Future<void> welcomeNewMemberPrivately(User newMember) async {
  await teledart.telegram.sendMessage(
    mobileDevGroupChatId, // TODO(marcelgarus): Look up chat id by user.
    'Hi there! TODO: I should tell you something about my commands.',
  );
}

Future<void> makeUserFeelBad(User user) async {
  await teledart.telegram.sendMessage(
    mobileDevGroupChatId, // TODO(marcelgarus): Look up chat id by user.
    'You break my heart! 💔😥',
  );
}

void sendMeetingAnnouncement(Meeting meeting) async {
  final _meetingTimePattern = LocalDateTimePattern.createWithCulture(
    'ddd., d.MMM, H:mm "Uhr"',
    await Cultures.getCulture('de-DE'),
  );

  final time = meeting.start
      .inZone(await DateTimeZoneProviders.defaultProvider
          .getZoneOrNull('Europe/Berlin'))
      .localDateTime;

  final participants = meeting.participantUsernames.isEmpty
      ? '👻 *cricket noise*'
      : [
          for (final participant in meeting.participantUsernames.sorted())
            // (await teledart.telegram.getChat(_mobileDevGroupChatId)).
            '\n• @$participant',
        ].join();

  await teledart.telegram.sendMessage(
    mobileDevGroupChatId,
    '''
Next meeting: ${_meetingTimePattern.format(time)}\n
Participants: $participants
'''
        .trim(),
    reply_markup: InlineKeyboardMarkup(
      inline_keyboard: [
        [
          InlineKeyboardButton(
            text: 'Change my attendance',
            callback_data: ButtonCallbacks.changeAttendance,
          ),
        ],
      ],
    ),
  );
}
