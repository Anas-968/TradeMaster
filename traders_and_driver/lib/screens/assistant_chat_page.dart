import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AssistantChatPage extends StatefulWidget {
  const AssistantChatPage({super.key});

  @override
  State<AssistantChatPage> createState() => _AssistantChatPageState();
}

class _AssistantChatPageState extends State<AssistantChatPage> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final List<_ChatMessage> _messages = [
    const _ChatMessage(
      text:
          'Hi! I’m your TradeMaster assistant. Ask me about using the app, posting loads, or finding a driver.',
      fromUser: false,
    ),
  ];
  bool _sending = false;

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send([String? suggestedText]) async {
    final text = (suggestedText ?? _input.text).trim();
    if (text.isEmpty || _sending) return;
    if (Supabase.instance.client.auth.currentSession == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to chat with the assistant.'),
        ),
      );
      return;
    }

    setState(() {
      _messages.add(_ChatMessage(text: text, fromUser: true));
      _input.clear();
      _sending = true;
    });
    _scrollToEnd();

    try {
      final history = _messages.skip(1).toList();
      if (history.length > 20) {
        history.removeRange(0, history.length - 20);
      }
      final response = await Supabase.instance.client.functions.invoke(
        'dynamic-function',
        body: {
          'messages': history
              .map(
                (message) => {
                  'role': message.fromUser ? 'user' : 'assistant',
                  'content': message.text,
                },
              )
              .toList(),
        },
      );
      final data = response.data;
      final reply = data is Map ? data['reply']?.toString().trim() : null;
      if (reply == null || reply.isEmpty) {
        throw const FormatException(
          'The assistant returned an empty response.',
        );
      }
      if (!mounted) return;
      setState(() => _messages.add(_ChatMessage(text: reply, fromUser: false)));
    } on FunctionException catch (error) {
      if (!mounted) return;
      debugPrint('Assistant function request failed: $error');
      final message = _functionErrorMessage(error);
      setState(
        () => _messages.add(
          _ChatMessage(text: message, fromUser: false, isError: true),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _messages.add(
          const _ChatMessage(
            text:
                'I couldn’t reach the assistant. Please check your connection and try again.',
            fromUser: false,
            isError: true,
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _sending = false);
        _scrollToEnd();
      }
    }
  }

  String _functionErrorMessage(FunctionException error) {
    if (error.status == 404) {
      return 'The assistant service was not found (HTTP 404). Deploy the assistant-chat Supabase function and try again.';
    }
    if (error.status == 401 || error.status == 403) {
      return 'Supabase rejected this request (HTTP ${error.status}). Sign out and back in, then check that the function accepts authenticated users.';
    }

    final details = error.details;
    String? detail;
    if (details is Map) {
      detail = details['error']?.toString() ?? details['message']?.toString();
    } else if (details is String && details.trim().isNotEmpty) {
      detail = details
          .trim()
          .replaceAll(RegExp(r'<[^>]*>'), ' ')
          .replaceAll(RegExp(r'\s+'), ' ');
    }
    detail ??= error.reasonPhrase;
    if (detail == null || detail.trim().isEmpty) {
      return 'The assistant request failed (HTTP ${error.status}). Please check the Supabase function logs and setup.';
    }
    final conciseDetail = detail.length > 240
        ? '${detail.substring(0, 240)}...'
        : detail;
    return 'Assistant request failed (HTTP ${error.status}): $conciseDetail';
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Row(
          children: [
            CircleAvatar(
              radius: 17,
              backgroundColor: Color(0xFFE8EAF6),
              child: Icon(
                Icons.auto_awesome,
                size: 19,
                color: Color(0xFF1A237E),
              ),
            ),
            SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('TradeMaster Assistant', style: TextStyle(fontSize: 16)),
                Text(
                  'Here to help',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.normal),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
              itemCount: _messages.length + (_sending ? 1 : 0),
              itemBuilder: (context, index) {
                if (_sending && index == _messages.length) {
                  return const Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.all(10),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  );
                }
                final message = _messages[index];
                return Align(
                  alignment: message.fromUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.sizeOf(context).width * 0.8,
                    ),
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 11,
                    ),
                    decoration: BoxDecoration(
                      color: message.fromUser
                          ? colors.primary
                          : message.isError
                          ? colors.errorContainer
                          : colors.surfaceContainerHighest,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(18),
                        topRight: const Radius.circular(18),
                        bottomLeft: Radius.circular(message.fromUser ? 18 : 4),
                        bottomRight: Radius.circular(message.fromUser ? 4 : 18),
                      ),
                    ),
                    child: SelectableText(
                      message.text,
                      style: TextStyle(
                        color: message.fromUser
                            ? colors.onPrimary
                            : colors.onSurface,
                        height: 1.4,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_messages.length == 1)
            SizedBox(
              height: 46,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  _suggestion('How do I post a load?'),
                  _suggestion('How can I find a driver?'),
                  _suggestion('How do I accept a load?'),
                ],
              ),
            ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      minLines: 1,
                      maxLines: 5,
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: 'Ask TradeMaster…',
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    tooltip: 'Send message',
                    onPressed: _sending ? null : () => _send(),
                    icon: const Icon(Icons.arrow_upward),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _suggestion(String text) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4),
    child: ActionChip(
      label: Text(text),
      onPressed: _sending ? null : () => _send(text),
    ),
  );
}

class _ChatMessage {
  const _ChatMessage({
    required this.text,
    required this.fromUser,
    this.isError = false,
  });

  final String text;
  final bool fromUser;
  final bool isError;
}
