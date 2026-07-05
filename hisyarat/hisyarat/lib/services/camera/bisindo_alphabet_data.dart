// Alphabet definitions aligned with the Mendeley BISINDO image dataset.

class BisindoAlphabetData {
  BisindoAlphabetData._();

  static List<BisindoGesture> get allAlphabets => _alphabets;

  static BisindoGesture? getByLetter(String letter) {
    final upper = letter.toUpperCase();
    try {
      return _alphabets.firstWhere((gesture) => gesture.letter == upper);
    } catch (_) {
      return null;
    }
  }

  static BisindoGesture? getByIndex(int index) {
    if (index < 0 || index >= _alphabets.length) return null;
    return _alphabets[index];
  }

  static const List<BisindoGesture> _alphabets = [
    BisindoGesture(
      letter: 'A',
      description: 'Dua tangan membentuk segitiga',
      instruction:
          'Hadapkan kedua tangan. Pertemukan ujung telunjuk di atas dan arahkan kedua ibu jari ke dalam di bawah.',
      handType: HandType.twoHand,
    ),
    BisindoGesture(
      letter: 'B',
      description: 'Telunjuk kanan melintang di atas jari tangan kiri',
      instruction:
          'Buka telunjuk dan jari tengah tangan kiri. Letakkan telunjuk tangan kanan melintang menyentuh ujung keduanya.',
      handType: HandType.twoHand,
    ),
    BisindoGesture(
      letter: 'C',
      description: 'Ibu jari dan telunjuk melengkung membentuk C',
      instruction:
          'Gunakan satu tangan. Lengkungkan telunjuk dan ibu jari seperti huruf C, lalu lipat jari lainnya.',
      handType: HandType.oneHand,
    ),
    BisindoGesture(
      letter: 'D',
      description: 'Dua telunjuk dan ibu jari membentuk bidang D',
      instruction:
          'Tegakkan telunjuk satu tangan. Gunakan telunjuk tangan lain sebagai garis atas dan ibu jari sebagai sisi bawah.',
      handType: HandType.twoHand,
    ),
    BisindoGesture(
      letter: 'E',
      description: 'Tiga jari tegak dengan ibu jari dan kelingking bertemu',
      instruction:
          'Tegakkan telunjuk, tengah, dan manis. Pertemukan ujung ibu jari dengan ujung kelingking.',
      handType: HandType.oneHand,
    ),
    BisindoGesture(
      letter: 'F',
      description: 'Dua jari tegak disentuh telunjuk tangan lain',
      instruction:
          'Tegakkan telunjuk dan jari tengah satu tangan. Sentuhkan telunjuk tangan lain ke sisi jari yang tegak.',
      handType: HandType.twoHand,
    ),
    BisindoGesture(
      letter: 'G',
      description: 'Kedua lengan ditekuk membentuk sudut',
      instruction:
          'Tekuk kedua lengan dan dekatkan siku sehingga membentuk garis bersudut seperti huruf G.',
      handType: HandType.twoHand,
    ),
    BisindoGesture(
      letter: 'H',
      description: 'Kedua tangan membentuk dua garis sejajar',
      instruction:
          'Arahkan telunjuk kedua tangan mendatar berlawanan arah. Hubungkan bagian tengah dengan ibu jari.',
      handType: HandType.twoHand,
    ),
    BisindoGesture(
      letter: 'I',
      description: 'Kelingking lurus ke samping',
      instruction: 'Kepalkan satu tangan dan luruskan kelingking ke samping.',
      handType: HandType.oneHand,
    ),
    BisindoGesture(
      letter: 'J',
      description: 'Kelingking mengarah ke bawah',
      instruction:
          'Kepalkan satu tangan dengan telapak menghadap depan, lalu luruskan kelingking ke bawah.',
      handType: HandType.oneHand,
    ),
    BisindoGesture(
      letter: 'K',
      description: 'Telunjuk kanan melintang di atas telunjuk kiri',
      instruction:
          'Tegakkan telunjuk satu tangan dan letakkan telunjuk tangan lain mendatar di atasnya.',
      handType: HandType.twoHand,
    ),
    BisindoGesture(
      letter: 'L',
      description: 'Ibu jari dan telunjuk membentuk sudut L',
      instruction:
          'Gunakan satu tangan. Luruskan telunjuk ke samping dan ibu jari ke atas membentuk sudut siku-siku.',
      handType: HandType.oneHand,
    ),
    BisindoGesture(
      letter: 'M',
      description: 'Tiga jari tangan kanan menyentuh telapak kiri',
      instruction:
          'Buka telapak kiri. Tempelkan tiga jari tangan kanan pada telapak tersebut.',
      handType: HandType.twoHand,
    ),
    BisindoGesture(
      letter: 'N',
      description: 'Dua jari tangan kanan menyentuh telapak kiri',
      instruction:
          'Buka telapak kiri. Tempelkan telunjuk dan jari tengah tangan kanan pada telapak tersebut.',
      handType: HandType.twoHand,
    ),
    BisindoGesture(
      letter: 'O',
      description: 'Ibu jari dan telunjuk membentuk lingkaran',
      instruction:
          'Gunakan satu tangan. Pertemukan ujung ibu jari dan telunjuk membentuk O, luruskan jari lain ke samping.',
      handType: HandType.oneHand,
    ),
    BisindoGesture(
      letter: 'P',
      description: 'Telunjuk kanan melintang di atas telunjuk kiri',
      instruction:
          'Tegakkan telunjuk satu tangan. Letakkan telunjuk tangan lain mendatar menyentuh ujungnya.',
      handType: HandType.twoHand,
    ),
    BisindoGesture(
      letter: 'Q',
      description: 'Telunjuk menyentuh lingkaran ibu jari dan telunjuk',
      instruction:
          'Bentuk lingkaran dengan ibu jari dan telunjuk satu tangan, lalu sentuhkan telunjuk tangan lain ke bawah lingkaran.',
      handType: HandType.twoHand,
    ),
    BisindoGesture(
      letter: 'R',
      description: 'Dua telunjuk bersilang',
      instruction:
          'Luruskan telunjuk kedua tangan lalu silangkan keduanya di bagian tengah.',
      handType: HandType.twoHand,
    ),
    BisindoGesture(
      letter: 'S',
      description: 'Dua tangan membentuk dua lengkungan',
      instruction:
          'Lengkungkan ibu jari dan telunjuk kedua tangan, lalu susun berlawanan arah seperti huruf S.',
      handType: HandType.twoHand,
    ),
    BisindoGesture(
      letter: 'T',
      description: 'Telunjuk mendatar menyentuh ujung ibu jari tegak',
      instruction:
          'Tegakkan ibu jari satu tangan. Sentuhkan telunjuk tangan lain secara mendatar pada ujungnya.',
      handType: HandType.twoHand,
    ),
    BisindoGesture(
      letter: 'U',
      description: 'Ibu jari dan telunjuk membentuk lengkungan U',
      instruction:
          'Gunakan satu tangan. Arahkan telunjuk dan ibu jari ke samping berlawanan sehingga membentuk U.',
      handType: HandType.oneHand,
    ),
    BisindoGesture(
      letter: 'V',
      description: 'Telunjuk dan jari tengah terbuka membentuk V',
      instruction:
          'Gunakan satu tangan. Luruskan telunjuk dan jari tengah, lalu renggangkan membentuk V.',
      handType: HandType.oneHand,
    ),
    BisindoGesture(
      letter: 'W',
      description: 'Dua tangan membentuk garis W',
      instruction:
          'Arahkan telunjuk kedua tangan ke samping dan hubungkan bagian tengah dengan jari yang ditekuk.',
      handType: HandType.twoHand,
    ),
    BisindoGesture(
      letter: 'X',
      description: 'Dua telunjuk bersilang membentuk X',
      instruction:
          'Luruskan telunjuk kedua tangan lalu silangkan secara diagonal membentuk X.',
      handType: HandType.twoHand,
    ),
    BisindoGesture(
      letter: 'Y',
      description: 'Telunjuk dan ibu jari membentuk cabang Y',
      instruction:
          'Buka telunjuk dan ibu jari satu tangan. Sentuhkan telunjuk tangan lain pada pangkal di bawahnya.',
      handType: HandType.twoHand,
    ),
    BisindoGesture(
      letter: 'Z',
      description: 'Tangan membentuk lekukan Z statis',
      instruction:
          'Gunakan satu tangan. Tekuk pergelangan dan rapatkan jari sehingga siluet tangan membentuk lekukan seperti Z.',
      handType: HandType.oneHand,
    ),
  ];
}

class BisindoGesture {
  final String letter;
  final String description;
  final String instruction;
  final HandType handType;
  final String emoji;
  final FingerPattern fingerPattern;
  final bool hasMotion;

  const BisindoGesture({
    required this.letter,
    required this.description,
    required this.instruction,
    required this.handType,
    this.emoji = '\u{1F91F}',
    this.fingerPattern = const FingerPattern(),
    this.hasMotion = false,
  });
}

class FingerPattern {
  final bool thumb;
  final bool index;
  final bool middle;
  final bool ring;
  final bool pinky;
  final bool curved;
  final bool crossed;

  const FingerPattern({
    this.thumb = false,
    this.index = false,
    this.middle = false,
    this.ring = false,
    this.pinky = false,
    this.curved = false,
    this.crossed = false,
  });

  int get extendedCount =>
      [thumb, index, middle, ring, pinky].where((value) => value).length;
  List<bool> toList() => [thumb, index, middle, ring, pinky];

  double similarity(FingerPattern other) {
    final otherValues = other.toList();
    var matches = 0;
    for (var index = 0; index < toList().length; index++) {
      if (toList()[index] == otherValues[index]) matches++;
    }
    return matches / 5.0;
  }
}

enum HandType { oneHand, twoHand }
