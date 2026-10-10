
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme.dart';

/// One confirmed medicine instruction that SMRITI can schedule.
class MedicineReminder {
  final String id;
  final String medicine;
  final String dose;
  final String instruction;
  TimeOfDay time;
  bool enabled;

  MedicineReminder({
    required this.id,
    required this.medicine,
    required this.dose,
    required this.instruction,
    required this.time,
    this.enabled = true,
  });
}

class RemindersScreen extends StatefulWidget {
  final SmritiUser user;

  /// Pass AI-confirmed prescription reminders here later from Report Analysis.
  final List<MedicineReminder> initialReminders;

  const RemindersScreen({
    super.key,
    required this.user,
    this.initialReminders = const [],
  });

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  late final List<MedicineReminder> _reminders;

  @override
  void initState() {
    super.initState();
    _reminders = List<MedicineReminder>.from(widget.initialReminders);
  }

  Future<void> _editTime(MedicineReminder reminder) async {
    final selected = await showTimePicker(
      context: context,
      initialTime: reminder.time,
      helpText: 'Choose medicine reminder time',
    );

    if (selected == null) return;

    setState(() {
      reminder.time = selected;
    });

    _showMessage('${reminder.medicine} reminder updated.');
  }

  Future<void> _addFromConfirmedPrescription() async {
    final medicineController = TextEditingController();
    final doseController = TextEditingController();
    final instructionController = TextEditingController();

    TimeOfDay selectedTime = const TimeOfDay(hour: 8, minute: 30);

    final result = await showModalBottomSheet<MedicineReminder>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 42,
                          height: 4,
                          decoration: BoxDecoration(
                            color: SmritiColors.mauve,
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Confirm medicine reminder',
                        style: TextStyle(
                          color: SmritiColors.plum,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Enter the instruction exactly as confirmed from the prescription.',
                        style: TextStyle(
                          color: SmritiColors.ink,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 18),
                      _field(
                        controller: medicineController,
                        label: 'Medicine name',
                        hint: 'e.g. Metformin',
                      ),
                      const SizedBox(height: 12),
                      _field(
                        controller: doseController,
                        label: 'Dose',
                        hint: 'e.g. 500 mg',
                      ),
                      const SizedBox(height: 12),
                      _field(
                        controller: instructionController,
                        label: 'Prescription instruction',
                        hint: 'e.g. After breakfast',
                      ),
                      const SizedBox(height: 16),
                      InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: selectedTime,
                            helpText: 'Choose reminder time',
                          );
                          if (picked != null) {
                            setSheetState(() {
                              selectedTime = picked;
                            });
                          }
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: SmritiColors.petal,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.schedule_rounded,
                                color: SmritiColors.rose,
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'Reminder time',
                                  style: TextStyle(
                                    color: SmritiColors.plum,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              Text(
                                selectedTime.format(context),
                                style: const TextStyle(
                                  color: SmritiColors.rose,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: SmritiColors.rose,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: SmritiColors.plum,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: () {
                            if (medicineController.text.trim().isEmpty ||
                                doseController.text.trim().isEmpty ||
                                instructionController.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context)
                                ..hideCurrentSnackBar()
                                ..showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Please confirm the medicine, dose and instruction.',
                                    ),
                                  ),
                                );
                              return;
                            }

                            Navigator.of(sheetContext).pop(
                              MedicineReminder(
                                id: DateTime.now()
                                    .microsecondsSinceEpoch
                                    .toString(),
                                medicine: medicineController.text.trim(),
                                dose: doseController.text.trim(),
                                instruction:
                                instructionController.text.trim(),
                                time: selectedTime,
                              ),
                            );
                          },
                          icon: const Icon(Icons.check_rounded),
                          label: const Text('Confirm & create reminder'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    medicineController.dispose();
    doseController.dispose();
    instructionController.dispose();

    if (!mounted || result == null) return;

    setState(() {
      _reminders.add(result);
    });

    _showMessage('${result.medicine} reminder created.');
  }

  Future<void> _deleteReminder(MedicineReminder reminder) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Remove reminder?'),
          content: Text(
            'Remove the ${reminder.medicine} reminder from SMRITI?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: SmritiColors.rose,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _reminders.remove(reminder);
    });

