import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/utils/haptics.dart';
import '../../../data/models/special_day_model.dart';
import '../../../domain/providers/special_day_providers.dart';

class AddEditSpecialDayScreen extends ConsumerStatefulWidget {
  final String? specialDayId;
  const AddEditSpecialDayScreen({super.key, this.specialDayId});

  @override
  ConsumerState<AddEditSpecialDayScreen> createState() =>
      _AddEditSpecialDayScreenState();
}

class _AddEditSpecialDayScreenState
    extends ConsumerState<AddEditSpecialDayScreen> {
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  SpecialDayType _type = SpecialDayType.yearly;
  DateTime _selectedDate = DateTime.now();
  int _reminderHour = 9;
  int _reminderMinute = 0;
  bool _isEditing = false;
  bool _isSaving = false;
  SpecialDayModel? _existing;

  final Set<int> _selectedOffsets = {7, 3, 1, 0};
  final Map<int, String> _availableOffsets = {
    30: '30d before',
    14: '14d before',
    7: '7d before',
    3: '3d before',
    1: '1d before',
    0: 'Same day',
  };

  @override
  void initState() {
    super.initState();
    if (widget.specialDayId != null) {
      _isEditing = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final all = ref.read(specialDayNotifierProvider);
        final found = all.where((s) => s.id == widget.specialDayId);
        if (found.isNotEmpty) {
          _existing = found.first;
          setState(() {
            _titleController.text = _existing!.title;
            _notesController.text = _existing!.notes ?? '';
            _type = _existing!.type;
            _selectedDate = _existing!.date;
            _reminderHour = _existing!.reminderHour;
            _reminderMinute = _existing!.reminderMinute;
            // Restore the user's custom offsets
            if (_existing!.reminderOffsets.isNotEmpty) {
              _selectedOffsets
                ..clear()
                ..addAll(_existing!.reminderOffsets);
            }
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    if (_type == SpecialDayType.yearly) {
      await _showMonthDayPicker();
    } else if (_type == SpecialDayType.monthly) {
      await _showDayOfMonthPicker();
    } else {
      final now = DateTime.now();
      final picked = await showDatePicker(
        context: context,
        initialDate: _selectedDate.isAfter(now) ? _selectedDate : now,
        firstDate: now,
        lastDate: DateTime(now.year + 10),
        builder: (ctx, child) => Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.textPrimary,
              onPrimary: AppColors.background,
              surface: AppColors.card,
            ),
          ),
          child: child!,
        ),
      );
      if (picked != null) setState(() => _selectedDate = picked);
    }
  }

  Future<void> _showDayOfMonthPicker() async {
    int day = _selectedDate.day;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setInner) {
          return AlertDialog(
            backgroundColor: AppColors.card,
            shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(AppDimensions.radiusLarge)),
            title: Text('Select Day of Month',
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _PickerRow(
                  label: 'Day',
                  child: DropdownButton<int>(
                    value: day.clamp(1, 31),
                    dropdownColor: AppColors.cardElevated,
                    style: GoogleFonts.inter(
                        color: AppColors.textPrimary, fontSize: 14),
                    underline: const SizedBox(),
                    items: List.generate(
                      31,
                      (i) => DropdownMenuItem(value: i + 1, child: Text('Day ${i + 1}')),
                    ),
                    onChanged: (v) => setInner(() => day = v!),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Cancel',
                    style:
                        GoogleFonts.inter(color: AppColors.textSecondary)),
              ),
              TextButton(
                onPressed: () {
                  setState(() => _selectedDate = DateTime(2000, 1, day));
                  Navigator.pop(ctx);
                },
                child: Text('Confirm',
                    style: GoogleFonts.inter(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showMonthDayPicker() async {
    int month = _selectedDate.month;
    int day = _selectedDate.day;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setInner) {
          final daysInMonth = DateUtils.getDaysInMonth(2000, month);
          if (day > daysInMonth) day = daysInMonth;

          return AlertDialog(
            backgroundColor: AppColors.card,
            shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(AppDimensions.radiusLarge)),
            title: Text('Select Month & Day',
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _PickerRow(
                  label: 'Month',
                  child: DropdownButton<int>(
                    value: month,
                    dropdownColor: AppColors.cardElevated,
                    style: GoogleFonts.inter(
                        color: AppColors.textPrimary, fontSize: 14),
                    underline: const SizedBox(),
                    items: List.generate(
                      12,
                      (i) => DropdownMenuItem(
                        value: i + 1,
                        child: Text(
                            DateFormat('MMMM').format(DateTime(2000, i + 1))),
                      ),
                    ),
                    onChanged: (v) => setInner(() => month = v!),
                  ),
                ),
                const SizedBox(height: 12),
                _PickerRow(
                  label: 'Day',
                  child: DropdownButton<int>(
                    value: day.clamp(1, DateUtils.getDaysInMonth(2000, month)),
                    dropdownColor: AppColors.cardElevated,
                    style: GoogleFonts.inter(
                        color: AppColors.textPrimary, fontSize: 14),
                    underline: const SizedBox(),
                    items: List.generate(
                      DateUtils.getDaysInMonth(2000, month),
                      (i) =>
                          DropdownMenuItem(value: i + 1, child: Text('${i + 1}')),
                    ),
                    onChanged: (v) => setInner(() => day = v!),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Cancel',
                    style:
                        GoogleFonts.inter(color: AppColors.textSecondary)),
              ),
              TextButton(
                onPressed: () {
                  setState(() => _selectedDate = DateTime(2000, month, day));
                  Navigator.pop(ctx);
                },
                child: Text('Confirm',
                    style: GoogleFonts.inter(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _reminderHour, minute: _reminderMinute),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.textPrimary,
            onPrimary: AppColors.background,
            surface: AppColors.card,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _reminderHour = picked.hour;
        _reminderMinute = picked.minute;
      });
    }
  }

  List<_ReminderEntry> _computeReminderDates() {
    final sortedOffsets = _selectedOffsets.toList()
      ..sort((a, b) => b.compareTo(a));
    final now = DateTime.now();
    final List<_ReminderEntry> entries = [];

    for (final offset in sortedOffsets) {
      late DateTime targetDt;
      final label = _availableOffsets[offset] ?? '$offset days before';

      if (_type == SpecialDayType.yearly) {
        final eventThisYear =
            DateTime(now.year, _selectedDate.month, _selectedDate.day);
        final notifyDate = eventThisYear.subtract(Duration(days: offset));
        final notifyDt = DateTime(notifyDate.year, notifyDate.month,
            notifyDate.day, _reminderHour, _reminderMinute);
        if (notifyDt.isBefore(now)) {
          final eventNextYear =
              DateTime(now.year + 1, _selectedDate.month, _selectedDate.day);
          final notifyDateNext =
              eventNextYear.subtract(Duration(days: offset));
          targetDt = DateTime(notifyDateNext.year, notifyDateNext.month,
              notifyDateNext.day, _reminderHour, _reminderMinute);
        } else {
          targetDt = notifyDt;
        }
      } else if (_type == SpecialDayType.monthly) {
        final daysInThisMonth = DateUtils.getDaysInMonth(now.year, now.month);
        final dayThisMonth = _selectedDate.day.clamp(1, daysInThisMonth);
        final eventThisMonth = DateTime(now.year, now.month, dayThisMonth);
        final notifyDate = eventThisMonth.subtract(Duration(days: offset));
        final notifyDt = DateTime(notifyDate.year, notifyDate.month,
            notifyDate.day, _reminderHour, _reminderMinute);
        if (notifyDt.isBefore(now)) {
          int nextMonth = now.month + 1;
          int nextYear = now.year;
          if (nextMonth > 12) {
            nextMonth = 1;
            nextYear++;
          }
          final daysInNextMonth = DateUtils.getDaysInMonth(nextYear, nextMonth);
          final dayNextMonth = _selectedDate.day.clamp(1, daysInNextMonth);
          final eventNextMonth = DateTime(nextYear, nextMonth, dayNextMonth);
          final notifyDateNext = eventNextMonth.subtract(Duration(days: offset));
          targetDt = DateTime(notifyDateNext.year, notifyDateNext.month,
              notifyDateNext.day, _reminderHour, _reminderMinute);
        } else {
          targetDt = notifyDt;
        }
      } else {
        final eventDay =
            DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
        final notifyDate = eventDay.subtract(Duration(days: offset));
        targetDt = DateTime(notifyDate.year, notifyDate.month,
            notifyDate.day, _reminderHour, _reminderMinute);
      }

      final isPast = targetDt.isBefore(now);
      entries.add(_ReminderEntry(
        label: label,
        date: targetDt,
        isPast: isPast,
        isToday: DateUtils.isSameDay(targetDt, now),
      ));
    }
    return entries;
  }

  Future<void> _save() async {
    if (_isSaving) return;
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final notes = _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim();

      if (_isEditing && _existing != null) {
        final updated = SpecialDayModel(
          id: _existing!.id,
          title: title,
          emoji: _existing!.emoji,
          type: _type,
          date: _selectedDate,
          reminderHour: _reminderHour,
          reminderMinute: _reminderMinute,
          color: _existing!.color,
          createdAt: _existing!.createdAt,
          notificationIds: _existing!.notificationIds,
          notes: notes,
          reminderOffsets: _selectedOffsets.toList(),
        );
        await ref.read(specialDayNotifierProvider.notifier).update(
          updated,
          customOffsets: _selectedOffsets.toList(),
        );
      } else {
        final model = SpecialDayModel(
          id: const Uuid().v4(),
          title: title,
          type: _type,
          date: _selectedDate,
          reminderHour: _reminderHour,
          reminderMinute: _reminderMinute,
          color: 0xFFFFFFFF,
          notes: notes,
          reminderOffsets: _selectedOffsets.toList(),
        );
        await ref.read(specialDayNotifierProvider.notifier).add(
          model,
          customOffsets: _selectedOffsets.toList(),
        );
      }

      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final reminderEntries = _computeReminderDates();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          _isEditing ? 'Edit Event' : 'New Event',
          style: GoogleFonts.inter(fontWeight: FontWeight.w800),
        ),
        actions: [
          _isSaving
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.textPrimary,
                    ),
                  ),
                )
              : TextButton(
                  onPressed: () {
                    AppHaptics.medium();
                    _save();
                  },
                  child: Text(
                    'Save',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      fontSize: 16,
                    ),
                  ),
                ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.paddingPage),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Event Details ──────────────────────────────────────────────
            _SectionLabel('Event Details'),
            const SizedBox(height: AppDimensions.spaceS),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingCard, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
                border: Border.all(color: AppColors.border),
              ),
              child: TextField(
                controller: _titleController,
                style: GoogleFonts.inter(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 16),
                decoration: InputDecoration(
                  hintText: "e.g. Mom's Birthday",
                  hintStyle: GoogleFonts.inter(
                      color: AppColors.textTertiary, fontSize: 15),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),

            const SizedBox(height: AppDimensions.spaceL),

            // ── Notes ─────────────────────────────────────────────────────
            _SectionLabel('Notes'),
            const SizedBox(height: AppDimensions.spaceS),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingCard, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
                border: Border.all(color: AppColors.border),
              ),
              child: TextField(
                controller: _notesController,
                maxLines: 3,
                style: GoogleFonts.inter(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    height: 1.6),
                decoration: InputDecoration(
                  hintText: 'Add a note, gift idea, or message…',
                  hintStyle: GoogleFonts.inter(
                      color: AppColors.textTertiary, fontSize: 13),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),

            const SizedBox(height: AppDimensions.spaceL),

            // ── Event Type ─────────────────────────────────────────────────
            _SectionLabel('Event Type'),
            const SizedBox(height: AppDimensions.spaceS),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  _TypeChip(
                    label: 'Yearly',
                    subtitle: 'Birthday, Anniversary',
                    icon: Icons.cake_rounded,
                    isSelected: _type == SpecialDayType.yearly,
                    onTap: hapticLight(
                        () => setState(() => _type = SpecialDayType.yearly)),
                  ),
                  _TypeChip(
                    label: 'Monthly',
                    subtitle: 'Bills, Subscription',
                    icon: Icons.repeat_one_rounded,
                    isSelected: _type == SpecialDayType.monthly,
                    onTap: hapticLight(
                        () => setState(() => _type = SpecialDayType.monthly)),
                  ),
                  _TypeChip(
                    label: 'One-time',
                    subtitle: 'Meeting, Trip, Event',
                    icon: Icons.event_rounded,
                    isSelected: _type == SpecialDayType.oneTime,
                    onTap: hapticLight(() => setState(() {
                      _type = SpecialDayType.oneTime;
                      // The yearly/monthly picker stores year 2000 as a placeholder.
                      // Reset to today so one-time notifications aren't in the past.
                      if (_selectedDate.year <= 2000) {
                        _selectedDate = DateTime.now();
                      }
                    })),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppDimensions.spaceL),

            // ── Date ──────────────────────────────────────────────────────
            _SectionLabel(
                _type == SpecialDayType.yearly
                    ? 'Month & Day'
                    : _type == SpecialDayType.monthly
                        ? 'Day of Month'
                        : 'Event Date'),
            const SizedBox(height: AppDimensions.spaceS),
            _TappableRow(
              icon: Icons.calendar_today_rounded,
              text: _type == SpecialDayType.yearly
                  ? DateFormat('MMMM d').format(_selectedDate)
                  : _type == SpecialDayType.monthly
                      ? 'Day ${_selectedDate.day} of every month'
                      : DateFormat('EEEE, MMMM d, y').format(_selectedDate),
              onTap: hapticLight(_pickDate),
            ),

            const SizedBox(height: AppDimensions.spaceL),

            // ── Reminders ─────────────────────────────────────────────────
            _SectionLabel('Reminders'),
            const SizedBox(height: AppDimensions.spaceS),
            Container(
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _TappableRowInCard(
                    icon: Icons.access_time_rounded,
                    label: 'Reminder Time',
                    value: TimeOfDay(
                            hour: _reminderHour, minute: _reminderMinute)
                        .format(context),
                    onTap: hapticLight(_pickTime),
                  ),
                  const Divider(height: 1, color: AppColors.border),
                  Padding(
                    padding: const EdgeInsets.all(AppDimensions.spaceM),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CUSTOMIZE REMINDER OFFSETS',
                          style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textTertiary,
                              letterSpacing: 0.8),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: _availableOffsets.entries.map((e) {
                            final isSel = _selectedOffsets.contains(e.key);
                            return GestureDetector(
                              onTap: () {
                                AppHaptics.light();
                                setState(() {
                                  if (isSel) {
                                    if (_selectedOffsets.length > 1) {
                                      _selectedOffsets.remove(e.key);
                                    }
                                  } else {
                                    _selectedOffsets.add(e.key);
                                  }
                                });
                              },
                              child: AnimatedContainer(
                                duration: AppDimensions.animFast,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isSel
                                      ? AppColors.textPrimary
                                      : AppColors.surfaceVariant,
                                  borderRadius: BorderRadius.circular(
                                      AppDimensions.radiusFull),
                                  border: Border.all(
                                    color: isSel
                                        ? AppColors.textPrimary
                                        : AppColors.border,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (isSel) ...[
                                      const Icon(Icons.check_rounded,
                                          size: 12,
                                          color: AppColors.background),
                                      const SizedBox(width: 4),
                                    ],
                                    Text(
                                      e.value,
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: isSel
                                            ? AppColors.background
                                            : AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: AppDimensions.spaceM),
                        Text(
                          'SCHEDULED NOTIFICATIONS',
                          style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textTertiary,
                              letterSpacing: 0.8),
                        ),
                        const SizedBox(height: AppDimensions.spaceS),
                        ...reminderEntries
                            .map((entry) => _ReminderRow(entry: entry)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppDimensions.spaceXL),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Data class for reminder preview
// ─────────────────────────────────────────────────────────────────────────────

class _ReminderEntry {
  final String label;
  final DateTime date;
  final bool isPast;
  final bool isToday;
  const _ReminderEntry({
    required this.label,
    required this.date,
    required this.isPast,
    required this.isToday,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper Widgets
// ─────────────────────────────────────────────────────────────────────────────

class _ReminderRow extends StatelessWidget {
  final _ReminderEntry entry;
  const _ReminderRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('EEE, MMM d · h:mm a').format(entry.date);
    final Color textColor =
        entry.isPast ? AppColors.textTertiary : AppColors.textSecondary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: entry.isPast
                  ? AppColors.textTertiary
                  : AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            entry.label,
            style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: entry.isPast
                    ? AppColors.textTertiary
                    : AppColors.textSecondary),
          ),
          const Spacer(),
          Text(
            dateStr,
            style: GoogleFonts.inter(fontSize: 11, color: textColor),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppColors.textTertiary,
          letterSpacing: 1.2),
    );
  }
}

class _TappableRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onTap;
  const _TappableRow(
      {required this.icon, required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.paddingCard, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.textSecondary, size: 18),
            const SizedBox(width: AppDimensions.spaceM),
            Text(
              text,
              style: GoogleFonts.inter(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                  fontSize: 15),
            ),
            const Spacer(),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textTertiary, size: 18),
          ],
        ),
      ),
    );
  }
}

class _TappableRowInCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  const _TappableRowInCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.paddingCard, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: AppColors.textSecondary, size: 18),
            const SizedBox(width: AppDimensions.spaceM),
            Text(label,
                style: GoogleFonts.inter(
                    color: AppColors.textSecondary, fontSize: 14)),
            const Spacer(),
            Text(value,
                style: GoogleFonts.inter(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14)),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textTertiary, size: 16),
          ],
        ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeChip({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppDimensions.animFast,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.cardElevated : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(icon,
                  size: 18,
                  color: isSelected
                      ? AppColors.textPrimary
                      : AppColors.textTertiary),
              const SizedBox(height: 4),
              Text(label,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight:
                        isSelected ? FontWeight.w700 : FontWeight.w400,
                    color: isSelected
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  )),
              const SizedBox(height: 2),
              Text(subtitle,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: AppColors.textTertiary,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

class _PickerRow extends StatelessWidget {
  final String label;
  final Widget child;
  const _PickerRow({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 60,
          child: Text(label,
              style: GoogleFonts.inter(
                  color: AppColors.textSecondary, fontSize: 13)),
        ),
        const SizedBox(width: 12),
        child,
      ],
    );
  }
}
