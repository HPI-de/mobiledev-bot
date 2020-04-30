import 'dart:math';

import 'package:logger/logger.dart';

final logger = Logger(
  filter: ProductionFilter(),
);

T random<T>(List<T> items) => items[Random().nextInt(items.length)];
