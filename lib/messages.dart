import 'package:hpi_mobiledev_bot/utils.dart';
import 'package:teledart/model.dart';
import 'package:time_machine/time_machine.dart';
import 'package:dartx/dartx.dart';
import 'package:time_machine/time_machine_text_patterns.dart';

import 'data/data.dart';
import 'main.dart';

const groupSpamMemes = [
  'https://lh3.googleusercontent.com/proxy/PZtN-h6JqhKh4YMmKbXOE2Xz1u-vsSQun34AGarGqkxo95yGHfo6nif28bwZ15KgXjL5_qOfxiNmrUF-JrjvzmpvkzfwCnnUaasvIcLDMHd_o4vu0Y-xw_Yngr13vMsdOFkOdQvjegyX0y1dSxHEVAVTk0tUPyMK14I',
  'https://media.makeameme.org/created/when-people-spam.jpg',
];

const sadPuppies = [
  'https://www.dailydot.com/wp-content/uploads/c39/18/3a8988f1f6257a137709c800dfd83d4d-1024x512.jpg',
  'https://media.breitbart.com/media/2015/04/enhanced-buzz-wide-6382-1329860109-8-640x427.jpg',
  'https://media.npr.org/assets/img/2015/08/21/istock_000010838061_large_sq-80d63c66ead97de497285063d92809553dcd16a7-s800-c85.jpg',
  'https://vignette3.wikia.nocookie.net/animaljam/images/6/6b/Sad_puppy.png/revision/latest?cb=20130806142646',
  'https://ququ-media.com/wp-content/uploads/2016/12/sad-puppy-wallpaper.jpg',
  'https://pbs.twimg.com/media/CEHMiIhVAAEnSwE.jpg',
];

Future<void> tellUserOffForSpammingTheGroupChat(User user) async {
  await telegram.sendPhoto(mobileDevGroupChatId, random(groupSpamMemes));
  await telegram.sendMessage(mobileDevGroupChatId,
      'To not spam this group, please send that to me privately at @$botName.');
}

// Because we can't initiate private chats with users, we welcome the user in
// the group and encourage them to text the bot privately.
Future<void> welcomeNewMemberInGroup(User newMember) async {
  await telegram.sendMessage(
    mobileDevGroupChatId,
    "Hi, ${newMember.first_name}! I'm thrilled to see you joined the MobileDev "
    "club! 🐰🥚 Do you mind texting me privately at @$botName? I'd love to "
    'give you a quick tour!',
  );
}

Future<void> welcomeNewMemberPrivately(User newMember) async {
  await telegram.sendMessage(
    mobileDevGroupChatId, // TODO(marcelgarus): Look up chat id by user.
    "Nice! 😊 So, you're probably wondering why I exist… Basically, I take "
    'care about announcing the meetings and taking notes of who will '
    "participate. If for some reason, you'll miss a meeting, just text "
    "/missing to me. And that's about it!",
  );
}

Future<void> makeUserFeelBad(User user) async {
  await telegram.sendMessage(
    mobileDevGroupChatId, // TODO(marcelgarus): Look up chat id by user.
    "You break my heart! 💔😥\nI'm so sad! Here's a picture of a sad puppy:",
  );
  await telegram.sendPhoto(
    mobileDevGroupChatId, // TODO(marcelgarus): Look up chat id by user.
    random(sadPuppies),
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

  final participants = meeting.participantIds.isEmpty
      ? '👻 *cricket noise*'
      : [
          for (final participant in meeting.participantIds.sorted())
            // (await telegram.getChat(_mobileDevGroupChatId)).
            '\n• @$participant',
        ].join();

  await telegram.sendMessage(
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
