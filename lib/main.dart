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
  await meetingBloc.createMeeting(Meeting(
    start: Instant.now().add(Time(hours: 1)),
    participantUsernames: {'JonasWanke'},
  ));

  final nextMeeting = await meetingBloc.getNextMeeting().first;
  logger.i(json.encode(nextMeeting.toJson()));

  final token = Platform.environment['TELEGRAM_BOT_TOKEN'];
  teledart = TeleDart(Telegram(token), Event());
  telegram = teledart.telegram;
  // telegram.sendMessage(_mobileDevGroupChatId, 'Hey MobileDev-Club :)');

  final bot = await teledart.start();
  botName = bot.username;

  sendMeetingAnnouncement(await meetingBloc.getNextMeeting().first);
  teledart.onCallbackQuery().listen((callback) {
    if (callback.data == ButtonCallbacks.changeAttendance) {
      logger.i("@${callback.from.username} won't participate :/");
    }
  });

  // teledart
  //     .onMessage(entityType: 'bot_command', keyword: 'start')
  //     .listen((message) {
  //   logger.i(message.chat.id);
  //   return teledart.telegram.sendMessage(message.chat.id, 'Hello TeleDart!');
  // });

  // TODO(JonasWanke): Do this once on startup or only on request.
  // teledart.onMessage(entityType: '*').listen((message) {
  //   logger..d(message)..d('Chat ID: ${message.chat.id}');
  // });

  teledart.onMessage(entityType: '*').listen((message) {
    for (final newMember in message.new_chat_members ?? <User>[]) {
      _handleNewGroupMember(message, newMember);
    }
  });

  // The user started the bot privately.
  teledart.onCommand('start').onlyInPrivateChats().listen(_handleStartCommand);

  // The user entered a `/missing` command.
  teledart
      .onCommand('missing')
      .onlyInPrivateChats()
      .listen(_handleMissingCommand);

  return;
}

/// A new user joined the group.
void _handleNewGroupMember(Message message, User newMember) async {
  logger.i('A new user joined a chat.');
  await welcomeNewMemberInGroup(newMember);
}

/// A user sent `/start` in a private chat.
void _handleStartCommand(Message message) async {
  // TODO(marcelgarus): Remember that the user `message.from.id` has private chat `message.chat.id` with us.
  await welcomeNewMemberPrivately(message.from);
}

/// A user sent `/missing` in a private chat.
void _handleMissingCommand(Message message) async {
  await makeUserFeelBad(message.from);
  // TODO(marcelgarus): Remember the user will be missing.
}

// - Anwesenheitsliste
// - Erinnern fürs nächste Treffen
// - (Essensbestellung samt Countdown)
//   - (Automatisch Geld anfragen? https://paypal.me/marcelgarus/8,30EUR)
//   - (Verschiedene Angebotslisten: MobileDev vs. Spiele)
// - (Ideensammlung)
// - Generelle Hilfe über den Bot
