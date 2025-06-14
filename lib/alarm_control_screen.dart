import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'history_screen.dart';
import 'schedule_screen.dart';
import 'users_screen.dart';

class AlarmControlScreen extends StatefulWidget {
  const AlarmControlScreen({super.key});

  @override
  State<AlarmControlScreen> createState() => _AlarmControlScreenState();
}

class _AlarmControlScreenState extends State<AlarmControlScreen> {
  final supabase = Supabase.instance.client;
  bool _alarmActive = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      await _loadAlarmStatus();
    } catch (e) {
      _showError('Error al cargar datos iniciales: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadAlarmStatus() async {
    try {
      final response = await supabase
          .from('estado_alarma')
          .select()
          .eq('id', 1)
          .single();

      setState(() {
        _alarmActive = response['activo'] ?? false;
      });
    } catch (e) {
      _showError('Error al cargar estado: ${e.toString()}');
    }
  }

  Future<void> _toggleAlarm() async {
    try {
      final newStatus = !_alarmActive;

      await supabase
          .from('estado_alarma')
          .update({'activo': newStatus})
          .eq('id', 1);

      setState(() {
        _alarmActive = newStatus;
      });

      _showMessage('Alarma ${newStatus ? 'activada' : 'desactivada'}');
    } catch (e) {
      _showError('Error al cambiar estado: ${e.toString()}');
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

  Widget _buildAlarmControlCard() {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'ESTADO ACTUAL',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Icon(
              _alarmActive ? Icons.security : Icons.security_outlined,
              size: 60,
              color: _alarmActive ? Colors.green : Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              _alarmActive ? 'ALARMA ACTIVADA' : 'ALARMA DESACTIVADA',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _alarmActive ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _toggleAlarm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _alarmActive ? Colors.green : Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  _alarmActive ? 'DESACTIVAR ALARMA' : 'ACTIVAR ALARMA',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewHistoryButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const HistoryScreen()),
            );
          },
          icon: const Icon(Icons.history),
          label: const Text('VER HISTORIAL DE DETECCIONES'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScheduleButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ScheduleScreen()),
            );
          },
          icon: const Icon(Icons.schedule),
          label: const Text('CONFIGURAR HORARIOS AUTOMÁTICOS'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUsersButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const UsersScreen()),
            );
          },
          icon: const Icon(Icons.people),
          label: const Text('GESTIONAR USUARIOS'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Control de Alarma'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadInitialData,
            tooltip: 'Actualizar datos',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildAlarmControlCard(),
                const SizedBox(height: 20),
                _buildViewHistoryButton(),
                const SizedBox(height: 10),
                _buildScheduleButton(),
                const SizedBox(height: 10),
                _buildUsersButton(),
              ],
            ),
    );
  }
}