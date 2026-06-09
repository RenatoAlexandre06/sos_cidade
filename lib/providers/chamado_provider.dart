import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Necessário para ouvir a nuvem
import '../models/chamado_model.dart';
import '../models/notificacao_model.dart';
import '../database/database_helper.dart';
import '../services/firebase_service.dart';

class ChamadoProvider with ChangeNotifier {
  List<Chamado> _chamados = [];
  List<Notificacao> _notificacoes = [];
  bool _isLoading = false;

  // Instância do nosso "carteiro" da nuvem
  final FirebaseService _firebaseService = FirebaseService();

  List<Chamado> get chamados => _chamados;
  List<Notificacao> get notificacoes => _notificacoes;
  bool get isLoading => _isLoading;

  int get contagemNaoLidas => _notificacoes.where((n) => !n.lida).length;

  // ==========================================
  // CARREGAMENTO INICIAL
  // ==========================================
  Future<void> loadChamados() async {
    _isLoading = true;
    notifyListeners();

    // Carrega tudo do SQLite instantaneamente (100% Offline e Rápido)
    _chamados = await DatabaseHelper.instance.fetchChamados();
    _notificacoes = await DatabaseHelper.instance.fetchNotificacoes();

    _isLoading = false;
    notifyListeners();

    // Dispara a verificação com a nuvem em background
    _sincronizarPendentes();
  }

  // ==========================================
  // AÇÕES DO UTILIZADOR (ENVIO / ATUALIZAÇÃO)
  // ==========================================
  Future<void> addChamado(Chamado chamado) async {
    chamado.isSincronizado = false; // Nasce pendente
    
    int id = await DatabaseHelper.instance.insertChamado(chamado);
    chamado.id = id;
    
    _chamados.insert(0, chamado);
    notifyListeners();

    _sincronizarPendentes();
  }

  Future<void> updateChamado(Chamado chamado) async {
    chamado.isSincronizado = false; // Modificou, fica pendente de subir
    
    await DatabaseHelper.instance.updateChamado(chamado);
    
    int index = _chamados.indexWhere((c) => c.id == chamado.id);
    if (index != -1) {
      _chamados[index] = chamado;
      notifyListeners();
    }

    _sincronizarPendentes();
  }

  // ==========================================
  // O MOTOR DE SINCRONIZAÇÃO (SQLITE -> NUVEM)
  // ==========================================
  Future<void> _sincronizarPendentes() async {
    final pendentes = _chamados.where((c) => !c.isSincronizado).toList();

    for (var chamado in pendentes) {
      try {
        await _firebaseService.sincronizarChamado(chamado);
        
        // Se chegou aqui, o Firebase confirmou! Marca como resolvido no SQLite.
        chamado.isSincronizado = true;
        await DatabaseHelper.instance.updateChamado(chamado);
      } catch (e) {
        debugPrint('Aguardando rede para sincronizar o chamado ${chamado.id}: $e');
      }
    }
    notifyListeners();
  }

  // ==========================================
  // ESCUTA EM TEMPO REAL (NUVEM -> SQLITE)
  // ==========================================
  void escutarChamadosEmTempoReal() {
    FirebaseFirestore.instance.collection('chamados').snapshots().listen((snapshot) async {
      for (var change in snapshot.docChanges) {
        final dadosNuvem = change.doc.data();
        if (dadosNuvem != null) {
          
          // Formata os dados da nuvem para o SQLite entender
          final mapFormatado = Map<String, dynamic>.from(dadosNuvem);
          mapFormatado['id'] = int.tryParse(change.doc.id) ?? 0;
          mapFormatado['isSincronizado'] = 1; // Já veio da nuvem, está sincronizado
          mapFormatado['isFavorito'] = mapFormatado['isFavorito'] == true ? 1 : 0;

          final chamadoNuvem = Chamado.fromMap(mapFormatado);

          if (change.type == DocumentChangeType.added) {
            final localExists = _chamados.any((c) => c.id == chamadoNuvem.id);
            if (!localExists) {
              await DatabaseHelper.instance.insertChamado(chamadoNuvem);
            }
          } else if (change.type == DocumentChangeType.modified) {
            await DatabaseHelper.instance.updateChamado(chamadoNuvem);
          }
        }
      }

      // Recarrega a UI com os dados fresquinhos
      _chamados = await DatabaseHelper.instance.fetchChamados();
      notifyListeners();
    });
  }

  // ==========================================
  // SISTEMA DE NOTIFICAÇÕES
  // ==========================================
  Future<void> addNotificacao(String titulo, String corpo) async {
    final novaNotificacao = Notificacao(
      titulo: titulo,
      corpo: corpo,
      data: DateTime.now(),
      lida: false,
    );
    await DatabaseHelper.instance.insertNotificacao(novaNotificacao);
    _notificacoes.insert(0, novaNotificacao);
    notifyListeners();
  }

  Future<void> marcarNotificacoesComoLidas() async {
    await DatabaseHelper.instance.marcarTodasComoLidas();
    for (var n in _notificacoes) {
      n.lida = true;
    }
    notifyListeners();
  }
}