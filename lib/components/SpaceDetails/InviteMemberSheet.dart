import 'package:flutter/material.dart';
import 'package:ottersync/components/Common/SheetHeader.dart';
import 'package:ottersync/components/Common/UserAvatar.dart';
import 'package:ottersync/theme/design_tokens.dart';
import 'package:ottersync/viewmodels/work_item_api.dart';
import 'package:ottersync/viewmodels/work_item_models.dart';

class InviteMemberSheet extends StatefulWidget {
  const InviteMemberSheet({
    super.key,
    required this.api,
    required this.workspaceId,
  });

  final WorkItemApi api;
  final int workspaceId;

  @override
  State<InviteMemberSheet> createState() => _InviteMemberSheetState();
}

class _InviteMemberSheetState extends State<InviteMemberSheet> {
  final TextEditingController _controller = TextEditingController();
  List<LookupOption> _users = const [];
  bool _loadingUsers = true;
  bool _inviting = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onQueryChanged);
    _loadUsers();
  }

  @override
  void dispose() {
    _controller.removeListener(_onQueryChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onQueryChanged() => setState(() {});

  Future<void> _loadUsers() async {
    try {
      final users = await widget.api.listRegisteredUsers();
      if (!mounted) return;
      setState(() {
        _users = users;
        _loadingUsers = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _users = const [];
        _loadingUsers = false;
      });
    }
  }

  String _emailOf(LookupOption user) => user.subtitle ?? user.title;

  List<LookupOption> get _filtered {
    final query = _controller.text.trim().toLowerCase();
    if (query.isEmpty) return _users;
    return _users
        .where((user) =>
            user.title.toLowerCase().contains(query) ||
            (user.subtitle?.toLowerCase().contains(query) ?? false))
        .toList(growable: false);
  }

  Future<void> _invite(String email) async {
    final normalized = email.trim();
    if (normalized.isEmpty || _inviting) return;
    setState(() => _inviting = true);
    try {
      await widget.api.inviteWorkspaceMember(
        workspaceId: widget.workspaceId,
        email: normalized,
      );
      if (!mounted) return;
      Navigator.of(context).pop(normalized);
    } catch (error) {
      if (!mounted) return;
      setState(() => _inviting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('邀请失败：$error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppThemePalette.of(context);
    final theme = Theme.of(context);
    final maxHeight = MediaQuery.of(context).size.height * 0.7;
    final typed = _controller.text.trim();
    final filtered = _filtered;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SheetHeader(title: '邀请成员协作'),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: TextField(
                  controller: _controller,
                  autofocus: true,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  onSubmitted: _invite,
                  decoration: InputDecoration(
                    hintText: '输入邮箱邀请，或搜索已注册用户',
                    prefixIcon: const Icon(Icons.mail_outline_rounded),
                    isDense: true,
                  ),
                ),
              ),
              Flexible(
                child: _loadingUsers
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : ListView(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        children: [
                          if (typed.isNotEmpty &&
                              !filtered.any((u) =>
                                  _emailOf(u).toLowerCase() ==
                                  typed.toLowerCase()))
                            ListTile(
                              leading: CircleAvatar(
                                backgroundColor: palette.primarySoft,
                                child: Icon(Icons.send_rounded,
                                    color: palette.primary, size: 20),
                              ),
                              title: Text('邀请 “$typed”'),
                              subtitle: const Text('通过邮箱邀请'),
                              onTap: () => _invite(typed),
                            ),
                          ...filtered.map(
                            (user) => ListTile(
                              leading: UserAvatar(
                                label: user.title,
                                size: 36,
                              ),
                              title: Text(user.title),
                              subtitle: user.subtitle == null
                                  ? null
                                  : Text(user.subtitle!),
                              trailing: Icon(Icons.person_add_alt_1_rounded,
                                  color: palette.primary),
                              onTap: () => _invite(_emailOf(user)),
                            ),
                          ),
                          if (typed.isEmpty && filtered.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 32),
                              child: Center(
                                child: Text(
                                  '还没有可邀请的注册用户，直接输入邮箱即可邀请',
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ),
                            ),
                        ],
                      ),
              ),
              if (_inviting)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: LinearProgressIndicator(),
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
