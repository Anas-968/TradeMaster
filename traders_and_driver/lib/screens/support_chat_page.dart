import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../language_controller.dart';

class SupportChatPage extends StatefulWidget {
  const SupportChatPage({super.key});
  @override
  State<SupportChatPage> createState() => _SupportChatPageState();
}

class _SupportChatPageState extends State<SupportChatPage> {
  final _db = Supabase.instance.client;
  final _input = TextEditingController();
  String? _id, _error;
  bool _admin = false, _loading = true, _sending = false;
  @override
  void initState() {
    super.initState();
    _admin = _db.auth.currentUser?.appMetadata['is_admin'] == true;
    if (_admin) {
      _loading = false;
    } else {
      _open();
    }
  }

  Future<void> _open() async {
    var user = _db.auth.currentUser;
    if (user == null) {
      try {
        user = (await _db.auth.signInAnonymously()).user;
      } on AuthException catch (error) {
        if (mounted)
          setState(() {
            _loading = false;
            _error =
                'Guest chat could not start. Check anonymous sign-in settings and the Supabase database logs.';
          });
        return;
      } catch (_) {
        if (mounted)
          setState(() {
            _loading = false;
            _error = 'Could not start guest chat. Please try again.';
          });
        return;
      }
    }
    if (user == null) {
      if (mounted)
        setState(() {
          _loading = false;
          _error = 'Could not start guest chat. Please try again.';
        });
      return;
    }
    try {
      final row =
          await _db
              .from('support_conversations')
              .select('id')
              .eq('user_id', user.id)
              .eq('status', 'open')
              .order('updated_at', ascending: false)
              .limit(1)
              .maybeSingle() ??
          await _db
              .from('support_conversations')
              .insert({'user_id': user.id})
              .select('id')
              .single();
      if (mounted)
        setState(() {
          _id = row['id'].toString();
          _loading = false;
        });
    } catch (_) {
      if (mounted)
        setState(() {
          _loading = false;
          _error =
              'Support chat is unavailable. Apply the live support database migration and try again.';
        });
    }
  }

  Future<void> _deleteConversation(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(appText('Delete support chat?')),
        content: Text(appText('This permanently deletes the conversation and all its messages.')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(appText('Cancel'))),
          TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text(appText('Delete'))),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _db.from('support_conversations').delete().eq('id', id);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(appText('Could not delete this support chat.'))),
        );
      }
    }
  }
  Future<void> _send() async {
    final text = _input.text.trim(), id = _id;
    if (text.isEmpty || id == null || _sending || text.length > 4000) return;
    setState(() => _sending = true);
    _input.clear();
    try {
      await _db.from('support_messages').insert({
        'conversation_id': id,
        'sender_id': _db.auth.currentUser!.id,
        'body': text,
      });
    } catch (_) {
      if (mounted) {
        _input.text = text;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(appText('Message could not be sent. Try again.')),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_error != null)
      return Scaffold(
        appBar: AppBar(title: Text(appText('Live Support'))),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(_error!, textAlign: TextAlign.center),
          ),
        ),
      );
    if (_admin && _id == null) return _inbox();
    return _chat();
  }

  Widget _inbox() => Scaffold(
    appBar: AppBar(
      title: Text(appText('Support Inbox')),
      automaticallyImplyLeading: false,
    ),

    body: StreamBuilder<List<Map<String, dynamic>>>(
      stream: _db
          .from('support_conversations')
          .stream(primaryKey: ['id'])
          .order('updated_at', ascending: false),
      builder: (context, snapshot) {
        if (snapshot.hasError)
          return Center(child: Text(appText('Could not load support requests.')));
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        final rows = snapshot.data!;
        if (rows.isEmpty)
          return Center(child: Text(appText('No support requests yet.')));
        return ListView(
          children: rows.map((row) {
            final uid = row['user_id'].toString();
            return ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person_outline)),
              title: Text(appText('Customer ') + uid.substring(0, 8)),
              subtitle: Text(appText('Support request · ') + row['status'].toString()),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: appText('Delete support chat'),
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _deleteConversation(row['id'].toString()),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
              onTap: () => setState(() => _id = row['id'].toString()),
            );
          }).toList(),
        );
      },
    ),
  );
  Widget _chat() => Scaffold(
    appBar: AppBar(
      leading: _admin
          ? BackButton(onPressed: () => setState(() => _id = null))
          : null,
      title: Text(_admin ? 'Customer Support' : 'Live Support'),
      actions: !_admin
          ? [
              Padding(
                padding: EdgeInsets.only(right: 14),
                child: Center(child: Text(appText('A support agent will reply here'))),
              ),
            ]
          : null,
    ),
    body: Column(
      children: [
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _db
                .from('support_messages')
                .stream(primaryKey: ['id'])
                .eq('conversation_id', _id!)
                .order('created_at', ascending: true),
            builder: (context, snapshot) {
              if (snapshot.hasError)
                return Center(child: Text(appText('Could not load messages.')));
              if (!snapshot.hasData)
                return const Center(child: CircularProgressIndicator());
              final messages = snapshot.data!;
              if (messages.isEmpty)
                return Center(
                  child: Text(appText('Send a message to reach our support team.')),
                );
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: messages.length,
                itemBuilder: (context, i) {
                  final message = messages[i],
                      mine = message['sender_id'] == _db.auth.currentUser?.id;
                  return Align(
                    alignment: mine
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 300),
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: mine
                            ? const Color(0xFF1A237E)
                            : Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        message['body'].toString(),
                        style: TextStyle(color: mine ? Colors.white : null),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _input,
                    minLines: 1,
                    maxLines: 4,
                    maxLength: 4000,
                    decoration: InputDecoration(
                      hintText: appText('Message support'),
                      border: OutlineInputBorder(),
                      counterText: '',
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  tooltip: appText('Send message'),
                  onPressed: _sending ? null : _send,
                  icon: _sending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
