class Chamado {
  int? id;
  String titulo;
  String descricao;
  String categoria;
  String prioridade;
  String bairro;
  String responsavel;
  DateTime data;
  String status;
  bool isFavorito;
  String? imagemPath;
  double? latitude;
  double? longitude;
  // NOVA FLAG: Controla a sincronização com a nuvem
  bool isSincronizado; 

  Chamado({
    this.id,
    required this.titulo,
    required this.descricao,
    required this.categoria,
    required this.prioridade,
    required this.bairro,
    required this.responsavel,
    required this.data,
    required this.status,
    this.isFavorito = false,
    this.imagemPath,
    this.latitude,
    this.longitude,
    this.isSincronizado = false, // Por padrão, nasce como falso (0)
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'titulo': titulo,
      'descricao': descricao,
      'categoria': categoria,
      'prioridade': prioridade,
      'bairro': bairro,
      'responsavel': responsavel,
      'data': data.toIso8601String(),
      'status': status,
      'isFavorito': isFavorito ? 1 : 0,
      'imagemPath': imagemPath,
      'latitude': latitude,
      'longitude': longitude,
      'isSincronizado': isSincronizado ? 1 : 0, // Salva no SQLite como 1 ou 0
    };
  }

  factory Chamado.fromMap(Map<String, dynamic> map) {
    return Chamado(
      id: map['id'],
      titulo: map['titulo'],
      descricao: map['descricao'],
      categoria: map['categoria'],
      prioridade: map['prioridade'],
      bairro: map['bairro'],
      responsavel: map['responsavel'],
      data: DateTime.parse(map['data']),
      status: map['status'],
      isFavorito: map['isFavorito'] == 1,
      imagemPath: map['imagemPath'],
      latitude: map['latitude'],
      longitude: map['longitude'],
      isSincronizado: map['isSincronizado'] == 1, // Recupera do SQLite como boicote
    );
  }

  String get tempoDecorrido {
    final diferenca = DateTime.now().difference(data);
    if (diferenca.inMinutes < 60) return '${diferenca.inMinutes} minutos atrás';
    if (diferenca.inHours < 24) return '${diferenca.inHours} horas atrás';
    return '${diferenca.inDays} dias atrás';
  }

  int get pesoPrioridade {
    if (status == 'Concluído') return 0;
    switch (prioridade) {
      case 'Crítica': return 4;
      case 'Alta': return 3;
      case 'Média': return 2;
      case 'Baixa': return 1;
      default: return 0;
    }
  }
}