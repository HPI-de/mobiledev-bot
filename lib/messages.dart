import 'dart:async';

import 'package:dartx/dartx.dart';
import 'package:hpi_mobiledev_bot/utils.dart';
import 'package:teledart/model.dart';
import 'package:teledart/src/util/http_client.dart' show HttpClientException;
import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_text_patterns.dart';

import 'data/data.dart';
import 'data/emotional_attachment.dart';
import 'main.dart';

const groupSpamMemes = [
  'https://media.makeameme.org/created/when-people-spam.jpg',
];

Future<void> sendChatId(Message message) async {
  await telegram.sendMessage(message.chat.id,
      'The Telegram chat id of this chat is ${message.chat.id}.');
}

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

Future<void> welcomeNewMemberPrivately(Member member) async {
  await telegram.sendMessage(
    member.id,
    "Nice! 😊 So, you're probably wondering why I exist… Basically, I take "
    'care about announcing the meetings and taking notes of who will '
    "participate. If for some reason, you'll miss a meeting, just text "
    "/missing to me. And that's about it!",
  );
}

Future<void> makeMemberFeelBad(Member member) async {
  try {
    await telegram.sendMessage(
      member.id,
      'You break my heart! 💔😥\nTo make you feel bad, please look at this '
      'picture of a sad ${member.emotionalAttachment.singularName} for 5 seconds:',
    );
    await telegram.sendPhoto(
      member.id,
      (member.emotionalAttachment ?? dogs).randomSad(),
      reply_markup: InlineKeyboardMarkup(
        inline_keyboard: [
          [
            InlineKeyboardButton(
              text: "I regret my decision — I'll come",
              callback_data: ButtonCallbacks.changeAttendance,
            ),
          ],
        ],
      ),
    );
  } on HttpClientException catch (e) {
    if (e.cause.contains('chat not found')) {
      logger.w('Making user ${member.name} with id ${member.id} feel bad '
          "didn't work because I couldn't text them privately. Here's the "
          'exception: $e');
      // The private chat id of the user is invalid. Either the user didn't text
      // us privately yet or blocked us or something.
    }
  }
}

void sendMeetingAnnouncement(Meeting meeting) async {
  final changeAttendanceKeyboard = InlineKeyboardMarkup(
    inline_keyboard: [
      [
        InlineKeyboardButton(
          text: 'Change my attendance',
          callback_data: ButtonCallbacks.changeAttendance,
        ),
      ],
    ],
  );

  final message = await telegram.sendMessage(
    mobileDevGroupChatId,
    await _meetingAnnouncementText(meeting),
    reply_markup: changeAttendanceKeyboard,
  );
  await meetingBloc.saveMessageId(meeting.id, message.message_id);

  StreamSubscription<Meeting> subscription;
  subscription = meetingBloc.getNextStream().listen((meeting) async {
    final isOver = meeting.start.inLocalZone().localDateTime.calendarDate <
        LocalDate.today();
    try {
      await telegram.editMessageText(
        await _meetingAnnouncementText(meeting),
        chat_id: mobileDevGroupChatId,
        message_id: message.message_id,
        reply_markup: isOver ? null : changeAttendanceKeyboard,
      );
    } on HttpClientException catch (e) {
      if (e.cause.contains('message is not modified')) {
        // This is okay.
      } else {
        rethrow;
      }
    }
    if (isOver) {
      await subscription.cancel();
    }
  });
}

Future<String> _meetingAnnouncementText(Meeting meeting) async {
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
            '\n• ${await _getParticipantText(participant)}',
        ].join();

  return 'Next meeting: ${_meetingTimePattern.format(time)}\n'
      'Participants: $participants';
}

Future<String> _getParticipantText(int userId) async {
  final member = await memberBloc.getStream(userId).first;
  if (member == null) {
    return 'Unknown member with id $userId';
  }
  final buffer = StringBuffer()..write(member.name);
  if (member.username != null) {
    buffer.write(' (@${member.username})');
  }
  return buffer.toString();
}
