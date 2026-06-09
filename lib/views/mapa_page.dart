import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chamado_provider.dart';
import '../models/chamado_model.dart';
import '../widgets/menu_lateral.dart'; 
import 'cadastro_page.dart';
import 'mapa_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String _filtroAtual = 'Todos'; 
  
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _abaSelecionada = 0;

  // Controlador do PageView
  late PageController _pageController;

  // Inicialização do Controlador
  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _abaSelecionada);
  }

  @override
  void dispose() {
    // Limpeza do Controlador
    _pageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  String _formatarDataHora(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} às ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
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

  Color _getCorChamado(Chamado chamado) {
    if (chamado.status == 'Concluído') return Colors.green;
    if (chamado.prioridade == 'Crítica') return Colors.red;
    if (chamado.status == 'Em andamento') return Colors.blue;
    if (chamado.status == 'Aberto') return Colors.orange;
    return Colors.grey;
  }
  
  Color _getCorTextoStatus(String status, BuildContext context) {
    if (status == 'Concluído') return Colors.green;
    if (status == 'Em andamento') return Colors.blue;
    if (status == 'Aberto') return Colors.orange;
    return Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey;
  }

  Color _getCorPrioridade(String prioridade, BuildContext context) {
    if (prioridade == 'Crítica') return Colors.red;
    if (prioridade == 'Alta') return Colors.orange;
    if (prioridade == 'Média') return Colors.blue;
    if (prioridade == 'Baixa') return Colors.grey;
    return Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
  }

  Widget _buildEstatisticas(ChamadoProvider provider) {
    final chamados = provider.chamados;
    final total = chamados.length;

    if (total == 0) return const Center(child: Text('Nenhum dado para analisar.'));

    final concluidos = chamados.where((c) => c.status == 'Concluído').length;
    final andamento = chamados.where((c) => c.status == 'Em andamento').length;
    final abertos = chamados.where((c) => c.status == 'Aberto').length;

    Map<String, int> contagemBairros = {};
    for (var chamado in chamados) {
      contagemBairros[chamado.bairro] = (contagemBairros[chamado.bairro] ?? 0) + 1;
    }
    
    var rankingBairros = contagemBairros.entries.toList();
    rankingBairros.sort((a, b) => b.value.compareTo(a.value));

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        const Text('Visão Geral dos Status', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        
        Container(
          height: 30,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(15), color: Colors.grey.shade300),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Row(
              children: [
                if (concluidos > 0) Expanded(flex: concluidos, child: Container(color: Colors.green)),
                if (andamento > 0) Expanded(flex: andamento, child: Container(color: Colors.blue)),
                if (abertos > 0) Expanded(flex: abertos, child: Container(color: Colors.orange)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildLegendaGrafico('Concluídos', concluidos, Colors.green),
            _buildLegendaGrafico('Em And.', andamento, Colors.blue),
            _buildLegendaGrafico('Abertos', abertos, Colors.orange),
          ],
        ),

        const Divider(height: 48, thickness: 2),

        const Text('Ranking de Bairros', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),

        ...List.generate(rankingBairros.length, (index) {
          final bairro = rankingBairros[index].key;
          final quantidade = rankingBairros[index].value;
          
          Color corMedalha = Colors.grey.shade400;
          IconData iconeMedalha = Icons.looks_4;
          if (index == 0) { corMedalha = Colors.amber; iconeMedalha = Icons.looks_one; }
          else if (index == 1) { corMedalha = Colors.grey.shade400; iconeMedalha = Icons.looks_two; }
          else if (index == 2) { corMedalha = Colors.brown.shade300; iconeMedalha = Icons.looks_3; }

          return Card(
            elevation: index < 3 ? 3 : 1,
            child: ListTile(
              leading: Icon(iconeMedalha, color: corMedalha, size: 32),
              title: Text(bairro, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                child: Text('$quantidade chamados', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildLegendaGrafico(String titulo, int valor, Color cor) {
    return Row(
      children: [
        CircleAvatar(radius: 6, backgroundColor: cor),
        const SizedBox(width: 4),
        Text('$titulo ($valor)'),
      ],
    );
  }

  Widget _buildListaChamados(ChamadoProvider provider) {
    final total = provider.chamados.length;
    final abertos = provider.chamados.where((c) => c.status == 'Aberto').length;
    final andamento = provider.chamados.where((c) => c.status == 'Em andamento').length;
    final concluidos = provider.chamados.where((c) => c.status == 'Concluído').length;
    final criticos = provider.chamados.where((c) => c.prioridade == 'Crítica' && c.status != 'Concluído').length;
    final favoritosCount = provider.chamados.where((c) => c.isFavorito).length;

    List<Chamado> chamadosFiltrados = provider.chamados;
    
    if (_filtroAtual == 'Favoritos') {
      chamadosFiltrados = chamadosFiltrados.where((c) => c.isFavorito).toList();
    } else if (_filtroAtual == 'Crítica') {
      chamadosFiltrados = chamadosFiltrados.where((c) => c.prioridade == 'Crítica' && c.status != 'Concluído').toList();
    } else if (_filtroAtual != 'Todos') {
      chamadosFiltrados = chamadosFiltrados.where((c) => c.status == _filtroAtual).toList();
    }

    if (_searchQuery.isNotEmpty) {
      chamadosFiltrados = chamadosFiltrados.where((c) {
        final tituloMatch = c.titulo.toLowerCase().contains(_searchQuery);
        final bairroMatch = c.bairro.toLowerCase().contains(_searchQuery);
        final responsavelMatch = c.responsavel.toLowerCase().contains(_searchQuery);
        final categoriaMatch = c.categoria.toLowerCase().contains(_searchQuery);
        return tituloMatch || bairroMatch || responsavelMatch || categoriaMatch;
      }).toList();
    }

    return RefreshIndicator(
      onRefresh: () async {
        await provider.loadChamados();
      },
      child: ListView(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue.withOpacity(0.1),
            child: Column(
              children: [
                Text(
                  'Atualizado em: ${_formatarDataHora(DateTime.now())}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text('Total de chamados registados: $total'),
              ],
            ),
          ),

          const SizedBox(height: 8),

          SizedBox(
            height: 90, 
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              children: [
                _buildCard('Abertos', abertos, Colors.orange, 'Aberto', Icons.folder_open, context),
                _buildCard('Em And.', andamento, Colors.blue, 'Em andamento', Icons.autorenew, context),
                _buildCard('Concluídos', concluidos, Colors.green, 'Concluído', Icons.check_circle, context),
                _buildCard('Críticos', criticos, Colors.red, 'Crítica', Icons.warning, context),
                _buildCard('Favoritos', favoritosCount, Colors.amber, 'Favoritos', Icons.star, context),
              ],
            ),
          ),

          const SizedBox(height: 8),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Filtro: ${_filtroAtual.toUpperCase()}', style: const TextStyle(fontWeight: FontWeight.bold)),
                if (_filtroAtual != 'Todos')
                  TextButton(
                    onPressed: () => setState(() => _filtroAtual = 'Todos'),
                    child: const Text('Limpar'),
                  )
              ],
            ),
          ),

          const Divider(),

          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(opacity: animation, child: child);
            },
            child: chamadosFiltrados.isEmpty
                ? Padding(
                    key: const ValueKey('empty'),
                    padding: const EdgeInsets.all(32.0),
                    child: Center(child: Text(_filtroAtual == 'Favoritos' ? 'Nenhum chamado favorito.' : 'Nenhum chamado encontrado.')),
                  )
                : ListView.builder(
                    key: ValueKey(chamadosFiltrados.length.toString() + _filtroAtual),
                    shrinkWrap: true, 
                    physics: const NeverScrollableScrollPhysics(), 
                    itemCount: chamadosFiltrados.length,
                    itemBuilder: (context, index) {
                      final chamado = chamadosFiltrados[index];
                      final corBalao = _getCorChamado(chamado); 
                      
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: corBalao.withOpacity(0.2), 
                            child: Icon(
                              _getIconeCategoria(chamado.categoria),
                              color: corBalao,
                            ),
                          ),
                          title: Row(
                            children: [
                              // Usando Expanded para o título não estourar a tela
                              Expanded(
                                child: Text(
                                  chamado.titulo, 
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (chamado.isFavorito)
                                const Icon(Icons.star, color: Colors.amber, size: 16),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // AQUI FOI APLICADA A SUA CORREÇÃO VISUAL
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      chamado.categoria,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (chamado.imagemPath != null) ...[
                                    const SizedBox(width: 6),
                                    const Icon(Icons.image, size: 14, color: Colors.blueGrey),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                chamado.bairro, 
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(chamado.tempoDecorrido, style: const TextStyle(color: Colors.blueGrey, fontSize: 12)),
                            ],
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(chamado.prioridade, style: TextStyle(
                                color: _getCorPrioridade(chamado.prioridade, context),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              )),
                              const SizedBox(height: 4),
                              Text(chamado.status, style: TextStyle(
                                fontSize: 12, 
                                color: _getCorTextoStatus(chamado.status, context),
                                fontWeight: FontWeight.bold
                              )),
                            ],
                          ),
                          onTap: () {
                            if (chamado.status == 'Concluído') {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Chamados concluídos não podem ser editados.'), backgroundColor: Colors.red),
                              );
                            } else {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => CadastroPage(chamadoParaEditar: chamado)),
                              );
                            }
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Procurar chamados...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.white70),
                ),
                style: const TextStyle(color: Colors.white, fontSize: 16),
                cursorColor: Colors.white,
                onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
              )
            : const Text('SOS Cidade'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _searchQuery = '';
                }
              });
            },
          ),
        ],
      ),
      drawer: const MenuLateral(),
      
      // PageView
      body: Consumer<ChamadoProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) return const Center(child: CircularProgressIndicator());
          return PageView(
            controller: _pageController,
            physics: const BouncingScrollPhysics(),
            onPageChanged: (index) {
              setState(() => _abaSelecionada = index);
            },
            children: [
              _buildListaChamados(provider),
              _buildEstatisticas(provider),
              const MapaPage(),
            ],
          );
        },
      ),

      // onTap atualizado para animar o PageView
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _abaSelecionada,
        onTap: (index) {
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Chamados'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Estatísticas'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Mapa'),
        ],
      ),
    );
  }

  Widget _buildCard(String titulo, int valor, Color cor, String filtroReferencia, IconData icone, BuildContext context) {
    bool isSelected = _filtroAtual == filtroReferencia;
    
    return Container(
      width: 105,
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      child: GestureDetector(
        onTap: () => setState(() => _filtroAtual = isSelected ? 'Todos' : filtroReferencia),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          margin: EdgeInsets.all(isSelected ? 0 : 2), 
          decoration: BoxDecoration(
            color: isSelected ? cor.withOpacity(0.15) : Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isSelected ? cor : Colors.transparent, width: 2),
            boxShadow: isSelected ? [BoxShadow(color: cor.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2))] : [],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 2.0),
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
      ),
    );
  }
}