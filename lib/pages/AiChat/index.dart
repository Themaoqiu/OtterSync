import 'package:flutter/material.dart';
import 'package:ottersync/components/AiChat/Composer.dart';
import 'package:ottersync/components/AiChat/IntroPanel.dart';
import 'package:ottersync/components/AiChat/MessageBubbles.dart';
import 'package:ottersync/components/AiChat/TypingRow.dart';
import 'package:ottersync/services/ai_chat_service.dart';
import 'package:ottersync/theme/design_tokens.dart';

class AiChatView extends StatefulWidget {
  const AiChatView({super.key, AiChatService? service}) : _service = service;

  final AiChatService? _service;

  @override
  State<AiChatView> createState() => _AiChatViewState();
}

class _AiChatViewState extends State<AiChatView> {
  late final AiChatService _service;
  final TextEditingController _input = TextEditingController();
  final FocusNode _inputFocus = FocusNode();
  final ScrollController _scroll = ScrollController();

  final List<Map<String, dynamic>> _history = [];
  final List<_VisibleMessage> _visible = [];

  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _service = widget._service ?? AiChatService();
    _history.add({
      'role': 'system',
      'content': defaultSystemPrompt(DateTime.now()),
    });
    _input.addListener(() => setState(() {}));
    _inputFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _input.dispose();
    _inputFocus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppThemePalette.of(context);

    return Scaffold(
      backgroundColor: palette.scaffold,
      appBar: AppBar(
        backgroundColor: palette.scaffold,
        scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: palette.textPrimary,
            size: 20,
          ),
        ),
        title: Text(
          'AI 助手',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_visible.isNotEmpty)
            IconButton(
              tooltip: '新对话',
              onPressed: _resetConversation,
              icon: Icon(
                Icons.add_comment_outlined,
                color: palette.textPrimary,
                size: 22,
              ),
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: _buildMessageList()),
          if (_error != null)
            Container(
              width: double.infinity,
              color: palette.danger.withValues(alpha: 0.1),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                _error!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: palette.danger,
                ),
              ),
            ),
          Composer(
            controller: _input,
            focusNode: _inputFocus,
            sending: _sending,
            canSend: _input.text.trim().isNotEmpty,
            onSend: _send,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    if (_visible.isEmpty) {
      return IntroPanel(
        configured: _service.configured,
        onSuggestionTap: _useSuggestion,
      );
    }
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 24),
      itemCount: _visible.length + (_sending ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _visible.length) {
          return const TypingRow();
        }
        final msg = _visible[index];
        if (msg.fromUser) {
          return UserBubble(text: msg.text);
        }
        return AssistantRow(text: msg.text);
      },
    );
  }

  void _useSuggestion(String text) {
    _input.text = text;
    _inputFocus.requestFocus();
  }

  void _resetConversation() {
    setState(() {
      _visible.clear();
      _history
        ..clear()
        ..add({
          'role': 'system',
          'content': defaultSystemPrompt(DateTime.now()),
        });
      _error = null;
    });
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() {
      _error = null;
      _sending = true;
      _visible.add(_VisibleMessage(fromUser: true, text: text));
      _input.clear();
    });
    _history.add({'role': 'user', 'content': text});
    _scrollToBottom();

    try {
      final reply = await _service.respond(_history);
      if (!mounted) return;
      setState(() {
        _visible.add(
          _VisibleMessage(
            fromUser: false,
            text: reply.trim().isEmpty ? '（无回复）' : reply.trim(),
          ),
        );
        _sending = false;
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _error = '$e';
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }
}

class _VisibleMessage {
  const _VisibleMessage({required this.fromUser, required this.text});
  final bool fromUser;
  final String text;
}
