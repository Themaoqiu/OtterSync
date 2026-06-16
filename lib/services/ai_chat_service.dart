import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:ottersync/viewmodels/jira_models.dart';
import 'package:ottersync/services/work_item_service.dart';
import 'package:ottersync/viewmodels/work_item_models.dart';

///
class AiChatService {
  AiChatService({WorkItemService? api, http.Client? client})
    : _api = api ?? WorkItemService(),
      _http = client ?? http.Client();

  final WorkItemService _api;
  final http.Client _http;

  String get _apiKey => dotenv.env['OPENAI_API_KEY'] ?? '';
  String get _model => dotenv.env['OPENAI_MODEL'] ?? 'gpt-4o-mini';
  String get _baseUrl =>
      dotenv.env['OPENAI_BASE_URL'] ?? 'https://api.openai.com/v1';

  bool get configured => _apiKey.isNotEmpty && !_apiKey.startsWith('sk-...');

  static final List<Map<String, dynamic>> _tools = [
    {
      'type': 'function',
      'function': {
        'name': 'list_spaces',
        'description': '列出当前所有工作空间，返回 id / name / key。',
        'parameters': {'type': 'object', 'properties': {}},
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'list_work_types',
        'description': '列出所有工作类型（任务、缺陷、故事等），返回 id 与名称。',
        'parameters': {'type': 'object', 'properties': {}},
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'list_sprints',
        'description': '列出指定空间的冲刺。',
        'parameters': {
          'type': 'object',
          'properties': {
            'workspace_id': {
              'type': 'integer',
              'description': '工作空间 id（来自 list_spaces）',
            },
          },
          'required': ['workspace_id'],
        },
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'list_users',
        'description': '列出所有可作为经办人/报告人的用户。',
        'parameters': {'type': 'object', 'properties': {}},
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'create_work_item',
        'description':
            '在指定空间创建工作项。在调用之前必须明确 workspace_id、work_type_id、summary。'
            '若用户未提供则先用 list_* 工具查询并向用户确认。',
        'parameters': {
          'type': 'object',
          'properties': {
            'workspace_id': {'type': 'integer'},
            'work_type_id': {'type': 'integer'},
            'summary': {'type': 'string', 'description': '工作项标题'},
            'description': {'type': 'string'},
            'assignee_id': {'type': 'integer'},
            'reporter_id': {'type': 'integer'},
            'sprint_id': {'type': 'integer'},
            'start_date': {
              'type': 'string',
              'description': 'ISO-8601 日期，如 2026-06-10',
            },
            'due_date': {
              'type': 'string',
              'description': 'ISO-8601 日期，如 2026-06-15',
            },
            'priority': {
              'type': 'string',
              'enum': ['Highest', 'High', 'Medium', 'Low', 'Lowest'],
            },
          },
          'required': ['workspace_id', 'work_type_id', 'summary'],
        },
      },
    },
  ];

  ///
  Future<String> respond(List<Map<String, dynamic>> messages) async {
    if (!configured) {
      throw const AiChatException(
        'OpenAI API key 未配置：请在项目根 .env 文件中填写 OPENAI_API_KEY。',
      );
    }

    for (var i = 0; i < 6; i++) {
      final response = await _callOpenAi(messages);
      final choice =
          (response['choices'] as List).first as Map<String, dynamic>;
      final message = choice['message'] as Map<String, dynamic>;

      messages.add({
        'role': 'assistant',
        if (message['content'] != null) 'content': message['content'],
        if (message['tool_calls'] != null) 'tool_calls': message['tool_calls'],
      });

      final toolCalls = message['tool_calls'] as List?;
      if (toolCalls == null || toolCalls.isEmpty) {
        return (message['content'] as String?) ?? '';
      }

      for (final raw in toolCalls) {
        final call = raw as Map<String, dynamic>;
        final fn = call['function'] as Map<String, dynamic>;
        final name = fn['name'] as String;
        final args = _parseArgs(fn['arguments'] as String?);
        final result = await _runTool(name, args);
        messages.add({
          'role': 'tool',
          'tool_call_id': call['id'],
          'content': result,
        });
      }
    }
    throw const AiChatException('AI 调用工具次数过多，已自动终止。');
  }

