import 'dart:math';

import 'package:hpi_mobiledev_bot/main.dart';
import 'package:logger/logger.dart';
import 'package:teledart/model.dart';
import 'package:teledart/src/util/http_client.dart' show HttpClientException;
import 'package:teledart/telegram.dart';

final logger = Logger(
  filter: ProductionFilter(),
);

T random<T>(List<T> items) => items[Random().nextInt(items.length)];

extension MaybeEdit on Telegram {
  // ignore_for_file: non_constant_identifier_names
  Future<Message> editMessageTextSafe(
    String text, {
    int chat_id,
    int message_id,
    String inline_message_id,
    String parse_mode,
    bool disable_web_page_preview,
    InlineKeyboardMarkup reply_markup,
  }) async {
    try {
      return await telegram.editMessageText(
        text,
        chat_id: chat_id,
        message_id: message_id,
        inline_message_id: inline_message_id,
        parse_mode: parse_mode,
        disable_web_page_preview: disable_web_page_preview,
        reply_markup: reply_markup,
      );
    } on HttpClientException catch (e) {
      if (e.cause.contains('message is not modified')) {
        // This is okay.
      } else {
        rethrow;
      }
    }
  }
}
