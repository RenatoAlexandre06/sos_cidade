import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/chamado_model.dart';
import '../models/notificacao_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    // NOVO NOME: Força a criação limpa para a arquitetura Offline-First
    _database = await _initDB('sos_cidade_offline_first.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 3, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    // Tabela de chamados
    await db.execute('''
      CREATE TABLE chamados (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        titulo TEXT NOT NULL,
        descricao TEXT NOT NULL,
        categoria TEXT NOT NULL,
        prioridade TEXT NOT NULL,
        bairro TEXT NOT NULL,
        responsavel TEXT NOT NULL,
        data TEXT NOT NULL,
        status TEXT NOT NULL,
        isFavorito INTEGER NOT NULL DEFAULT 0,
        imagemPath TEXT,
        latitude REAL,
        longitude REAL,
        isSincronizado INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // NOVA TABELA: Histórico de Notificações para o Cidadão
    await db.execute('''
      CREATE TABLE notificacoes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        titulo TEXT NOT NULL,
        corpo TEXT NOT NULL,
        data TEXT NOT NULL,
        lida INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  // Métodos de Chamados
  Future<int> insertChamado(Chamado chamado) async {
    final db = await instance.database;
    return await db.insert('chamados', chamado.toMap());
  }

  Future<List<Chamado>> fetchChamados() async {
    final db = await instance.database;
    final result = await db.query('chamados');
    return result.map((json) => Chamado.fromMap(json)).toList();
  }

  Future<int> updateChamado(Chamado chamado) async {
    final db = await instance.database;
    return db.update('chamados', chamado.toMap(), where: 'id = ?', whereArgs: [chamado.id]);
  }

  // NOVOS MÉTODOS: Gestão de Notificações
  Future<int> insertNotificacao(Notificacao notificacao) async {
    final db = await instance.database;
    return await db.insert('notificacoes', notificacao.toMap());
  }

  Future<List<Notificacao>> fetchNotificacoes() async {
    final db = await instance.database;
    final result = await db.query('notificacoes', orderBy: 'data DESC');
    return result.map((json) => Notificacao.fromMap(json)).toList();
  }

  Future<int> marcarTodasComoLidas() async {
    final db = await instance.database;
    return await db.update('notificacoes', {'lida': 1}, where: 'lida = 0');
  }
}