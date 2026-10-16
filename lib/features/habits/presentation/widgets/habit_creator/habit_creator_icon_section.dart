import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_dimensions.dart';
import '../../../../../core/theme/app_font_sizes.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/haptics.dart';
import '../../../../../core/widgets/widgets.dart';
import '../../../data/models/habit_model.dart';
import '../../providers/habit_creator_form_provider.dart';
import '../habit_extensions.dart';
import 'habit_creator_accent.dart';

/// Tabbed emoji glyph / Material icon picker.
///
/// Owns its [TabController] and the custom-emoji text controller; the selected
/// glyph itself lives in [habitCreatorFormProvider].
class HabitCreatorIconSection extends ConsumerStatefulWidget {
  final HabitModel? initialHabit;

  const HabitCreatorIconSection({super.key, required this.initialHabit});

  static const List<String> curatedEmojis = [
    '☀️',
    '💧',
    '🏃',
    '🧘',
    '⚡',
    '📖',
    '💪',
    '🌙',
    '🥑',
    '🎯',
    '⏰',
    '🧠',
    '🎨',
    '🌿',
    '☕',
    '🍎',
    '🏆',
    '🔥',
    '🚀',
    '📚',
    '🚴',
    '🏊',
    '✍️',
    '🎵',
  ];

  @override
  ConsumerState<HabitCreatorIconSection> createState() =>
      _HabitCreatorIconSectionState();
}

class _HabitCreatorIconSectionState
    extends ConsumerState<HabitCreatorIconSection>
    with SingleTickerProviderStateMixin {
  late final TabController _iconTabController;
  late final TextEditingController _customEmojiController;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialHabit;
    _customEmojiController = TextEditingController();

    final isIcon =
        initial?.iconCode != null &&
        HabitIconRegistry.icons.containsKey(initial?.iconCode);

    _iconTabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: isIcon ? 1 : 0,
    );

    _iconTabController.addListener(() {
      if (_iconTabController.indexIsChanging) {
        AppHaptics.selectionClick();
        ref
            .read(habitCreatorFormProvider(widget.initialHabit).notifier)
            .setIsEmojiSelected(_iconTabController.index == 0);
      }
    });
  }

  @override
  void dispose() {
    _customEmojiController.dispose();
    _iconTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(habitCreatorFormProvider(widget.initialHabit));
    final formNotifier = ref.read(
      habitCreatorFormProvider(widget.initialHabit).notifier,
    );
    final activeColor = resolveHabitCreatorAccent(context, formState);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('ICON & EMOJI GLYPH', style: AppTextStyles.labelSmall(context)),
        SizedBox(height: 10.h),
        _buildTabHeader(context),
        SizedBox(height: 12.h),
        SizedBox(
          height: 130.w,
          child: TabBarView(
            controller: _iconTabController,
            children: [
              // Emoji Tab
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Wrap(
                        spacing: 8.w,
                        runSpacing: 8.h,
                        children: HabitCreatorIconSection.curatedEmojis.map((
                          emoji,
                        ) {
                          return _GlyphTile(
                            isSelected:
                                formState.isEmojiSelected &&
                                formState.selectedEmoji == emoji,
                            activeColor: activeColor,
                            onTap: () {
                              AppHaptics.selectionClick();
                              formNotifier.selectEmoji(emoji);
                            },
                            child: Text(
                              emoji,
                              style: context.textTheme.bodyMedium?.copyWith(
                                fontSize: AppFontSizes.titleLarge,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  SizedBox(height: 6.h),
                  AppTextField(
                    controller: _customEmojiController,
                    hintText: 'Type any custom emoji...',
                    accentColor: activeColor,
                    borderRadius: AppRadius.sm,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 6.h,
                    ),
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: context.textPrimaryColor,
                    ),
                    hintStyle: context.textTheme.bodySmall?.copyWith(
                      color: context.textMutedColor,
                    ),
                    onChanged: (val) {
                      final text = val.trim();
                      if (text.isNotEmpty) {
                        formNotifier.selectEmoji(text);
                      }
                    },
                  ),
                ],
              ),

              // Material Icon Tab
              SingleChildScrollView(
                child: Wrap(
                  spacing: 8.w,
                  runSpacing: 8.h,
                  children: HabitIconRegistry.icons.entries.map((entry) {
                    final isSelected =
                        !formState.isEmojiSelected &&
                        formState.selectedIconCode == entry.key;
                    return _GlyphTile(
                      isSelected: isSelected,
                      activeColor: activeColor,
                      onTap: () {
                        AppHaptics.selectionClick();
                        formNotifier.selectIcon(entry.key);
                      },
                      child: Icon(
                        entry.value,
                        size: AppIconSizes.lg,
                        color: isSelected
                            ? activeColor
                            : context.textPrimaryColor,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabHeader(BuildContext context) {
    return Container(
      height: 38.w,
      decoration: BoxDecoration(
        color: context.isDarkMode
            ? context.surfaceElevatedColor
            : context.cardBorderColor.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: context.cardBorderColor,
          width: AppSizes.borderWidth,
        ),
      ),
      child: TabBar(
        controller: _iconTabController,
        indicator: BoxDecoration(
          color: context.cardBackgroundColor,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: context.cardBorderColor,
            width: AppSizes.borderWidth,
          ),
          boxShadow: [
            BoxShadow(
              color: context.shadowColor,
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        labelColor: context.textPrimaryColor,
        unselectedLabelColor: context.textMutedColor,
        labelStyle: context.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: AppColors.transparent,
        tabs: const [
          Tab(text: 'Emoji Glyph'),
          Tab(text: 'Material Icon'),
        ],
      ),
    );
  }
}

/// Square selectable tile shared by the emoji and Material icon grids.
class _GlyphTile extends StatelessWidget {
  final bool isSelected;
  final Color activeColor;
  final VoidCallback onTap;
  final Widget child;

  const _GlyphTile({
    required this.isSelected,
    required this.activeColor,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36.r,
        height: 36.r,
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withValues(alpha: 0.22)
              : context.cardBackgroundColor,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: isSelected ? activeColor : context.cardBorderColor,
            width: isSelected ? AppSizes.borderWidthFocused : 1.0,
          ),
        ),
        child: Center(child: child),
      ),
    );
  }
}
