import 'dart:convert';
import 'dart:io';

import 'package:dartx/dartx.dart';
import 'package:teledart/model.dart';
import 'package:teledart/teledart.dart';
import 'package:teledart/telegram.dart';
import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_text_patterns.dart';

import 'data.dart';
import 'utils.dart';

const _mobileDevGroupChatId = -421105343;

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

  await initDb();

  final nextMeeting = await meetingBloc.getNextMeeting().first;
  logger.i(json.encode(nextMeeting.toJson()));

  final token = Platform.environment['TELEGRAM_BOT_TOKEN'];
  final teledart = TeleDart(Telegram(token), Event());
  // teledart.telegram.sendMessage(_mobileDevGroupChatId, 'Hey MobileDev-Club :)');

  final bot = await teledart.start();
  final botName = bot.username;

  _sendMeetingAnnouncement(teledart, await meetingBloc.getNextMeeting().first);
  teledart.onCallbackQuery().listen((callback) {
    if (callback.data == _callbackMeetingCantParticipate) {
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

// Because we can't initiate private chats with users, we welcome the user in
// the group and encourage him/her to text the bot privately.
void _onUserJoined(TeleDart teledart, User user) {
  // teledart.telegram.sendMessage(user., 'Welcome to the MobileDev club!');

  // teledart.onCommand('missing')
  //   .listen((message) => teledart.replyMessage(message, "What a pity. But I'll remember that."));
}

const _callbackMeetingCantParticipate = 'meeting_cantParticipate';
void _sendMeetingAnnouncement(
  TeleDart teledart,
  Meeting meeting,
) async {
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
    _mobileDevGroupChatId,
    '''
Next meeting: ${_meetingTimePattern.format(time)}\n
Participants: $participants
'''
        .trim(),
    reply_markup: InlineKeyboardMarkup(
      inline_keyboard: [
        [
          InlineKeyboardButton(
            text: "I can't participate 😢",
            callback_data: _callbackMeetingCantParticipate,
          ),
        ],
      ],
    ),
  );
}

/// Because we can't initiate private chats with users, we welcome new users in
/// the group and encourage them to text us privately.
void _handleNewGroupMember(
    TeleDart teledart, Message message, String botName, User newMember) async {
  logger.i('A new user joined a chat.');
  await teledart.telegram.sendMessage(
    message.chat.id,
    'Hi, ${newMember.first_name}! Welcome to the MobileDev club! 🐰🥚\n'
    'Please text me privately at @$botName.',
  );
}

/// Handles a user initiating a conversation with us. Only called in private
/// chats.
void _handleStartCommand(TeleDart teledart, Message message) async {
  await teledart.telegram.sendMessage(message.chat.id,
      'Hi there! TODO: I should tell you something about my commands.');
}

/// The user entered the `/missing` command to indicate they will miss the next
/// meeting.
void _handleMissingCommand(TeleDart teledart, Message message) async {
  await teledart.telegram
      .sendMessage(message.chat.id, 'You break my heart! 💔😥');
  // TODO: remember the user will be missing
}

// - Anwesenheitsliste
// - Erinnern fürs nächste Treffen
// - Essensbestellung samt Countdown
//   - automatisch Geld anfragen? https://paypal.me/marcelgarus/8,30EUR
//   - verschiedene Angebotslisten: MobileDev vs. Spiele
// - Ideensammlung
// - Help
