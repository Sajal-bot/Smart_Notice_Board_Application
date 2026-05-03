import 'package:flutter/material.dart';
import '../models/app_notification.dart';

class AddNotificationPage extends StatefulWidget {
  @override
  _AddNotificationPageState createState() => _AddNotificationPageState();
}

class _AddNotificationPageState extends State<AddNotificationPage> {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();
  final TextEditingController _frequencyController = TextEditingController();

  Priority _selectedPriority = Priority.normal;
  DateTime _selectedStartTime = DateTime.now();
  int _selectedColor = 0xFF42A5F5; // Default blue

  void _saveNotification() {
    final String text = _textController.text;
    final int durationMinutes = int.tryParse(_durationController.text) ?? 15;
    final int frequencyMinutes = int.tryParse(_frequencyController.text) ?? 30;

    final AppNotification newNotification = AppNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      colorValue: _selectedColor,
      priority: _selectedPriority,
      startTime: _selectedStartTime,
      durationMinutes: durationMinutes,
      frequencyMinutes: frequencyMinutes,
    );

    // Save to Hive box or pass it to your provider/controller
    // Example:
    // Hive.box<AppNotification>('notifications').add(newNotification);

    Navigator.pop(context); // Go back after saving
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add Notification')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _textController,
              decoration: InputDecoration(labelText: 'Notification Text'),
            ),
            TextField(
              controller: _durationController,
              decoration: InputDecoration(labelText: 'Duration (minutes)'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _frequencyController,
              decoration: InputDecoration(labelText: 'Frequency (minutes)'),
              keyboardType: TextInputType.number,
            ),
            DropdownButton<Priority>(
              value: _selectedPriority,
              items: Priority.values.map((Priority priority) {
                return DropdownMenuItem<Priority>(
                  value: priority,
                  child: Text(priority.toString().split('.').last),
                );
              }).toList(),
              onChanged: (Priority? newValue) {
                setState(() {
                  _selectedPriority = newValue!;
                });
              },
            ),
            SizedBox(height: 20),
            ElevatedButton(onPressed: _saveNotification, child: Text('Save')),
          ],
        ),
      ),
    );
  }
}
