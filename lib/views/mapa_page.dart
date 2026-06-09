import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../providers/chamado_provider.dart';
import '../models/chamado_model.dart';
import 'cadastro_page.dart';

class MapaPage extends StatefulWidget {
  const MapaPage({Key? key}) : super(key: key);

  @override
  State<MapaPage> createState() => _MapaPageState();
}

class _MapaPageState extends State<MapaPage> {
  String _filtroCategoria = 'Todos';
  final MapController _mapController = MapController();

  // NOVO: Estado interativo da legenda (quais prioridades estão visíveis)
  final List<String> _filtrosPrioridade = ['Crítica', 'Alta', 'Média', 'Baixa'];

  Color _getCorPrioridade(String prioridade) {
    if (prioridade == 'Crítica') return Colors.red;
    if (prioridade == 'Alta') return Colors.orange;
    if (prioridade == 'Média') return Colors.blue;
    return Colors.grey;
  }

  LatLng _getCoordenadasPorBairro(String bairro) {
    final int hash = bairro.toLowerCase().trim().hashCode;
    final random = Random(hash);
    final double lat = -7.115 + (random.nextDouble() * 0.05 - 0.025);
    final double lng = -34.861 + (random.nextDouble() * 0.05 - 0.025);
    return LatLng(lat, lng);
  }

  void _mostrarDetalhes(Chamado chamado) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          height: 250,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(chamado.prioridade.toUpperCase(), style: TextStyle(color: _getCorPrioridade(chamado.prioridade), fontWeight: FontWeight.bold, fontSize: 16)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: Colors.blueGrey.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                    child: Text(chamado.status, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                  ),
                ],
              ),
              const Divider(),
              Text(chamado.titulo, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(chamado.bairro, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                ],
              ),
              const SizedBox(height: 12),
              Text(chamado.descricao, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.black87)),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 45,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context); 
                    Navigator.push(context, MaterialPageRoute(builder: (_) => CadastroPage(chamadoParaEditar: chamado)));
                  },
                  icon: const Icon(Icons.edit_location_alt),
                  label: const Text('Triar Chamado', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                ),
              )
            ],
          )
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChamadoProvider>(
      builder: (context, provider, child) {
        // LÓGICA DE FILTRAGEM DUPLA (Categoria + Legenda Interativa)
        List<Chamado> chamadosNoMapa = provider.chamados.where((c) => c.status != 'Concluído').toList();
        
        // Filtra pela Categoria do Dropdown no topo
        if (_filtroCategoria != 'Todos') {
          chamadosNoMapa = chamadosNoMapa.where((c) => c.categoria == _filtroCategoria).toList();
        }
        
        // Filtra pelos cliques na Legenda de Prioridade
        chamadosNoMapa = chamadosNoMapa.where((c) => _filtrosPrioridade.contains(c.prioridade)).toList();

        return Column(
          children: [
            // Filtro Superior de Categoria
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              color: Theme.of(context).cardColor,
              child: Row(
                children: [
                  const Icon(Icons.layers, color: Colors.blueGrey),
                  const SizedBox(width: 12),
                  const Text('Região / Área:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _filtroCategoria,
                        isExpanded: true,
                        icon: const Icon(Icons.arrow_drop_down_circle, color: Colors.blue, size: 20),
                        items: ['Todos', 'Trânsito', 'Iluminação', 'Saneamento', 'Segurança', 'Limpeza urbana', 'Desastre natural']
                            .map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 14)))).toList(),
                        onChanged: (val) => setState(() => _filtroCategoria = val!),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // O MAPA COM A LEGENDA FLUTUANTE
            Expanded(
              child: Stack(
                children: [
                  // 1. O Mapa em si
                  FlutterMap(
                    mapController: _mapController,
                    options: const MapOptions(
                      initialCenter: LatLng(-7.1150, -34.8610),
                      initialZoom: 13.0,
                      maxZoom: 18.0,
                      minZoom: 10.0,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.soscidade.app',
                      ),
                      MarkerLayer(
                        markers: chamadosNoMapa.map((chamado) {
                          final LatLng latLng = (chamado.latitude != null && chamado.longitude != null)
                              ? LatLng(chamado.latitude!, chamado.longitude!)
                              : _getCoordenadasPorBairro(chamado.bairro);
                          final cor = _getCorPrioridade(chamado.prioridade);
                          
                          return Marker(
                            point: latLng,
                            width: 45,
                            height: 45,
                            child: GestureDetector(
                              onTap: () => _mostrarDetalhes(chamado),
                              child: Icon(
                                Icons.location_pin,
                                color: cor,
                                size: 45,
                                shadows: const [Shadow(blurRadius: 10, color: Colors.black45, offset: Offset(2, 2))],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),

                  // 2. A Legenda Flutuante Interativa (Nova UI/UX)
                  Positioned(
                    bottom: 20, // Distância do rodapé
                    left: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.95), // Efeito vidro suave
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))
                        ],
                      ),
                      // O WRAP garante que não há quebra de ecrã em telemóveis pequenos
                      child: Wrap(
                        alignment: WrapAlignment.spaceEvenly,
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildLegendaInterativa(Colors.red, 'Crítica'),
                          _buildLegendaInterativa(Colors.orange, 'Alta'),
                          _buildLegendaInterativa(Colors.blue, 'Média'),
                          _buildLegendaInterativa(Colors.grey, 'Baixa'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      }
    );
  }

  // Novo Widget de Botão de Legenda Interativo
  Widget _buildLegendaInterativa(Color cor, String prioridade) {
    final bool isSelected = _filtrosPrioridade.contains(prioridade);

    return GestureDetector(
      onTap: () {
        setState(() {
          // Lógica de toggle: liga/desliga a visualização daquela prioridade
          if (isSelected) {
            // Impede de apagar o último filtro (para o mapa não ficar vazio de propósito)
            if (_filtrosPrioridade.length > 1) {
              _filtrosPrioridade.remove(prioridade);
            }
          } else {
            _filtrosPrioridade.add(prioridade);
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? cor.withOpacity(0.15) : Colors.transparent,
          border: Border.all(color: isSelected ? cor : Colors.grey.shade300, width: 1.5),
          borderRadius: BorderRadius.circular(20), // Formato de "pílula" moderno
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min, // Ajusta o botão ao tamanho do texto
          children: [
            CircleAvatar(radius: 5, backgroundColor: isSelected ? cor : Colors.grey.shade400),
            const SizedBox(width: 6),
            Text(
              prioridade,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.black87 : Colors.grey,
                decoration: isSelected ? TextDecoration.none : TextDecoration.lineThrough, // Risca o texto se desativado
              ),
            ),
          ],
        ),
      ),
    );
  }
}