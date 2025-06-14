import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  bool _isSaving = false;
  List<Map<String, dynamic>> _schedules = [];
  final List<String> _days = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
  final List<bool> _selectedDays = List.filled(7, false);

  TimeOfDay _startTime = TimeOfDay.now();
  TimeOfDay _endTime = TimeOfDay.now();
  bool _execute = true;

  @override
  void initState() {
    super.initState();
    _loadSchedules();
  }

  Future<void> _loadSchedules() async {
    setState(() => _isLoading = true);
    try {
      final response = await supabase
          .from('horarios_alarma')
          .select('*')
          .order('hora_inicio', ascending: true);

      if (response != null && response.isNotEmpty) {
        setState(() {
          _schedules = List<Map<String, dynamic>>.from(response);
          if (_schedules.isNotEmpty) {
            final schedule = _schedules.first;
            _execute = schedule['ejecutar'] ?? true;
            _startTime = _parseTime(schedule['hora_inicio']);
            _endTime = _parseTime(schedule['hora_fin']);
            _updateSelectedDays(schedule['dias'] ?? []);
          }
        });
      }
    } catch (e) {
      _showError('Error al cargar horarios: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  TimeOfDay _parseTime(String timeString) {
    final parts = timeString.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  void _updateSelectedDays(List<dynamic> days) {
    for (var i = 0; i < _selectedDays.length; i++) {
      _selectedDays[i] = days.contains(_days[i]);
    }
  }

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final initialTime = isStartTime ? _startTime : _endTime;
    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    
    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  Future<void> _saveSchedule() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final selectedDays = <String>[];
      for (var i = 0; i < _selectedDays.length; i++) {
        if (_selectedDays[i]) selectedDays.add(_days[i]);
      }

      final startTimeStr = '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}:00';
      final endTimeStr = '${_endTime.hour.toString().padLeft(2, '0')}:${_endTime.minute.toString().padLeft(2, '0')}:00';

      final scheduleData = {
        'hora_inicio': startTimeStr,
        'hora_fin': endTimeStr,
        'dias': selectedDays,
        'ejecutar': _execute,
      };

      if (_schedules.isNotEmpty) {
        await supabase
            .from('horarios_alarma')
            .update(scheduleData)
            .eq('id', _schedules.first['id']);
      } else {
        await supabase
            .from('horarios_alarma')
            .insert([scheduleData]);
      }

      _showMessage('Horario guardado correctamente');
      await _loadSchedules();
    } catch (e) {
      _showError('Error al guardar horario: ${e.toString()}');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _deleteSchedule(int id) async {
    try {
      await supabase
          .from('horarios_alarma')
          .delete()
          .eq('id', id);
      
      _showMessage('Horario eliminado correctamente');
      await _loadSchedules();
    } catch (e) {
      _showError('Error al eliminar horario: ${e.toString()}');
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
        title: const Text('Configurar Horarios Automáticos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSchedules,
            tooltip: 'Actualizar horarios',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SwitchListTile(
                      title: const Text('Ejecutar horario automático'),
                      value: _execute,
                      onChanged: (value) => setState(() => _execute = value),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Hora de inicio:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    ListTile(
                      title: Text(_startTime.format(context)),
                      trailing: const Icon(Icons.access_time),
                      onTap: () => _selectTime(context, true),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Hora de fin:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    ListTile(
                      title: Text(_endTime.format(context)),
                      trailing: const Icon(Icons.access_time),
                      onTap: () => _selectTime(context, false),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Días de activación:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: List.generate(
                        _days.length,
                        (index) => FilterChip(
                          label: Text(_days[index]),
                          selected: _selectedDays[index],
                          onSelected: (selected) => setState(() => _selectedDays[index] = selected),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveSchedule,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _isSaving
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('GUARDAR HORARIO'),
                      ),
                    ),
                    if (_schedules.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      const Divider(),
                      const Text(
                        'Horarios configurados:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 10),
                      ..._schedules.map((schedule) => Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          title: Text(
                            '${schedule['hora_inicio']} - ${schedule['hora_fin']}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'Días: ${(schedule['dias'] as List).join(', ')}\n'
                            'Ejecutar: ${schedule['ejecutar'] ? 'Sí' : 'No'}',
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteSchedule(schedule['id']),
                          ),
                        ),
                      )),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}