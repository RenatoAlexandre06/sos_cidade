import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/chamado_model.dart';
import '../providers/chamado_provider.dart';
import '../services/notification_service.dart'; 

class CadastroPage extends StatefulWidget {
  final Chamado? chamadoParaEditar;

  const CadastroPage({Key? key, this.chamadoParaEditar}) : super(key: key);

  @override
  State<CadastroPage> createState() => _CadastroPageState();
}

class _CadastroPageState extends State<CadastroPage> {
  // Variáveis para os campos editáveis
  late String _statusSelecionado;
  late String _prioridadeSelecionada;
  late String _categoriaSelecionada;
  bool _isFavorito = false; // Controle local do estado de favorito

  final List<String> _categorias = ['Trânsito', 'Iluminação', 'Saneamento', 'Segurança', 'Limpeza urbana', 'Desastre natural'];
  final List<String> _prioridades = ['Baixa', 'Média', 'Alta', 'Crítica'];
  final List<String> _statusOpcoes = ['Aberto', 'Em andamento', 'Concluído'];

  @override
  void initState() {
    super.initState();
    _statusSelecionado = widget.chamadoParaEditar?.status ?? 'Aberto';
    _prioridadeSelecionada = widget.chamadoParaEditar?.prioridade ?? 'Baixa';
    _categoriaSelecionada = widget.chamadoParaEditar?.categoria ?? 'Limpeza urbana';
    _isFavorito = widget.chamadoParaEditar?.isFavorito ?? false; // Inicializa o favorito
  }

  IconData _getIconeCategoria(String categoria) {
    switch (categoria.toLowerCase()) {
      case 'trânsito': return Icons.traffic;
      case 'iluminação': return Icons.lightbulb;
      case 'saneamento': return Icons.water_drop;
      case 'segurança': return Icons.local_police;
      case 'limpeza urbana': return Icons.delete;
      case 'desastre natural': return Icons.storm;
      default: return Icons.report_problem;
    }
  }

  Color _getCorPrioridade(String prioridade) {
    if (prioridade == 'Crítica') return Colors.red;
    if (prioridade == 'Alta') return Colors.orange;
    if (prioridade == 'Média') return Colors.blue;
    if (prioridade == 'Baixa') return Colors.grey;
    return Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
  }

  Color _getCorStatus(String status) {
    if (status == 'Concluído') return Colors.green;
    if (status == 'Em andamento') return Colors.blue;
    if (status == 'Aberto') return Colors.orange;
    return Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
  }

