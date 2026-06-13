import 'package:flutter/material.dart';
import 'package:ottersync/components/Common/SheetHeader.dart';
import 'package:ottersync/theme/design_tokens.dart';

/// 可搜索选择器的一个选项。
class PickerEntry<T> {
  const PickerEntry({
    required this.value,
    required this.label,
    this.subtitle,
    this.icon,
    this.iconColor,
  });

  final T value;
  final String label;
  final String? subtitle;
  final IconData? icon;
  final Color? iconColor;
}

/// 通用的「从列表里选一项」底部弹窗：带标题、可搜索、空状态。
///
/// 智能显隐搜索框：选项数 > [searchThreshold]（默认 5）时才显示搜索框，
/// 小列表保持简洁。返回选中项的 value；用户关闭弹窗时返回 null。
Future<T?> showSearchablePicker<T>({
  required BuildContext context,
  required String title,
  required List<PickerEntry<T>> entries,
  T? current,
  String? searchHint,
  String emptyLabel = '没有匹配的选项',
  int searchThreshold = 5,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) {
      final palette = AppThemePalette.of(sheetContext);
      final searchController = TextEditingController();
      final showSearch = entries.length > searchThreshold;
      final maxHeight = MediaQuery.of(sheetContext).size.height * 0.7;
      return SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: StatefulBuilder(
              builder: (context, setSheetState) {
                final query = searchController.text.trim().toLowerCase();
                final filtered = query.isEmpty
                    ? entries
                    : entries
                        .where((e) =>
                            e.label.toLowerCase().contains(query) ||
                            (e.subtitle?.toLowerCase().contains(query) ?? false))
                        .toList(growable: false);
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SheetHeader(title: title),
                    if (showSearch)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        child: TextField(
                          controller: searchController,
                          autofocus: true,
                          onChanged: (_) => setSheetState(() {}),
                          decoration: InputDecoration(
                            hintText: searchHint ?? '搜索',
                            prefixIcon: const Icon(Icons.search_rounded),
                            isDense: true,
                          ),
                        ),
                      ),
                    Flexible(
                      child: filtered.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.symmetric(vertical: 32),
                              child: Text(
                                emptyLabel,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final entry = filtered[index];
                                final selected = entry.value == current;
                                return ListTile(
                                  leading: entry.icon == null
                                      ? null
                                      : Icon(entry.icon, color: entry.iconColor),
                                  title: Text(entry.label),
                                  subtitle: entry.subtitle == null
                                      ? null
                                      : Text(entry.subtitle!),
                                  trailing: selected
                                      ? Icon(Icons.check_rounded,
                                          color: palette.primary)
                                      : null,
                                  onTap: () =>
                                      Navigator.of(context).pop(entry.value),
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 8),
                  ],
                );
              },
            ),
          ),
        ),
      );
    },
  );
}
