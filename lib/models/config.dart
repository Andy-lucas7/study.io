class Config {
  final String theme;
  final String environment;
  final int volume;

  Config({
    required this.theme,
    required this.environment,
    required this.volume,
  });

  factory Config.fromMap(Map<String, dynamic> map) {
    return Config(
      theme: map['theme'],
      environment: map['environment'],
      volume: map['volume'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'theme': theme,
      'environment': environment,
      'volume': volume,
    };
  }
}
