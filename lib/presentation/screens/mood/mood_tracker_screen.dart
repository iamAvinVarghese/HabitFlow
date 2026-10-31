import 'package:flutter/material.dart';
import 'package:habitflow/core/utils/haptics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/utils/date_utils.dart';
import '../../../data/models/mood_model.dart';
import '../../../domain/providers/mood_providers.dart';
import '../../widgets/mood_selector.dart';

class MoodTrackerScreen extends ConsumerStatefulWidget {
  const MoodTrackerScreen({super.key});

  @override
  ConsumerState<MoodTrackerScreen> createState() => _MoodTrackerScreenState();
}

class _MoodTrackerScreenState extends ConsumerState<MoodTrackerScreen> {
  MoodLevel _selectedMood = MoodLevel.neutral;
  final _noteController = TextEditingController();
  int _energyLevel = 3;

  final List<String> _availableTags = [
    'Work',
    'Family',
    'Friends',
    'Health',
    'Exercise',
    'Sleep',
    'Diet',
    'Relax',
    'Hobby',
    'Travel'
  ];
  final List<String> _selectedTags = [];

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _toggleTag(String tag) {
    setState(() {
      if (_selectedTags.contains(tag)) {
        _selectedTags.remove(tag);
      } else {
        _selectedTags.add(tag);
      }
    });
  }

  Future<void> _saveMood() async {
    HapticFeedback.mediumImpact();
    final newEntry = MoodEntry(
      id: const Uuid().v4(),
      date: DateTime.now(),
      mood: _selectedMood,
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      tags: _selectedTags,
      energyLevel: _energyLevel,
    );

    await ref.read(moodNotifierProvider.notifier).addMoodEntry(newEntry);
    _noteController.clear();
    _selectedTags.clear();
    setState(() {
      _selectedMood = MoodLevel.neutral;
      _energyLevel = 3;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Daily mood log saved.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final todayMood = ref.watch(todayMoodEntryProvider);
    final pastMoods = ref.watch(moodNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Mood Tracker',
          style: GoogleFonts.inter(fontWeight: FontWeight.w800),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingPage),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppDimensions.spaceM),
              if (todayMood == null) ...[
                // Log mood card
                _buildLogMoodCard(),
              ] else ...[
                // Today logged card
                _buildTodayLoggedCard(todayMood),
              ],
              const SizedBox(height: AppDimensions.spaceXL),
              // Past logs label
              const Text(
                'Past Mood Entries',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: AppDimensions.spaceM),
              _buildPastLogsList(pastMoods),
              const SizedBox(height: 120),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogMoodCard() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingCard),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'How are you feeling today?',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: AppDimensions.spaceM),
          MoodSelector(
            selectedMood: _selectedMood,
            onMoodSelected: (mood) {
              setState(() {
                _selectedMood = mood;
              });
            },
          ),
          const SizedBox(height: AppDimensions.spaceL),
          // Energy level slider
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Energy Level', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              Text('$_energyLevel / 5', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            ],
          ),
          Slider(
            value: _energyLevel.toDouble(),
            min: 1,
            max: 5,
            divisions: 4,
            activeColor: AppColors.textPrimary,
            inactiveColor: AppColors.surface,
            onChanged: (val) {
              setState(() {
                _energyLevel = val.toInt();
              });
            },
          ),
          const SizedBox(height: AppDimensions.spaceM),
          // Note field
          TextField(
            controller: _noteController,
            decoration: const InputDecoration(
              hintText: 'Add notes about today...',
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
          const SizedBox(height: AppDimensions.spaceM),
          // Tags
          const Text('Activities / Tags', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _availableTags.map((tag) {
              final isSelected = _selectedTags.contains(tag);
              return GestureDetector(
                onTap: hapticSelection(() => _toggleTag(tag)),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.textPrimary : AppColors.surface,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    tag,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? AppColors.background : AppColors.textSecondary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppDimensions.spaceL),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: hapticMedium(_saveMood),
              child: const Text('Log Mood'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayLoggedCard(MoodEntry todayMood) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingCard),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        border: Border.all(color: AppColors.borderBright),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Today's Mood Logged",
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textTertiary),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFFF6B6B)),
                onPressed: hapticMedium(() {
                  ref.read(moodNotifierProvider.notifier).deleteMoodEntry(todayMood.id);
                }),
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceS),
          Row(
            children: [
              Icon(
                _getMoodIcon(todayMood.mood),
                size: 32,
                color: AppColors.textPrimary,
              ),
              const SizedBox(width: AppDimensions.spaceM),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    todayMood.moodLabel,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  Text(
                    'Energy Level: ${todayMood.energyLevel} / 5',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ],
          ),
          if (todayMood.note != null) ...[
            const SizedBox(height: AppDimensions.spaceM),
            Text(
              todayMood.note!,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
            ),
          ],
          if (todayMood.tags.isNotEmpty) ...[
            const SizedBox(height: AppDimensions.spaceM),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: todayMood.tags.map((tag) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.border, width: 0.5),
                  ),
                  child: Text(
                    tag,
                    style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPastLogsList(List<MoodEntry> entries) {
    final filtered = entries.where((e) => AppDateUtils.toStorageKey(e.date) != AppDateUtils.toStorageKey(DateTime.now())).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spaceXXL),
          child: Text(
            'No past entries logged.',
            style: TextStyle(color: AppColors.textTertiary, fontSize: 13),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filtered.length,
      itemBuilder: (context, idx) {
        final entry = filtered[idx];
        return Container(
          margin: const EdgeInsets.only(bottom: AppDimensions.spaceS),
          padding: const EdgeInsets.all(AppDimensions.paddingCard),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                _getMoodIcon(entry.mood),
                size: 24,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: AppDimensions.spaceM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          entry.moodLabel,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        Text(
                          DateFormat('MMM dd').format(entry.date),
                          style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
                        ),
                      ],
                    ),
                    if (entry.note != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        entry.note!,
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  IconData _getMoodIcon(MoodLevel mood) {
    switch (mood) {
      case MoodLevel.terrible:
        return Icons.sentiment_very_dissatisfied_rounded;
      case MoodLevel.bad:
        return Icons.sentiment_dissatisfied_rounded;
      case MoodLevel.neutral:
        return Icons.sentiment_neutral_rounded;
      case MoodLevel.good:
        return Icons.sentiment_satisfied_rounded;
      case MoodLevel.excellent:
        return Icons.sentiment_very_satisfied_rounded;
    }
  }
}
