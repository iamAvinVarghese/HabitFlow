import 'package:flutter/material.dart';
import 'package:habitflow/core/utils/haptics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../data/models/journal_model.dart';
import '../../../domain/providers/journal_providers.dart';

class JournalEntryScreen extends ConsumerStatefulWidget {
  final String? entryId;

  const JournalEntryScreen({super.key, this.entryId});

  @override
  ConsumerState<JournalEntryScreen> createState() => _JournalEntryScreenState();
}

class _JournalEntryScreenState extends ConsumerState<JournalEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _tagsController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  bool get _isEditing => widget.entryId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadEntry());
    }
  }

  void _loadEntry() {
    final entry = ref.read(journalNotifierProvider).firstWhere((e) => e.id == widget.entryId);
    _titleController.text = entry.title;
    _contentController.text = entry.content;
    _tagsController.text = entry.tags.join(', ');
    setState(() {
      _selectedDate = entry.date;
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final tags = _tagsController.text
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    if (_isEditing) {
      final entry = ref.read(journalNotifierProvider).firstWhere((e) => e.id == widget.entryId);
      entry.updateContent(_titleController.text.trim(), _contentController.text.trim());
      entry.tags = tags;
      entry.date = _selectedDate;
      await ref.read(journalNotifierProvider.notifier).saveJournalEntry(entry);
    } else {
      final newEntry = JournalEntry(
        id: const Uuid().v4(),
        date: _selectedDate,
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        tags: tags,
      );
      await ref.read(journalNotifierProvider.notifier).saveJournalEntry(newEntry);
    }

    if (mounted) Navigator.pop(context);
  }

  void _simulateVoiceInput() {
    HapticFeedback.mediumImpact();
    // Pre-populate with typical voice reflections
    final reflections = [
      "Today was super productive. Completed all coding goals and went for a run.",
      "Reflecting on today, I felt a bit distracted in the morning but focused well after lunch.",
      "Great session focusing on self-study today. Need to keep this momentum going tomorrow.",
    ];
    final randomReflection = (reflections..shuffle()).first;
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Row(
          children: [
            Icon(Icons.mic, color: AppColors.textPrimary),
            SizedBox(width: 8),
            Text('Offline Voice Entry'),
          ],
        ),
        content: const Text('Simulating voice capture... Listening to reflections.'),
        actions: [
          TextButton(
            onPressed: hapticLight(() {
              setState(() {
                _contentController.text = '${_contentController.text} $randomReflection'.trim();
              });
              Navigator.pop(ctx);
            }),
            child: const Text('Insert Simulated Voice'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Edit Reflection' : 'Write Reflection',
          style: GoogleFonts.inter(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.mic_rounded),
            onPressed: hapticLight(_simulateVoiceInput),
            tooltip: 'Simulate Voice Input',
          ),
          IconButton(
            icon: const Icon(Icons.check_rounded),
            onPressed: hapticMedium(_save),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingPage),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                TextFormField(
                  controller: _titleController,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    hintText: 'Entry Title',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Title is required' : null,
                ),
                const Divider(height: 24),
                // Date
                GestureDetector(
                  onTap: hapticSelection(() async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime.utc(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() {
                        _selectedDate = date;
                      });
                    }
                  }),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 8),
                      Text(
                        'Date: ${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimensions.spaceM),
                // Tags
                TextFormField(
                  controller: _tagsController,
                  style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    hintText: 'Tags (comma separated, e.g. reflection, coding, focus)',
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
                const SizedBox(height: AppDimensions.spaceM),
                // Content
                TextFormField(
                  controller: _contentController,
                  maxLines: 15,
                  style: const TextStyle(fontSize: 14, height: 1.5, color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    hintText: 'Start writing here...',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    fillColor: Colors.transparent,
                    contentPadding: EdgeInsets.zero,
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Reflection content cannot be empty' : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
