import 'dart:convert';
import 'dart:io';

import 'package:dartx/dartx.dart';
import 'package:hpi_mobiledev_bot/messages.dart';
import 'package:teledart/model.dart';
import 'package:teledart/teledart.dart';
import 'package:teledart/telegram.dart';
import 'package:time_machine/time_machine.dart';

import 'mongo.dart';
import 'utils.dart';

const mobileDevGroupChatId = -421105343;
String botName;

abstract class ButtonCallbacks {
  static const changeAttendance = 'change_attendance';
}

extension OnlyInPrivateChats on Stream<Message> {
  /// For every emitted [Message], check if we are in a group chat. If we are,
  /// tell the user to instead execute the command in a private chat. Otherwise,
  /// forward the command to the returned [Stream].
  Stream<Message> onlyInPrivateChats(TeleDart teledart, String botName) async* {
    await for (final message in this) {
      if (message.chat.type == 'group') {
        await teledart.replyMessage(
            message, 'Sorry, please send that to me privately at @$botName.');
      } else {
        yield message;
      }
    }
  }
}

void main() async {
  await TimeMachine.initialize();

  final db = MdDb();
  await db.init();

  final nextMeeting = await db.getNextMeeting();
  logger.i(json.encode(nextMeeting.toJson()));

  final token = Platform.environment['TELEGRAM_BOT_TOKEN'];
  final teledart = TeleDart(Telegram(token), Event());
  // teledart.telegram.sendMessage(_mobileDevGroupChatId, 'Hey MobileDev-Club :)');

  final bot = await teledart.start();
  botName = bot.username;

  sendMeetingAnnouncement(teledart, await db.getNextMeeting());
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
      _handleNewGroupMember(teledart, message, botName, newMember);
    }
  });

  // The user started the bot privately.
  teledart
      .onCommand('start')
      .onlyInPrivateChats(teledart, botName)
      .listen((message) => _handleStartCommand(teledart, message));

  // The user entered a `/missing` command.
  teledart
      .onCommand('missing')
      .onlyInPrivateChats(teledart, botName)
      .listen((message) => _handleMissingCommand(teledart, message));

  return;
}

/// A new user joined the group.
void _handleNewGroupMember(
    TeleDart teledart, Message message, String botName, User newMember) async {
  logger.i('A new user joined a chat.');
  await welcomeNewMemberInGroup(newMember);
}

/// A user sent `/start` in a private chat.
void _handleStartCommand(TeleDart teledart, Message message) async {
  // TODO(marcelgarus): Remember that the user `message.from.id` has private chat `message.chat.id` with us.
  await welcomeNewMemberPrivately(message.from);
}

/// A user sent `/missing` in a private chat.
void _handleMissingCommand(TeleDart teledart, Message message) async {
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
