import 'package:meta/meta.dart';

import '../utils.dart';

class EmotionalAttachment {
  const EmotionalAttachment._({
    @required this.singularName,
    @required this.pluralName,
    @required this.happyUrls,
    @required this.sadUrls,
  });

  factory EmotionalAttachment.fromJson(dynamic name) {
    return emotionalAttachments.singleWhere((a) => a.pluralName == name,
            orElse: () => null) ??
        (throw StateError('Unsupported emotional attachment: $name'));
  }

  final String singularName;
  final String pluralName;
  final List<String> happyUrls;
  final List<String> sadUrls;

  @override
  String toString() => singularName;

  dynamic toJson() => pluralName;

  String randomHappy() => random(happyUrls);
  String randomSad() => random(sadUrls);
}

const emotionalAttachments = [
  dogs,
  cats,
];

const dogs = EmotionalAttachment._(
  singularName: 'dog',
  pluralName: 'dogs',
  happyUrls: [
    'https://i.imgflip.com/4a8he.jpg',
  ],
  sadUrls: [
    'https://www.dailydot.com/wp-content/uploads/c39/18/3a8988f1f6257a137709c800dfd83d4d-1024x512.jpg',
    'https://media.breitbart.com/media/2015/04/enhanced-buzz-wide-6382-1329860109-8-640x427.jpg',
    'https://media.npr.org/assets/img/2015/08/21/istock_000010838061_large_sq-80d63c66ead97de497285063d92809553dcd16a7-s800-c85.jpg',
    'https://vignette3.wikia.nocookie.net/animaljam/images/6/6b/Sad_puppy.png/revision/latest?cb=20130806142646',
    'https://ququ-media.com/wp-content/uploads/2016/12/sad-puppy-wallpaper.jpg',
    'https://pbs.twimg.com/media/CEHMiIhVAAEnSwE.jpg',
  ],
);

const cats = EmotionalAttachment._(
  singularName: 'cat',
  pluralName: 'cats',
  happyUrls: [
    'https://media.discordapp.net/attachments/698123074817622046/709877801871868014/sfta1zf54ey41.png?width=506&height=674',
  ],
  sadUrls: [
    'https://www.womansworld.com/wp-content/uploads/2019/05/sad-cat.jpg',
    'https://thypix.com/wp-content/uploads/sad-cat-7.jpg',
  ],
);