  void _atualizarChamado() {
    if (widget.chamadoParaEditar != null) {
      final chamadoAtualizado = Chamado(
        id: widget.chamadoParaEditar!.id,
        titulo: widget.chamadoParaEditar!.titulo,
        descricao: widget.chamadoParaEditar!.descricao,
        bairro: widget.chamadoParaEditar!.bairro,
        responsavel: widget.chamadoParaEditar!.responsavel,
        data: widget.chamadoParaEditar!.data,
        imagemPath: widget.chamadoParaEditar!.imagemPath,
        categoria: _categoriaSelecionada,
        prioridade: _prioridadeSelecionada,
        status: _statusSelecionado,
        isFavorito: _isFavorito,
        latitude: widget.chamadoParaEditar!.latitude,
        longitude: widget.chamadoParaEditar!.longitude
      );

      final provider = Provider.of<ChamadoProvider>(context, listen: false);

      provider.updateChamado(chamadoAtualizado).then((_) {
        String tituloNotif = '🔄 Atualização em: ${chamadoAtualizado.titulo}';
        String corpoNotif = 'A prefeitura alterou o status para [$_statusSelecionado] com prioridade [$_prioridadeSelecionada].';

        NotificationService.exibirNotificacao(
          id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          titulo: tituloNotif,
          corpo: corpoNotif,
        );

        provider.addNotificacao(tituloNotif, corpoNotif);

        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chamado atualizado e cidadão notificado!'), backgroundColor: Colors.green),
        );
      }).catchError((error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString()), backgroundColor: Colors.red),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final chamado = widget.chamadoParaEditar;

    return Scaffold(
      appBar: AppBar(
        title: Text(chamado == null ? 'Novo Chamado' : 'Gerir Chamado'),
        // AQUI ESTÁ A ESTRELA DE FAVORITO TOCÁVEL NO TOPO DA TELA
        actions: [
          if (chamado != null)
            IconButton(
              icon: Icon(
                _isFavorito ? Icons.star : Icons.star_border,
                color: _isFavorito ? Colors.amber : Colors.white70,
                size: 28,
              ),
              onPressed: () {
                setState(() {
                  _isFavorito = !_isFavorito;
                });
                // Dá um feedback visual rápido para o usuário
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(_isFavorito ? 'Adicionado aos Favoritos!' : 'Removido dos Favoritos.'),
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Dados da Denúncia", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blue)),
            const Divider(),
            _buildInfoCard("Título", chamado?.titulo ?? "Sem título"),
            _buildInfoCard("Bairro", chamado?.bairro ?? "Não informado"),
            _buildInfoCard("Responsável", chamado?.responsavel ?? "Anônimo"),
            _buildInfoCard("Descrição", chamado?.descricao ?? "Sem descrição"),
            
            if (chamado?.imagemPath != null) ...[
              const SizedBox(height: 10),
              const Text("Evidência Visual:", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(File(chamado!.imagemPath!), height: 200, width: double.infinity, fit: BoxFit.cover),
              ),
            ],

            const SizedBox(height: 30),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Ações da Prefeitura", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green)),
                ElevatedButton.icon(
                  onPressed: _analisarComIA,
                  icon: const Icon(Icons.auto_awesome, color: Colors.amber),
                  label: const Text('Análise IA'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                ),
              ],
            ),
            const Divider(),
            
            DropdownButtonFormField<String>(
              value: _categoriaSelecionada,
              decoration: const InputDecoration(labelText: "Categoria", border: OutlineInputBorder()),
              items: _categorias.map((String cat) => DropdownMenuItem(
                value: cat, 
                child: Row(
                  children: [
                    Icon(_getIconeCategoria(cat), color: Colors.blueGrey, size: 20),
                    const SizedBox(width: 10),
                    Text(cat),
                  ],
                )
              )).toList(),
              onChanged: (val) => setState(() => _categoriaSelecionada = val!),
            ),
            const SizedBox(height: 15),

            DropdownButtonFormField<String>(
              value: _prioridadeSelecionada,
              decoration: const InputDecoration(labelText: "Prioridade", border: OutlineInputBorder()),
              items: _prioridades.map((String prio) => DropdownMenuItem(
                value: prio, 
                child: Text(prio, style: TextStyle(color: _getCorPrioridade(prio), fontWeight: FontWeight.bold))
              )).toList(),
              onChanged: (val) => setState(() => _prioridadeSelecionada = val!),
            ),
            const SizedBox(height: 15),

            DropdownButtonFormField<String>(
              value: _statusSelecionado,
              decoration: const InputDecoration(labelText: "Status do Chamado", border: OutlineInputBorder()),
              items: _statusOpcoes.map((String stat) => DropdownMenuItem(
                value: stat, 
                child: Text(stat, style: TextStyle(color: _getCorStatus(stat), fontWeight: FontWeight.bold))
              )).toList(),
              onChanged: (val) => setState(() => _statusSelecionado = val!),
            ),

            const SizedBox(height: 30),
            
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                onPressed: _atualizarChamado,
                child: const Text("Atualizar Chamado", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
  //Lógica da IA que foi implementada
  void _analisarComIA() {
    final textoRelato = "${widget.chamadoParaEditar?.titulo ?? ''} ${widget.chamadoParaEditar?.descricao ?? ''}".toLowerCase();
    
    String novaCategoria = _categoriaSelecionada;
    String novaPrioridade = _prioridadeSelecionada;
    String justificativa = 'A IA não detetou padrões críticos, triagem manual recomendada.';

    if (textoRelato.contains('choque') || textoRelato.contains('fogo') || textoRelato.contains('fio') || textoRelato.contains('desab') || textoRelato.contains('armado')) {
      novaCategoria = 'Segurança';
      novaPrioridade = 'Crítica';
      justificativa = 'Detetado risco iminente à vida (fogo, choque ou desabamento).';
    } else if (textoRelato.contains('buraco') || textoRelato.contains('asfalto') || textoRelato.contains('semaforo') || textoRelato.contains('semáforo')) {
      novaCategoria = 'Trânsito';
      novaPrioridade = 'Alta';
      justificativa = 'Identificados problemas de infraestrutura viária e tráfego.';
    } else if (textoRelato.contains('esgoto') || textoRelato.contains('vazamento') || textoRelato.contains('cano') || textoRelato.contains('fede') || textoRelato.contains('água')) {
      novaCategoria = 'Saneamento';
      novaPrioridade = 'Alta';
      justificativa = 'Termos associados a risco de saúde pública e saneamento detetados.';
    } else if (textoRelato.contains('lixo') || textoRelato.contains('entulho') || textoRelato.contains('rato') || textoRelato.contains('mato')) {
      novaCategoria = 'Limpeza urbana';
      novaPrioridade = 'Média';
      justificativa = 'Detetado acúmulo de resíduos ou pragas.';
    } else if (textoRelato.contains('luz') || textoRelato.contains('escur') || textoRelato.contains('poste') || textoRelato.contains('lampada') || textoRelato.contains('lâmpada')) {
      novaCategoria = 'Iluminação';
      novaPrioridade = 'Média';
      justificativa = 'Identificados problemas com a iluminação pública local.';
    }

    setState(() {
      if (_categorias.contains(novaCategoria)) _categoriaSelecionada = novaCategoria;
      _prioridadeSelecionada = novaPrioridade;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.auto_awesome, color: Colors.amber),
            const SizedBox(width: 8),
            Expanded(child: Text('Sugestão IA: $justificativa', style: const TextStyle(fontWeight: FontWeight.bold))),
          ],
        ),
        backgroundColor: Colors.deepPurple,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildInfoCard(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          Text(value, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}