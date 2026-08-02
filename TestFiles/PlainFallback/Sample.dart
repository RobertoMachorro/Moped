// Sample.dart — declared/openable by Moped but has no tokenizer.
// Should open and display as plain text with no syntax coloring.

class Greeter {
  final String name;

  Greeter(this.name);

  String greet() => 'Hello, $name!';
}

void main() {
  final greeter = Greeter('Moped');
  print(greeter.greet());
}
