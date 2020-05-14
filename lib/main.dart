import 'dart:convert';
import 'dart:io';

import 'package:hpi_mobiledev_bot/messages.dart';
import 'package:teledart/model.dart';
import 'package:teledart/teledart.dart';
import 'package:teledart/telegram.dart';
import 'package:time_machine/time_machine.dart';

import 'data/data.dart';
import 'utils.dart';

const mobileDevGroupChatId = -421105343;
String botName;
TeleDart teledart;
Telegram telegram;

abstract class ButtonCallbacks {
  static const changeAttendance = 'change_attendance';
}

extension OnlyInPrivateChats on Stream<Message> {
  /// For every emitted [Message], check if we are in a group chat. If we are,
  /// tell the user to instead execute the command in a private chat. Otherwise,
  /// forward the command to the returned [Stream].
  Stream<Message> onlyInPrivateChats() async* {
    await for (final message in this) {
      if (message.chat.type == 'group') {
        await tellUserOffForSpammingTheGroupChat(message.from);
      } else {
        yield message;
      }
    }
  }
}

void main() async {
  await TimeMachine.initialize();

  await initDb();
  await meetingBloc.create(Meeting(
    start: Instant.now().add(Time(hours: 1)),
    participantIds: {171455652},
  ));

  final nextMeeting = await meetingBloc.getNextStream().first;
  logger.i(json.encode(nextMeeting.toJson()));

  final token = Platform.environment['TELEGRAM_BOT_TOKEN'];
  teledart = TeleDart(Telegram(token), Event());
  telegram = teledart.telegram;

  final bot = await teledart.start();
  botName = bot.username;

  sendMeetingAnnouncement(await meetingBloc.getNextStream().first);

  // TODO(JonasWanke): Do this once on startup or only on request.
  // teledart.onMessage(entityType: '*').listen((message) {
  //   logger..d(message)..d('Chat ID: ${message.chat.id}');
  // });

  // Gets invoked when anything happens inside Telegram.
  teledart.onMessage(entityType: '*').listen((message) {
    if (message.chat.id == mobileDevGroupChatId) {
      // Something is happening inside the MobileDev group chat!

      // If new members join, we welcome them.
      (message.new_chat_members ?? <User>[]).forEach(_handleNewGroupMember);

      // Otherwise, we check from whom the message originated and update them.
      // This message appeared in the group chat, so we're sure that they are a
      // member of the chat.
      final user = message.from;
      if (user != null) {
        memberBloc.update(Member.fromUser(user));
      }
    }
  });

  // Callbacks occur when users click on keyboard buttons.
  teledart.onCallbackQuery().listen((callback) async {
    if (callback.data == ButtonCallbacks.changeAttendance) {
      final user = callback.from;
      final nextMeeting = await meetingBloc.getNext();
      print('Participant IDs are ${nextMeeting.participantIds}');
      if (nextMeeting.participantIds.contains(user.id)) {
        _handleUserWillBeMissing(user);
      } else {
        _handleUserWillBeComing(user);
      }
    }
  });

  // If `/chatid` is sent, answer with the current chat id.
  teledart.onCommand('chatid').listen(sendChatId);

  // The user started the bot privately.
  teledart.onCommand('start').onlyInPrivateChats().listen(_handleStartCommand);

  // The user entered a `/missing` command.
  teledart
      .onCommand('missing')
      .onlyInPrivateChats()
      .listen((message) => _handleUserWillBeMissing(message.from));

  // The user entered a `/coming` command.
  teledart
      .onCommand('coming')
      .onlyInPrivateChats()
      .listen((message) => _handleUserWillBeComing(message.from));

  return;
}

/// A new user joined the group.
void _handleNewGroupMember(User newMember) async {
  logger.i('A new user joined a chat.');
  await memberBloc.update(Member.fromUser(newMember));
  await welcomeNewMemberInGroup(newMember);
}

/// A user sent `/start` in a private chat.
void _handleStartCommand(Message message) async {
  final member = Member.fromMessage(message);
  if (!await memberBloc.doesExist(member.id)) {
    await welcomeNewMemberPrivately(member);
  }
  await memberBloc.update(member);
}

/// A user will be coming to the next meeting.
void _handleUserWillBeComing(User user) async {
  logger.i('@${user.username} will participate :D');
  final member = Member.fromUser(user);
  // Use this opportunity to update information that users may potentially
  // change, like their username or name.
  await memberBloc.update(member);

  final nextMeeting = await meetingBloc.getNext();
  await meetingBloc.addParticipant(nextMeeting.id, member.id);
}

/// A user will be absent from the next meeting.
void _handleUserWillBeMissing(User user) async {
  logger.i("@${user.username} won't participate :/");
  final member = Member.fromUser(user);
  // Use this opportunity to update information that users may potentially
  // change, like their username or name.
  await memberBloc.update(member);

  final nextMeeting = await meetingBloc.getNext();
  await meetingBloc.removeParticipant(nextMeeting.id, user.id);
  await makeMemberFeelBad(member);
}

// - Anwesenheitsliste
// - Erinnern fürs nächste Treffen
// - (Essensbestellung samt Countdown)
//   - (Automatisch Geld anfragen? https://paypal.me/marcelgarus/8,30EUR)
//   - (Verschiedene Angebotslisten: MobileDev vs. Spiele)
// - (Ideensammlung)
// - Generelle Hilfe über den Bot
