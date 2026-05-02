import 'package:flutter/material.dart';
import 'package:ottersync/components/Common/AppSurface.dart';
import 'package:ottersync/theme/design_tokens.dart';
import 'package:ottersync/viewmodels/work_item_models.dart';

class TypeSelectorBar extends StatelessWidget {
  const TypeSelectorBar({
    required this.workspace,
    required this.workType,
    required this.workspaces,
    required this.workTypes,
    required this.onWorkspaceChanged,
    required this.onWorkTypeChanged,
    required this.onWorkspaceLoadParentItems,
    super.key,
  });

  final LookupOption? workspace;
  final LookupOption? workType;
  final List<LookupOption> workspaces;
  final List<LookupOption> workTypes;
  final ValueChanged<LookupOption> onWorkspaceChanged;
  final ValueChanged<LookupOption> onWorkTypeChanged;
  final Future<void> Function() onWorkspaceLoadParentItems;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppThemePalette.of(context);

    return AppSurface(
      padding: EdgeInsets.zero,
      radius: AppSpace.radiusLarge,
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () async {
                  final result = await _pickLookup(
                    context,
                    title: '选择空间',
                    options: workspaces,
                    selected: workspace,
                  );
                  if (result != null) {
                    onWorkspaceChanged(result);
                    await onWorkspaceLoadParentItems();
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
                  child: Text(
                    workspace?.title ?? '选择空间',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ),
            ),
            VerticalDivider(width: 1, thickness: 1, color: palette.divider),
            InkWell(
              onTap: () async {
                final result = await _pickLookup(
                  context,
                  title: '选择工作类型',
                  options: workTypes,
                  selected: workType,
                );
                if (result != null) {
                  onWorkTypeChanged(result);
                }
              },
              child: Container(
                constraints: const BoxConstraints(minWidth: 180),
                padding: const EdgeInsets.fromLTRB(16, 18, 14, 18),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_box_outlined,
                      color: theme.colorScheme.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        workType?.title ?? '选择类型',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.arrow_drop_down_rounded, color: palette.textSecondary),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<LookupOption?> _pickLookup(
    BuildContext context, {
    required String title,
    required List<LookupOption> options,
    required LookupOption? selected,
  }) {
    return showModalBottomSheet<LookupOption?>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        final theme = Theme.of(context);
        final screenHeight = MediaQuery.of(context).size.height;
        final searchController = TextEditingController();
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
            child: StatefulBuilder(
              builder: (context, setSheetState) {
                final query = searchController.text.trim().toLowerCase();
                final filtered = options.where((item) {
                  if (query.isEmpty) {
                    return true;
                  }
                  return item.title.toLowerCase().contains(query) ||
                      (item.subtitle?.toLowerCase().contains(query) ?? false);
                }).toList(growable: false);
                return AppSurface(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
                  radius: AppSpace.radiusXLarge,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: theme.textTheme.titleLarge),
                      const SizedBox(height: 12),
                      TextField(
                        controller: searchController,
                        onChanged: (_) => setSheetState(() {}),
                        decoration: InputDecoration(
                          hintText: title == '选择空间' ? '搜索空间' : '搜索工作类型',
                          prefixIcon: const Icon(Icons.search_rounded),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (filtered.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Text('暂无可选项', style: theme.textTheme.bodyMedium),
                        )
                      else
                        SizedBox(
                          height: screenHeight * 0.5,
                          child: ListView.builder(
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final item = filtered[index];
                              final isSelected = item.id == selected?.id;
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(item.title),
                                subtitle: item.subtitle == null ? null : Text(item.subtitle!),
                                trailing: isSelected ? const Icon(Icons.check_rounded) : null,
                                onTap: () => Navigator.of(context).pop(item),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
