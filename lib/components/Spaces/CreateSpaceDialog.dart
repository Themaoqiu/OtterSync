import 'package:flutter/material.dart';
import 'package:ottersync/theme/design_tokens.dart';
import 'package:ottersync/viewmodels/jira_models.dart';

class WorkspaceCreateDialogResult {
  const WorkspaceCreateDialogResult({
    required this.name,
    required this.key,
    required this.template,
  });

  final String name;
  final String key;
  final String template;
}

class CreateSpaceDialog extends StatefulWidget {
  const CreateSpaceDialog({super.key});

  @override
  State<CreateSpaceDialog> createState() => _CreateSpaceDialogState();
}

class _CreateSpaceDialogState extends State<CreateSpaceDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _keyController = TextEditingController();
  String _selectedTemplate = '看板';
  bool _keyEditedManually = false;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_handleNameChanged);
  }

  @override
  void dispose() {
    _nameController.removeListener(_handleNameChanged);
    _nameController.dispose();
    _keyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppThemePalette.of(context);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: palette.border,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Text('创建空间', style: theme.textTheme.headlineMedium),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                      tooltip: '关闭',
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '名称、模板和 key 会立即写入真实空间数据。',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: '空间名称',
                    hintText: '例如：ottersync',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '请输入空间名称';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: _selectedTemplate,
                  decoration: const InputDecoration(labelText: '空间模板'),
                  items: const [
                    DropdownMenuItem(value: '看板', child: Text('看板')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedTemplate = value);
                    }
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _keyController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: '空间 Key',
                    hintText: '例如：OTTE',
                    helperText: '会根据空间名称自动生成，也可以手动修改',
                  ),
                  onChanged: (value) {
                    _keyEditedManually = value.trim().isNotEmpty;
                  },
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '请输入空间 Key';
                    }
                    final normalized = value.trim().toUpperCase();
                    final valid = RegExp(r'^[A-Z]{2,4}$').hasMatch(normalized);
                    if (!valid) {
                      return '空间 Key 需要是 2 到 4 个大写字母';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _submit,
                    child: const Text('创建空间'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleNameChanged() {
    if (_keyEditedManually) {
      return;
    }
    final generated = generateWorkspaceKey(_nameController.text);
    if (_keyController.text != generated) {
      _keyController.value = TextEditingValue(
        text: generated,
        selection: TextSelection.collapsed(offset: generated.length),
      );
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    Navigator.of(context).pop(
      WorkspaceCreateDialogResult(
        name: _nameController.text.trim(),
        key: _keyController.text.trim().toUpperCase(),
        template: _selectedTemplate,
      ),
    );
  }
}
