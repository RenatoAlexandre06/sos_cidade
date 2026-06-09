import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class MenuLateral extends StatelessWidget {
  const MenuLateral({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Drawer(
      // Usamos Column para poder fixar o copyright no fundo (rodapé)
      child: Column(
        children: [
          // O Expanded faz a lista de botões ocupar todo o espaço possível
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                DrawerHeader(
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Icon(Icons.location_city, color: Colors.white, size: 48),
                      SizedBox(height: 8),
                      Text('SOS Cidade', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                      Text('Configurações', style: TextStyle(color: Colors.white70)),
                    ],
                  ),
                ),
                SwitchListTile(
                  title: const Text('Modo Escuro (Dark Mode)'),
                  secondary: Icon(themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode),
                  value: themeProvider.isDarkMode,
                  onChanged: (value) {
                    themeProvider.toggleTheme();
                  },
                ),
              ],
            ),
          ),
          
          // --- RODAPÉ DA ABA LATERAL ---
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
            child: Column(
              children: [
                const Text(
                  'Versão 2.0.0',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  '© 2026 SOS Cidade.',
                  style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 12),
                ),
                Text(
                  'Desenvolvido pela SOS Company',
                  style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}