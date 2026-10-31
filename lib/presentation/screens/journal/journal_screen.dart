import 'package:flutter/material.dart';
import 'package:habitflow/core/utils/haptics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../data/models/journal_model.dart';
import '../../../domain/providers/journal_providers.dart';
import '../../widgets/empty_state.dart';

class JournalScreen extends ConsumerStatefulWidget {
  const JournalScreen({super.key});

  @override
  ConsumerState<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends ConsumerState<JournalScreen> {
  final _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entries = ref.watch(searchedJournalsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            backgroundColor: AppColors.background,
            floating: true,
            snap: true,
            title: _isSearching
                ? TextField(
                    controller: _searchController,
                    autofocus: true,
                    style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 16),
                    decoration: InputDecoration(
                      hintText: 'Search journal entries...',
                      hintStyle: GoogleFonts.inter(color: AppColors.textTertiary),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      fillColor: Colors.transparent,
                    ),
                    onChanged: (val) {
                      ref.read(journalSearchQueryProvider.notifier).state = val;
                    },
                  )
                : Text(
                    'Daily Journal',
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
            actions: [
              IconButton(
                icon: Icon(
                  _isSearching ? Icons.close_rounded : Icons.search_rounded,
                  color: AppColors.textSecondary,
                ),
                onPressed: hapticLight(() {
                  setState(() => _isSearching = !_isSearching);
                  if (!_isSearching) {
                    _searchController.clear();
                    ref.read(journalSearchQueryProvider.notifier).state = '';
                  }
                }),
              ),
              IconButton(
                icon: const Icon(Icons.add_rounded, color: AppColors.textPrimary),
                onPressed: hapticLight(() => context.push('/journal/write')),
              ),
            ],
          ),
        ],
        body: entries.isEmpty
            ? _buildEmptyState()
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(
                  AppDimensions.paddingPage,
                  AppDimensions.spaceM,
                  AppDimensions.paddingPage,
                  120,
                ),
                itemCount: entries.length,
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  return _buildJournalCard(entry);
                },
              ),
      ),
    );
  }

  Widget _buildJournalCard(JournalEntry entry) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.spaceS),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingCard,
          vertical: 8,
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                entry.title,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              DateFormat('MMM dd, yyyy').format(entry.date),
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            Text(
              entry.content,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (entry.tags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: entry.tags.map((tag) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppColors.border, width: 0.5),
                    ),
                    child: Text(
                      '#$tag',
                      style: const TextStyle(fontSize: 9, color: AppColors.textTertiary),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
        onTap: hapticLight(() => context.push('/journal/edit/${entry.id}')),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFFF6B6B), size: 20),
          onPressed: hapticMedium(() => _confirmDelete(entry)),
        ),
      ),
    );
  }

  void _confirmDelete(JournalEntry entry) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Delete Entry'),
        content: const Text('Are you sure you want to delete this journal entry?'),
        actions: [
          TextButton(
            onPressed: hapticLight(() => Navigator.pop(ctx)),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: hapticMedium(() {
              ref.read(journalNotifierProvider.notifier).deleteJournalEntry(entry.id);
              Navigator.pop(ctx);
            }),
            child: const Text('Delete', style: TextStyle(color: Color(0xFFFF6B6B))),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const EmptyState(
      icon: Icons.book_rounded,
      title: 'No thoughts written down',
      description: 'Write about your goals, reflections, or days to clear your mind.',
    );
  }
}