  Future<Map<String, dynamic>> _callOpenAi(
    List<Map<String, dynamic>> messages,
  ) async {
    final uri = Uri.parse('$_baseUrl/chat/completions');
    final res = await _http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      },
      body: jsonEncode({
        'model': _model,
        'messages': messages,
        'tools': _tools,
        'tool_choice': 'auto',
        'temperature': 0.3,
      }),
    );
    if (res.statusCode >= 400) {
      throw AiChatException('OpenAI 调用失败 (${res.statusCode})：${res.body}');
    }
    return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
  }

  Map<String, dynamic> _parseArgs(String? raw) {
    if (raw == null || raw.isEmpty) return const {};
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return const {};
    }
  }

  Future<String> _runTool(String name, Map<String, dynamic> args) async {
    try {
      switch (name) {
        case 'list_spaces':
          final spaces = await _api.listSpaces();
          return jsonEncode(
            spaces
                .map((s) => {'id': s.id, 'name': s.name, 'key': s.key})
                .toList(),
          );
        case 'list_work_types':
          final lookups = await _api.loadCreateLookups();
          return jsonEncode(
            lookups.workTypes
                .map(
                  (o) => {'id': o.id, 'title': o.title, 'subtitle': o.subtitle},
                )
                .toList(),
          );
        case 'list_sprints':
          final wsId = (args['workspace_id'] as num?)?.toInt();
          if (wsId == null) {
            return jsonEncode({'error': '缺少 workspace_id'});
          }
          final sprints = await _api.listSprints(workspaceId: wsId);
          return jsonEncode(
            sprints
                .map(
                  (s) => {'id': s.id, 'name': s.name, 'status': s.status.name},
                )
                .toList(),
          );
        case 'list_users':
          final lookups = await _api.loadCreateLookups();
          return jsonEncode(
            lookups.users.map((o) => {'id': o.id, 'title': o.title}).toList(),
          );
        case 'create_work_item':
          return await _createWorkItem(args);
      }
    } catch (e) {
      return jsonEncode({'error': '$e'});
    }
    return jsonEncode({'error': 'unknown tool: $name'});
  }

  Future<String> _createWorkItem(Map<String, dynamic> args) async {
    final lookups = await _api.loadCreateLookups();
    final wsId = (args['workspace_id'] as num?)?.toInt();
    final wtId = (args['work_type_id'] as num?)?.toInt();
    final summary = (args['summary'] as String?)?.trim();
    if (wsId == null || wtId == null || summary == null || summary.isEmpty) {
      return jsonEncode({
        'error': 'workspace_id / work_type_id / summary 必须全部提供。',
      });
    }
    final reporterId =
        (args['reporter_id'] as num?)?.toInt() ??
        (lookups.users.isNotEmpty ? lookups.users.first.id : 1);

    DateTime? parseDate(Object? raw) {
      if (raw is! String) return null;
      try {
        return DateTime.parse(raw);
      } catch (_) {
        return null;
      }
    }

    final sprintId = (args['sprint_id'] as num?)?.toInt();
    final created = await _api.createWorkItem(
      WorkItemCreateRequest(
        workspaceId: wsId,
        workTypeId: wtId,
        summary: summary,
        description: args['description'] as String?,
        reporterId: reporterId,
        assigneeId: (args['assignee_id'] as num?)?.toInt(),
        sprintId: sprintId,
        bucket: sprintId != null
            ? WorkItemBucket.sprint
            : WorkItemBucket.backlog,
        startDate: parseDate(args['start_date']),
        dueDate: parseDate(args['due_date']),
      ),
    );
    return jsonEncode({
      'ok': true,
      'id': created.id,
      'key': created.key,
      'summary': created.summary,
    });
  }
}

class AiChatException implements Exception {
  const AiChatException(this.message);
  final String message;

  @override
  String toString() => message;
}

String defaultSystemPrompt(DateTime now) {
  final today =
      '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  return '''
你是 OtterSync 的 AI 助手，负责帮助用户在 Flutter 客户端里创建和管理工作项。
今天的日期是 $today，时区按用户本地。

工作流程：
1. 用户描述要做什么后，先用 list_spaces / list_work_types 等工具查询真实数据，
   不要凭空猜 id。
2. 如果空间名称、工作类型、截止时间等关键信息缺失或有歧义，必须先反问用户确认；
   只有信息齐全时才调用 create_work_item。
3. 创建成功后，用一两句话告诉用户结果，包含工作项 key 和标题。
4. 用简体中文回复。回复要简洁，不要重复用户已经知道的细节。
''';
}
