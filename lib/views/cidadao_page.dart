import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart'; // Import do GPS
import '../models/chamado_model.dart';
import '../providers/chamado_provider.dart';
import '../widgets/menu_lateral.dart';
import '../services/notification_service.dart'; // Import das notificações

class CidadaoPage extends StatefulWidget {
  const CidadaoPage({Key? key}) : super(key: key);

  @override
  State<CidadaoPage> createState() => _CidadaoPageState();
}

class _CidadaoPageState extends State<CidadaoPage> {
  bool _exibindoFormulario = false;

  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _bairroController = TextEditingController();
  final _nomeController = TextEditingController();

  String? _imagemPath;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _tituloController.dispose();
    _descricaoController.dispose();
    _bairroController.dispose();
    _nomeController.dispose();
    super.dispose();
  }

  Future<void> _capturarImagem(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source, imageQuality: 70);
      if (pickedFile != null) {
        setState(() => _imagemPath = pickedFile.path);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao aceder à câmara/galeria: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // Lógica de captura de GPS Seguro
  Future<Position?> _determinarPosicaoAtual() async {
    bool servicoAtivo;
    LocationPermission permissao;

    servicoAtivo = await Geolocator.isLocationServiceEnabled();
    if (!servicoAtivo) {
      return Future.error('O serviço de localização (GPS) está desativado.');
    }

    permissao = await Geolocator.checkPermission();
    if (permissao == LocationPermission.denied) {
      permissao = await Geolocator.requestPermission();
      if (permissao == LocationPermission.denied) {
        return Future.error('A permissão para aceder à localização foi recusada.');
      }
    }
    
    if (permissao == LocationPermission.deniedForever) {
      return Future.error('As permissões de localização estão permanentemente recusadas.');
    } 

    return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }

  void _enviarChamado() async {
    if (_formKey.currentState!.validate()) {
      // Mostra o loading para o cidadão enquanto o GPS localiza
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      double? lat;
      double? lng;

      try {
        Position? posicao = await _determinarPosicaoAtual();
        if (posicao != null) {
          lat = posicao.latitude;
          lng = posicao.longitude;
        }
      } catch (e) {
        debugPrint("Erro ao capturar GPS, usando modo de contingência: $e");
      }

      // Fecha o loading do GPS
      if (mounted) Navigator.pop(context);

      final chamado = Chamado(
        titulo: _tituloController.text.trim(),
        descricao: _descricaoController.text.trim(),
        bairro: _bairroController.text.trim(),
        responsavel: _nomeController.text.trim(),
        imagemPath: _imagemPath,
        data: DateTime.now(),
        categoria: 'Limpeza urbana', 
        prioridade: 'Baixa',         
        status: 'Aberto',            
        isFavorito: false,
        latitude: lat,  // Coordenada capturada (ou null se falhar)
        longitude: lng, // Coordenada capturada (ou null se falhar)
      );

      if (mounted) {
        final provider = Provider.of<ChamadoProvider>(context, listen: false);

        provider.addChamado(chamado).then((_) {
          NotificationService.exibirNotificacao(
            id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
            titulo: '🚨 SOS Cidade: Chamado Registado!',
            corpo: 'A sua solicitação sobre "${chamado.titulo}" foi encaminhada com sucesso.',
          );

          setState(() {
            _exibindoFormulario = false;
            _limparFormulario();
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Chamado enviado para a prefeitura!'), backgroundColor: Colors.green),
          );
        });
      }
    }
  }

  void _limparFormulario() {
    _tituloController.clear();
    _descricaoController.clear();
    _bairroController.clear();
    _nomeController.clear();
    setState(() => _imagemPath = null);
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

  Color _getCorStatus(String status) {
    if (status == 'Concluído') return Colors.green;
    if (status == 'Em andamento') return Colors.blue;
    return Colors.orange;
  }

  // Abre o histórico de notificações do utilizador
  void _abrirCentralNotificacoes(ChamadoProvider provider) {
    provider.marcarNotificacoesComoLidas();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20))),
      builder: (context) {
        return Consumer<ChamadoProvider>(
          builder: (context, currentProvider, child) {
            final lista = currentProvider.notificacoes;
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Histórico de Alertas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                    ],
                  ),
                  const Divider(),
                  Expanded(
                    child: lista.isEmpty
                        ? const Center(child: Text('Nenhuma atualização registada ainda.', style: TextStyle(color: Colors.grey)))
                        : ListView.builder(
                            itemCount: lista.length,
                            itemBuilder: (context, index) {
                              final item = lista[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                color: Colors.blue.withOpacity(0.05),
                                child: ListTile(
                                  leading: const CircleAvatar(backgroundColor: Colors.blue, child: Icon(Icons.notifications_active, color: Colors.white, size: 20)),
                                  title: Text(item.titulo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  subtitle: Text(item.corpo, style: const TextStyle(fontSize: 13)),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildListaCidadao(ChamadoProvider provider) {
    final chamados = provider.chamados;
    final abertos = chamados.where((c) => c.status == 'Aberto').length;
    final andamento = chamados.where((c) => c.status == 'Em andamento').length;
    final concluidos = chamados.where((c) => c.status == 'Concluído').length;

    return RefreshIndicator(
      onRefresh: () async => await provider.loadChamados(),
      child: ListView(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue.withOpacity(0.1),
            child: const Column(
              children: [
                Text('Painel de Acompanhamento', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                SizedBox(height: 4),
                Text('Veja abaixo o andamento das solicitações da sua comunidade', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildCardResumo('Abertos', abertos, Colors.orange, Icons.folder_open),
                _buildCardResumo('Em Andamento', andamento, Colors.blue, Icons.autorenew),
                _buildCardResumo('Concluídos', concluidos, Colors.green, Icons.check_circle),
              ],
            ),
          ),
          const Divider(),
          if (chamados.isEmpty)
            const Padding(padding: EdgeInsets.all(32.0), child: Center(child: Text('Nenhuma solicitação registada ainda.')))
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: chamados.length,
              itemBuilder: (context, index) {
                final chamado = chamados[index];
                final corStatus = _getCorStatus(chamado.status);

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: corStatus.withOpacity(0.2),
                      child: Icon(_getIconeCategoria(chamado.categoria), color: corStatus),
                    ),
                    title: Text(chamado.titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(chamado.bairro),
                            if (chamado.imagemPath != null) ...[
                              const SizedBox(width: 6),
                              const Icon(Icons.image, size: 14, color: Colors.blueGrey),
                            ]
                          ],
                        ),
                        Text(chamado.tempoDecorrido, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: corStatus.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                      child: Text(chamado.status, style: TextStyle(color: corStatus, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildFormularioCidadao() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => setState(() => _exibindoFormulario = false)),
                const Text('Nova Solicitação', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _tituloController,
              decoration: const InputDecoration(labelText: 'O que aconteceu? (Ex: Poste sem luz)', border: OutlineInputBorder()),
              validator: (value) => value == null || value.trim().isEmpty ? 'Campo obrigatório' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descricaoController,
              decoration: const InputDecoration(labelText: 'Explique em detalhes o problema', border: OutlineInputBorder()),
              maxLines: 4,
              validator: (value) => value == null || value.trim().isEmpty ? 'Campo obrigatório' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _bairroController,
              decoration: const InputDecoration(labelText: 'Bairro / Localidade', border: OutlineInputBorder()),
              validator: (value) => value == null || value.trim().isEmpty ? 'Campo obrigatório' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nomeController,
              decoration: const InputDecoration(labelText: 'Seu Nome Completo', border: OutlineInputBorder()),
              validator: (value) => value == null || value.trim().isEmpty ? 'Campo obrigatório' : null,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(4)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Anexar Foto do Local (Opcional)', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _imagemPath != null
                      ? Stack(
                          alignment: Alignment.topRight,
                          children: [
                            ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(File(_imagemPath!), height: 180, width: double.infinity, fit: BoxFit.cover)),
                            CircleAvatar(backgroundColor: Colors.black54, child: IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => setState(() => _imagemPath = null)))
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton.icon(onPressed: () => _capturarImagem(ImageSource.camera), icon: const Icon(Icons.camera_alt), label: const Text('Câmara')),
                            ElevatedButton.icon(onPressed: () => _capturarImagem(ImageSource.gallery), icon: const Icon(Icons.photo_library), label: const Text('Galeria')),
                          ],
                        ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), backgroundColor: Colors.blue, foregroundColor: Colors.white),
              onPressed: _enviarChamado,
              child: const Text('ENVIAR PARA A PREFEITURA', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChamadoProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('SOS Cidade - Cidadão'),
            centerTitle: true,
            actions: [
              // Ícone de notificações com o badge vermelho para não lidas
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Badge(
                  label: Text(provider.contagemNaoLidas.toString()),
                  isLabelVisible: provider.contagemNaoLidas > 0,
                  backgroundColor: Colors.red,
                  child: IconButton(
                    icon: const Icon(Icons.notifications),
                    onPressed: () => _abrirCentralNotificacoes(provider),
                  ),
                )       
              )
            ],
          ),
          drawer: const MenuLateral(),
          body: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _exibindoFormulario
                ? _buildFormularioCidadao()
                : provider.isLoading 
                    ? const Center(child: CircularProgressIndicator()) 
                    : _buildListaCidadao(provider),
          ),
          floatingActionButton: !_exibindoFormulario
              ? FloatingActionButton.extended(
                  onPressed: () => setState(() => _exibindoFormulario = true),
                  label: const Text('Reportar Problema'),
                  icon: const Icon(Icons.add_comment),
                  backgroundColor: Colors.blue,
                )
              : null,
        );
      },
    );
  }

  Widget _buildCardResumo(String titulo, int valor, Color cor, IconData icone) {
    return Expanded(
      child: Card(
        elevation: 1,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            children: [
              Icon(icone, color: cor, size: 20),
              const SizedBox(height: 4),
              Text(valor.toString(), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: cor)),
              Text(titulo, style: const TextStyle(fontSize: 10), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
