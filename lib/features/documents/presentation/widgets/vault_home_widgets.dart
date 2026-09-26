import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../domain/vault_document_sort.dart';

class VaultSearchField extends StatefulWidget {
  const VaultSearchField({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  State<VaultSearchField> createState() => _VaultSearchFieldState();
}

class _VaultSearchFieldState extends State<VaultSearchField> {
  late final FocusNode _focus;

  @override
  void initState() {
    super.initState();
    _focus = FocusNode()..addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final focused = _focus.hasFocus;

    return AnimatedContainer(
      duration: AppMotion.fast,
      curve: AppMotion.curve,
      decoration: BoxDecoration(
        borderRadius: AppRadius.cardBorder,
        border: Border.all(
          color: focused ? scheme.primary : scheme.outline,
          width: focused ? 1.5 : 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: AppRadius.cardBorder,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: TextField(
            focusNode: _focus,
            controller: widget.controller,
            onChanged: widget.onChanged,
            style: textTheme.bodyMedium,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search documents, tags or extracted text',
              filled: true,
              fillColor: AppColors.glassFill(scheme.brightness),
              prefixIcon: Icon(
                Icons.search_rounded,
                size: 22,
                color: focused ? scheme.primary : scheme.onSurfaceVariant,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class VaultPulseRow extends StatelessWidget {
  const VaultPulseRow({
    super.key,
    required this.documents,
    required this.expiring,
    required this.categories,
  });

  final int documents;
  final int expiring;
  final int categories;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: _PulseStat(
            label: 'Documents',
            value: documents,
            valueColor: scheme.onSurface,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: _PulseStat(
            label: 'Expiring',
            value: expiring,
            valueColor: expiring > 0
                ? AppColors.warning(scheme.brightness)
                : scheme.onSurface,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: _PulseStat(
            label: 'Categories',
            value: categories,
            valueColor: scheme.onSurface,
          ),
        ),
      ],
    );
  }
}

class _PulseStat extends StatelessWidget {
  const _PulseStat({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final String label;
  final int value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Semantics(
      container: true,
      label: '$value $label',
      child: ExcludeSemantics(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: AppRadius.cardBorder,
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.labelSmall,
                ),
                const SizedBox(height: AppSpacing.xxs),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '$value',
                    style: textTheme.titleLarge?.copyWith(color: valueColor),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class VaultBrowserToolbar extends StatelessWidget {
  const VaultBrowserToolbar({
    super.key,
    required this.grid,
    required this.onViewMode,
    required this.sortMode,
    required this.onSort,
    required this.filtersActive,
    required this.onFilters,
    required this.importing,
    required this.onImport,
  });

  final bool grid;
  final ValueChanged<bool> onViewMode;
  final VaultDocumentSort sortMode;
  final ValueChanged<VaultDocumentSort> onSort;
  final bool filtersActive;
  final VoidCallback onFilters;
  final bool importing;
  final VoidCallback? onImport;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        _ViewToggle(grid: grid, onViewMode: onViewMode),
        const Spacer(),
        PopupMenuButton<VaultDocumentSort>(
          tooltip: 'Sort',
          initialValue: sortMode,
          onSelected: onSort,
          icon: Icon(
            Icons.swap_vert_rounded,
            size: 22,
            color: scheme.onSurface,
          ),
          itemBuilder: (context) => [
            for (final mode in VaultDocumentSort.values)
              PopupMenuItem<VaultDocumentSort>(
                value: mode,
                child: Row(
                  children: [
                    SizedBox(
                      width: 28,
                      child: mode == sortMode
                          ? Icon(
                              Icons.check_rounded,
                              size: 20,
                              color: scheme.primary,
                            )
                          : null,
                    ),
                    Text(mode.menuLabel),
                  ],
                ),
              ),
          ],
        ),
        IconButton(
          tooltip: 'Filters',
          onPressed: onFilters,
          icon: Badge(
            isLabelVisible: filtersActive,
            smallSize: 8,
            backgroundColor: scheme.primary,
            child: Icon(Icons.tune_rounded, size: 22, color: scheme.onSurface),
          ),
        ),
        IconButton(
          tooltip: importing ? 'Importing' : 'Import files',
          onPressed: onImport,
          icon: importing
              ? SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: scheme.primary,
                  ),
                )
              : Icon(
                  Icons.file_upload_outlined,
                  size: 22,
                  color: scheme.onSurface,
                ),
        ),
      ],
    );
  }
}

class _ViewToggle extends StatelessWidget {
  const _ViewToggle({required this.grid, required this.onViewMode});

  final bool grid;
  final ValueChanged<bool> onViewMode;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: AppRadius.cardBorder,
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ViewButton(
            tooltip: 'List view',
            icon: Icons.view_list_outlined,
            selected: !grid,
            onPressed: () => onViewMode(false),
          ),
          _ViewButton(
            tooltip: 'Grid view',
            icon: Icons.grid_view_outlined,
            selected: grid,
            onPressed: () => onViewMode(true),
          ),
        ],
      ),
    );
  }
}

class _ViewButton extends StatelessWidget {
  const _ViewButton({
    required this.tooltip,
    required this.icon,
    required this.selected,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        selected: selected,
        label: tooltip,
        child: InkWell(
          onTap: onPressed,
          borderRadius: AppRadius.cardBorder,
          child: AnimatedContainer(
            duration: AppMotion.fast,
            curve: AppMotion.curve,
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? scheme.primaryContainer : Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadius.chip),
            ),
            child: Icon(
              icon,
              size: 22,
              color: selected ? scheme.primary : scheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

class VaultSelectionBar extends StatelessWidget {
  const VaultSelectionBar({
    super.key,
    required this.count,
    required this.allSelected,
    required this.onToggleSelectAll,
    required this.onCategory,
    required this.onExport,
    required this.onDelete,
    required this.onClose,
    required this.exporting,
    required this.actionsEnabled,
  });

  final int count;
  final bool allSelected;
  final VoidCallback onToggleSelectAll;
  final VoidCallback onCategory;
  final VoidCallback onExport;
  final VoidCallback onDelete;
  final VoidCallback onClose;
  final bool exporting;
  final bool actionsEnabled;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surface.withValues(alpha: 0.94),
            border: Border(top: BorderSide(color: scheme.outlineVariant)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xs,
                AppSpacing.xxs,
                AppSpacing.xs,
                AppSpacing.xxs,
              ),
              child: Row(
                children: [
                  const SizedBox(width: AppSpacing.sm),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 132),
                    child: Text(
                      '$count selected',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleMedium,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      reverse: true,
                      child: Row(
                        children: [
                          IconButton(
                            tooltip: allSelected
                                ? 'Clear selection'
                                : 'Select all',
                            onPressed: onToggleSelectAll,
                            icon: Icon(
                              allSelected
                                  ? Icons.deselect_rounded
                                  : Icons.select_all_rounded,
                              size: 22,
                            ),
                          ),
                          IconButton(
                            tooltip: 'Set category',
                            onPressed: actionsEnabled ? onCategory : null,
                            icon: const Icon(Icons.sell_outlined, size: 22),
                          ),
                          IconButton(
                            tooltip: exporting
                                ? 'Exporting'
                                : 'Export selected',
                            onPressed: actionsEnabled && !exporting
                                ? onExport
                                : null,
                            icon: const Icon(Icons.ios_share_rounded, size: 22),
                          ),
                          IconButton(
                            tooltip: 'Move selected to Trash',
                            onPressed: actionsEnabled ? onDelete : null,
                            icon: Icon(
                              Icons.delete_outline_rounded,
                              size: 22,
                              color: actionsEnabled ? scheme.error : null,
                            ),
                          ),
                          IconButton(
                            tooltip: 'Close selection',
                            onPressed: onClose,
                            icon: const Icon(Icons.close_rounded, size: 22),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class VaultEmptyState extends StatelessWidget {
  const VaultEmptyState({
    super.key,
    required this.filtered,
    required this.onClear,
    required this.onAdd,
  });

  final bool filtered;
  final VoidCallback onClear;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(AppRadius.fab),
              ),
              child: SizedBox(
                width: 88,
                height: 88,
                child: Icon(
                  filtered
                      ? Icons.search_off_outlined
                      : Icons.folder_open_outlined,
                  size: 36,
                  color: scheme.primary,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              filtered ? 'No matching documents' : 'No documents yet',
              textAlign: TextAlign.center,
              style: textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              filtered
                  ? 'Try different search words or filters.'
                  : 'Add images, scans, or PDFs. Everything stays encrypted on this device.',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (filtered)
              FilledButton.tonalIcon(
                onPressed: onClear,
                icon: const Icon(Icons.filter_alt_off_outlined, size: 20),
                label: const Text('Clear filters'),
              )
            else
              FilledButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text('Add document'),
              ),
          ],
        ),
      ),
    );
  }
}

class VaultListSkeleton extends StatelessWidget {
  const VaultListSkeleton({
    super.key,
    required this.grid,
    required this.columns,
  });

  final bool grid;
  final int columns;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bone = scheme.surfaceContainerHighest;
    if (grid) {
      return GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: columns * 2,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          mainAxisSpacing: AppSpacing.sm,
          crossAxisSpacing: AppSpacing.sm,
          mainAxisExtent: 220,
        ),
        itemBuilder: (context, index) => _Bone(
          color: bone,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: ColoredBox(color: scheme.surfaceContainerLow)),
              const SizedBox(height: AppSpacing.sm),
              _Bar(width: 120, color: scheme.surfaceContainerLow),
              const SizedBox(height: AppSpacing.xs),
              _Bar(width: 72, color: scheme.surfaceContainerLow),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        for (var i = 0; i < 6; i++) ...[
          _Bone(
            color: bone,
            height: 84,
            child: Row(
              children: [
                _Box(size: 56, color: scheme.surfaceContainerLow),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Bar(width: 160, color: scheme.surfaceContainerLow),
                      const SizedBox(height: AppSpacing.xs),
                      _Bar(width: 96, color: scheme.surfaceContainerLow),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (i != 5) const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}

class _Bone extends StatelessWidget {
  const _Bone({required this.color, required this.child, this.height});

  final Color color;
  final Widget child;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.45),
        borderRadius: AppRadius.cardBorder,
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: SizedBox(
        height: height,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: child,
        ),
      ),
    );
  }
}

class _Box extends StatelessWidget {
  const _Box({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: SizedBox(width: size, height: size),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.width, required this.color});

  final double width;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: SizedBox(width: width, height: 12),
    );
  }
}

class VaultHomeRail extends StatelessWidget {
  const VaultHomeRail({
    super.key,
    required this.extended,
    required this.onToggleExtended,
    required this.onCategories,
    required this.onSettings,
  });

  final bool extended;
  final VoidCallback onToggleExtended;
  final VoidCallback onCategories;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: AppMotion.standard,
      curve: AppMotion.curve,
      width: extended ? 208 : 80,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(right: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.sm),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: scheme.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: SizedBox(
                width: 36,
                height: 36,
                child: Icon(
                  Icons.lock_outline_rounded,
                  size: 20,
                  color: scheme.onPrimary,
                ),
              ),
            ),
          ),
          Expanded(
            child: NavigationRail(
              extended: extended,
              minWidth: 80,
              minExtendedWidth: 208,
              backgroundColor: Colors.transparent,
              selectedIndex: 0,
              groupAlignment: -1,
              onDestinationSelected: (index) {
                if (index == 1) onCategories();
                if (index == 2) onSettings();
              },
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.inventory_2_outlined),
                  selectedIcon: Icon(Icons.inventory_2_outlined),
                  label: Text('Vault'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.sell_outlined),
                  selectedIcon: Icon(Icons.sell_outlined),
                  label: Text('Categories'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.settings_outlined),
                  selectedIcon: Icon(Icons.settings_outlined),
                  label: Text('Settings'),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: extended ? 'Collapse sidebar' : 'Expand sidebar',
            onPressed: onToggleExtended,
            icon: Icon(
              extended
                  ? Icons.keyboard_arrow_left_rounded
                  : Icons.keyboard_arrow_right_rounded,
              size: 22,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
      ),
    );
  }
}
