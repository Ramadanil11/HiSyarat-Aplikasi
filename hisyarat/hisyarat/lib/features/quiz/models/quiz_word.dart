class QuizWord {
  final String word;
  final String category;

  const QuizWord({required this.word, required this.category});

  List<String> get letters => word.split('');

  int get length => word.length;

  String currentLetter(int index) => letters[index];
}
