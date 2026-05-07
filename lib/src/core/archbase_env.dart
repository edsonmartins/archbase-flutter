/// Ambientes suportados de forma padronizada.
enum ArchbaseEnv {
  dev,
  homolog,
  prod;

  bool get isDev => this == ArchbaseEnv.dev;
  bool get isHomolog => this == ArchbaseEnv.homolog;
  bool get isProd => this == ArchbaseEnv.prod;
}
