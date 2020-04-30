import 'package:teledart/model.dart';
import 'package:time_machine/time_machine.dart';
import 'package:dartx/dartx.dart';
import 'package:time_machine/time_machine_text_patterns.dart';

import 'data.dart';
import 'main.dart';

Future<void> tellUserOffForSpammingTheGroupChat(User user) async {
  await telegram.sendMessage(mobileDevGroupChatId,
      'To not spam this group, please send that to me privately at @$botName.');
}

// Because we can't initiate private chats with users, we welcome the user in
// the group and encourage them to text the bot privately.
Future<void> welcomeNewMemberInGroup(User newMember) async {
  await teledart.telegram.sendMessage(
    mobileDevGroupChatId,
    "Hi, ${newMember.first_name}! I'm thrilled to see you joined the MobileDev "
    "club! 🐰🥚 Do you mind texting me privately at @$botName? I'd love to "
    'give you a quick tour!',
  );
}

Future<void> welcomeNewMemberPrivately(User newMember) async {
  await teledart.telegram.sendMessage(
    mobileDevGroupChatId, // TODO(marcelgarus): Look up chat id by user.
    "Nice! 😊 So, you're probably wondering why I exist… Basically, I take "
    'care about announcing the meetings and taking notes of who will '
    "participate. If for some reason, you'll miss a meeting, just text "
    "/missing to me. And that's about it!",
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
    'ddd., d. MMM, H:mm "Uhr"',
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
