import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<Map<String, dynamic>> _alertas = [];
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy HH:mm:ss');
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _loadAlertasData();
  }

  Future<void> _loadAlertasData() async {
    setState(() => _isLoading = true);
    try {
      final response = await supabase
          .from('alertas')
          .select('*')
          .order('fecha_hora', ascending: false);

      if (response != null) {
        setState(() {
          _alertas = List<Map<String, dynamic>>.from(response);
        });
      }
    } catch (e) {
      _showError('Error al cargar alertas: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteAllHistory() async {
    final confirmed = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: const Text('¿Está seguro que desea eliminar todo el historial de detecciones? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isDeleting = true);
    try {
      await supabase
          .from('alertas')
          .delete()
          .neq('id', 0);

      _showMessage('Historial eliminado correctamente');
      await _loadAlertasData();
    } catch (e) {
      _showError('Error al eliminar historial: ${e.toString()}');
    } finally {
      setState(() => _isDeleting = false);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Detecciones'),
        actions: [
          if (_alertas.isNotEmpty) ...[
            IconButton(
              icon: _isDeleting 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Icon(Icons.delete, color: Colors.red),
              onPressed: _isDeleting ? null : _deleteAllHistory,
              tooltip: 'Eliminar todo el historial',
            ),
          ],
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAlertasData,
            tooltip: 'Actualizar historial',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _alertas.isEmpty
              ? const Center(child: Text('No hay alertas registradas'))
              : RefreshIndicator(
                  onRefresh: _loadAlertasData,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _alertas.length,
                    itemBuilder: (context, index) {
                      final alerta = _alertas[index];
                      final fechaHora = DateTime.tryParse(alerta['fecha_hora'] ?? '');
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Tipo: ${alerta['tipo'] ?? 'No especificado'}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Fecha: ${fechaHora != null ? _dateFormat.format(fechaHora) : 'Fecha desconocida'}',
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}