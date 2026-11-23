/// Stable id for the one thread between two people.
/// Order of the arguments does not matter.
String conversationId(String a, String b) {
  final ids = [a, b]..sort();
  return '${ids[0]}_${ids[1]}';
}
