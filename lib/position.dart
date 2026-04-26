class Position {
  int value;

  Position([this.value = 0]);

  bool operator >(int other) => value > other;

  bool operator <(int other) => value < other;

  void plus([int other = 1]) => value += other;

  void minus([int other = 1]) => value -= other;
}
