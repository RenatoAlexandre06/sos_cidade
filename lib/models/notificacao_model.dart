class Notificacao {
  int? id;
  String titulo;
  String corpo;
  DateTime data;
  bool lida;

  Notificacao({
    this.id,
    required this.titulo,
    required this.corpo,
    required this.data,
    this.lida = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'titulo': titulo,
      'corpo': corpo,
      'data': data.toIso8601String(),
      'lida': lida ? 1 : 0,
    };
  }

  factory Notificacao.fromMap(Map<String, dynamic> map) {
    return Notificacao(
      id: map['id'],
      titulo: map['titulo'],
      corpo: map['corpo'],
      data: DateTime.parse(map['data']),
      lida: map['lida'] == 1,
    );
  }
}