    _showMessage('Reminder removed.');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  static Widget _field({
    required TextEditingController controller,
    required String label,
    required String hint,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: SmritiColors.blush,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  String _formatTime(BuildContext context, TimeOfDay time) {
    return time.format(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SmritiColors.blush,
      appBar: AppBar(
        backgroundColor: SmritiColors.blush,
        foregroundColor: SmritiColors.plum,
        elevation: 0,
        title: const Text(
          'Reminders',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [SmritiColors.plum, SmritiColors.rose],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.alarm_rounded,
                    color: SmritiColors.roseLight,
                    size: 32,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Medicine reminders',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Hi ${widget.user.name}, keep track of reminders created from your confirmed prescription instructions.',
                    style: const TextStyle(
                      color: SmritiColors.petal,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (_reminders.isEmpty)
              _buildEmptyState()
            else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Today's reminders",
                    style: TextStyle(
                      color: SmritiColors.plum,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _addFromConfirmedPrescription,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add'),
                    style: TextButton.styleFrom(
                      foregroundColor: SmritiColors.rose,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              for (final reminder in _reminders)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ReminderCard(
                    reminder: reminder,
                    timeText: _formatTime(context, reminder.time),
                    onEditTime: () => _editTime(reminder),
                    onToggle: (value) {
                      setState(() {
                        reminder.enabled = value;
                      });
                    },
                    onDelete: () => _deleteReminder(reminder),
                  ),
                ),
            ],
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: SmritiColors.petal,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Text(
                'Safety note: Always check the medicine name, dose and timing against the doctor’s prescription. If an instruction is unclear, confirm it with your doctor or pharmacist.',
                style: TextStyle(
                  color: SmritiColors.plum,
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.notifications_none_rounded,
                color: SmritiColors.rose,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'No reminders yet',
                  style: TextStyle(
                    color: SmritiColors.plum,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Reminders will appear here after prescription instructions are confirmed and scheduled.',
            style: TextStyle(
              color: SmritiColors.ink,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _addFromConfirmedPrescription,
              style: OutlinedButton.styleFrom(
                foregroundColor: SmritiColors.plum,
                side: const BorderSide(color: SmritiColors.rose),
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
              icon: const Icon(Icons.add_alarm_rounded),
              label: const Text('Add from confirmed prescription'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  final MedicineReminder reminder;
  final String timeText;
  final VoidCallback onEditTime;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDelete;

  const _ReminderCard({
    required this.reminder,
    required this.timeText,
    required this.onEditTime,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: reminder.enabled ? 1 : 0.55,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: SmritiColors.petal,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.medication_rounded,
                    color: SmritiColors.rose,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reminder.medicine,
                        style: const TextStyle(
                          color: SmritiColors.plum,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        reminder.dose,
                        style: const TextStyle(
                          color: SmritiColors.rose,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        reminder.instruction,
                        style: const TextStyle(
                          color: SmritiColors.ink,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: reminder.enabled,
                  activeColor: SmritiColors.rose,
                  onChanged: onToggle,
                ),
              ],
            ),
            const SizedBox(height: 14),
            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onEditTime,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: SmritiColors.blush,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.schedule_rounded,
                      color: SmritiColors.rose,
                      size: 21,
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Reminder time',
                        style: TextStyle(
                          color: SmritiColors.plum,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      timeText,
                      style: const TextStyle(
                        color: SmritiColors.rose,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.edit_rounded,
                      color: SmritiColors.rose,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                label: const Text('Remove'),
                style: TextButton.styleFrom(
                  foregroundColor: SmritiColors.mauve,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
