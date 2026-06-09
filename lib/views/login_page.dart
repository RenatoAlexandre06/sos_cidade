import 'package:flutter/material.dart';
import 'cidadao_page.dart';
import 'dashboard_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _senhaController = TextEditingController();
  bool _ocultarSenha = true;

  @override
  void dispose() {
    _senhaController.dispose();
    super.dispose();
  }

  void _fazerLoginPrefeitura() {
    final senhaDigitada = _senhaController.text.trim();
    
    if (senhaDigitada == 'admin123') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const DashboardPage()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Senha incorreta! Acesso negado.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _entrarComoCidadao() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const CidadaoPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, 
      child: Scaffold(
        backgroundColor: Colors.blue, 
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 40),
              const Icon(Icons.location_city, size: 80, color: Colors.white),
              const SizedBox(height: 16),
              const Text(
                'SOS Cidade',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.5),
              ),
              const SizedBox(height: 40),
              
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    children: [
                      const TabBar(
                        labelColor: Colors.blue,
                        unselectedLabelColor: Colors.grey,
                        indicatorColor: Colors.blue,
                        indicatorWeight: 3,
                        // AQUI ESTÁ A CORREÇÃO:
                        indicatorSize: TabBarIndicatorSize.tab, // Faz a linha azul ocupar toda a largura da aba
                        dividerColor: Colors.black12, // Cria uma linha de base contínua e suave
                        tabs: [
                          Tab(icon: Icon(Icons.person), text: 'Sou Cidadão'),
                          Tab(icon: Icon(Icons.admin_panel_settings), text: 'Prefeitura'),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            // ABA 1: CIDADÃO
                            Center(
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.all(24.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.volunteer_activism, size: 64, color: Colors.blueGrey),
                                    const SizedBox(height: 24),
                                    const Text(
                                      'Acesso Livre',
                                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Ajude a nossa cidade relatando problemas de forma rápida, sem precisar criar conta.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: Colors.grey, fontSize: 16),
                                    ),
                                    const SizedBox(height: 40),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(vertical: 16),
                                          backgroundColor: Colors.blue,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                        onPressed: _entrarComoCidadao,
                                        child: const Text('ENTRAR NO PORTAL', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // ABA 2: PREFEITURA
                            Center(
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.all(24.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text(
                                      'Acesso Restrito',
                                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Painel de gestão de chamados para funcionários.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: Colors.grey, fontSize: 16),
                                    ),
                                    const SizedBox(height: 32),
                                    TextField(
                                      controller: _senhaController,
                                      obscureText: _ocultarSenha,
                                      decoration: InputDecoration(
                                        labelText: 'Senha de Acesso',
                                        border: const OutlineInputBorder(),
                                        prefixIcon: const Icon(Icons.lock),
                                        suffixIcon: IconButton(
                                          icon: Icon(_ocultarSenha ? Icons.visibility : Icons.visibility_off),
                                          onPressed: () {
                                            setState(() {
                                              _ocultarSenha = !_ocultarSenha;
                                            });
                                          },
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    const Align(
                                      alignment: Alignment.centerRight,
                                      child: Text('Dica: a senha é admin123', style: TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic)),
                                    ),
                                    const SizedBox(height: 32),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(vertical: 16),
                                          backgroundColor: Colors.redAccent,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                        onPressed: _fazerLoginPrefeitura,
                                        child: const Text('ACESSAR PAINEL', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}