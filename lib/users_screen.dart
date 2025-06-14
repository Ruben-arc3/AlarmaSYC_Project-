import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<Map<String, dynamic>> _users = [];
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  bool _isAdding = false;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final response = await supabase
          .from('usuarios')
          .select('*')
          .order('numero', ascending: true);

      if (response != null) {
        setState(() {
          _users = List<Map<String, dynamic>>.from(response);
        });
      }
    } catch (e) {
      _showError('Error al cargar usuarios: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isAdding = true);
    try {
      String phoneNumber = _phoneController.text.trim();
      
      if (!phoneNumber.startsWith('+57')) {
        phoneNumber = '+57$phoneNumber';
      }

      await supabase
          .from('usuarios')
          .insert({'numero': phoneNumber});

      _phoneController.clear();
      _showMessage('Usuario agregado correctamente');
      await _loadUsers();
    } catch (e) {
      _showError('Error al agregar usuario: ${e.toString()}');
    } finally {
      setState(() => _isAdding = false);
    }
  }

  Future<void> _deleteUser(int id) async {
    try {
      await supabase
          .from('usuarios')
          .delete()
          .eq('id', id);
      
      _showMessage('Usuario eliminado correctamente');
      await _loadUsers();
    } catch (e) {
      _showError('Error al eliminar usuario: ${e.toString()}');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingrese un número de teléfono';
    }
    
    final cleaned = value.replaceAll(RegExp(r'[^0-9+]'), '');
    if (!cleaned.startsWith('+57') && !RegExp(r'^[0-9]{10}$').hasMatch(cleaned)) {
      return 'Ingrese un número válido (10 dígitos o +57...)';
    }
    
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Usuarios'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUsers,
            tooltip: 'Actualizar lista',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Card(
                    margin: const EdgeInsets.only(bottom: 20),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Agregar Nuevo Usuario',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _phoneController,
                              decoration: const InputDecoration(
                                labelText: 'Número de teléfono',
                                hintText: 'Ej: 3001234567 o +573001234567',
                                prefixText: '+57',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.phone,
                              validator: _validatePhone,
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isAdding ? null : _addUser,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                                child: _isAdding
                                    ? const CircularProgressIndicator(color: Colors.white)
                                    : const Text('AGREGAR USUARIO'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (_users.isEmpty)
                    const Center(child: Text('No hay usuarios registrados'))
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Usuarios Registrados',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ListView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: _users.length,
                          itemBuilder: (context, index) {
                            final user = _users[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                title: Text(user['numero'] ?? ''),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _deleteUser(user['id']),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                ],
              ),
            ),
    );
  }
}