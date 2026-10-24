import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Optional feedback: Contact, Rating, Survey / Suggestions.
/// User-filled only; copies a mailto draft and opens instructions.
class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  static const supportEmail = 'sales@sharadasoft.com';

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Feedback'),
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: Colors.amber,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Contact'),
            Tab(text: 'Rate'),
            Tab(text: 'Survey'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: const [
          _ContactTab(),
          _RatingTab(),
          _SurveyTab(),
        ],
      ),
    );
  }
}

Future<void> _sendMail({
  required BuildContext context,
  required String subject,
  required String body,
}) async {
  final draft = 'To: ${FeedbackScreen.supportEmail}\nSubject: $subject\n\n$body';
  await Clipboard.setData(ClipboardData(text: draft));
  if (!context.mounted) return;
  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Ready to send'),
      content: Text(
        'Your message was copied to the clipboard.\n\n'
        'Open your email app, paste into a new message to:\n'
        '${FeedbackScreen.supportEmail}',
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
      ],
    ),
  );
}

class _PrivacyNote extends StatelessWidget {
  const _PrivacyNote();

  @override
  Widget build(BuildContext context) {
    return Text(
      'Nothing is sent automatically. Your message is only prepared when you tap Send — then you paste it into your own email app.',
      style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
    );
  }
}

class _ContactTab extends StatefulWidget {
  const _ContactTab();

  @override
  State<_ContactTab> createState() => _ContactTabState();
}

class _ContactTabState extends State<_ContactTab> {
  final _name = TextEditingController();
  final _contact = TextEditingController();
  final _message = TextEditingController();
  bool _consent = false;

  @override
  void dispose() {
    _name.dispose();
    _contact.dispose();
    _message.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('Contact us', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const _PrivacyNote(),
        const SizedBox(height: 16),
        TextField(
          controller: _name,
          decoration: const InputDecoration(labelText: 'Name (optional)', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _contact,
          decoration: const InputDecoration(
            labelText: 'Email or phone (optional)',
            border: OutlineInputBorder(),
            helperText: 'Only if you want a reply — you type it yourself',
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _message,
          decoration: const InputDecoration(
            labelText: 'Message *',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
          minLines: 4,
          maxLines: 8,
        ),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          value: _consent,
          onChanged: (v) => setState(() => _consent = v ?? false),
          title: const Text('I agree to be contacted about this message'),
          controlAffinity: ListTileControlAffinity.leading,
        ),
        FilledButton.icon(
          onPressed: () {
            final msg = _message.text.trim();
            if (msg.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a message')));
              return;
            }
            if (!_consent) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please agree to be contacted')));
              return;
            }
            _sendMail(
              context: context,
              subject: 'Classic Games Hub — Contact',
              body: [
                'Name: ${_name.text.trim().isEmpty ? '(not provided)' : _name.text.trim()}',
                'Contact: ${_contact.text.trim().isEmpty ? '(not provided)' : _contact.text.trim()}',
                '',
                msg,
              ].join('\n'),
            );
          },
          icon: const Icon(Icons.copy_all),
          label: const Text('Copy & send via email'),
        ),
      ],
    );
  }
}

class _RatingTab extends StatefulWidget {
  const _RatingTab();

  @override
  State<_RatingTab> createState() => _RatingTabState();
}

class _RatingTabState extends State<_RatingTab> {
  int _stars = 0;
  final _comment = TextEditingController();
  String? _favoriteGame;

  static const _games = ['Ludo', 'Snake & Ladder', 'Chess', '2048', 'Snake', 'Other'];

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('Rate the app', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const _PrivacyNote(),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (i) {
            final n = i + 1;
            return IconButton(
              iconSize: 36,
              onPressed: () => setState(() => _stars = n),
              icon: Icon(n <= _stars ? Icons.star : Icons.star_border, color: Colors.amber.shade700),
            );
          }),
        ),
        DropdownButtonFormField<String>(
          // ignore: deprecated_member_use
          value: _favoriteGame,
          decoration: const InputDecoration(labelText: 'Favorite game (optional)', border: OutlineInputBorder()),
          items: _games.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
          onChanged: (v) => setState(() => _favoriteGame = v),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _comment,
          decoration: const InputDecoration(labelText: 'Comments (optional)', border: OutlineInputBorder(), alignLabelWithHint: true),
          minLines: 3,
          maxLines: 6,
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () {
            if (_stars < 1) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a star rating')));
              return;
            }
            _sendMail(
              context: context,
              subject: 'Classic Games Hub — Rating $_stars/5',
              body: [
                'Rating: $_stars / 5',
                'Favorite game: ${_favoriteGame ?? '(not selected)'}',
                '',
                _comment.text.trim().isEmpty ? '(no comment)' : _comment.text.trim(),
              ].join('\n'),
            );
          },
          icon: const Icon(Icons.star),
          label: const Text('Copy rating for email'),
        ),
      ],
    );
  }
}

class _SurveyTab extends StatefulWidget {
  const _SurveyTab();

  @override
  State<_SurveyTab> createState() => _SurveyTabState();
}

class _SurveyTabState extends State<_SurveyTab> {
  String? _howOften;
  String? _difficulty;
  String? _wantMore;
  final _suggestion = TextEditingController();
  final Set<String> _improvements = {};

  static const _improveOptions = [
    'More games',
    'Better graphics',
    'Online multiplayer',
    'Sound / music',
    'Tutorials',
    'Performance',
  ];

  @override
  void dispose() {
    _suggestion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('Survey & suggestions', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const _PrivacyNote(),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          // ignore: deprecated_member_use
          value: _howOften,
          decoration: const InputDecoration(labelText: 'How often do you play?', border: OutlineInputBorder()),
          items: const [
            DropdownMenuItem(value: 'Daily', child: Text('Daily')),
            DropdownMenuItem(value: 'Weekly', child: Text('Weekly')),
            DropdownMenuItem(value: 'Occasionally', child: Text('Occasionally')),
            DropdownMenuItem(value: 'First time', child: Text('First time')),
          ],
          onChanged: (v) => setState(() => _howOften = v),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          // ignore: deprecated_member_use
          value: _difficulty,
          decoration: const InputDecoration(labelText: 'Game difficulty feels…', border: OutlineInputBorder()),
          items: const [
            DropdownMenuItem(value: 'Too easy', child: Text('Too easy')),
            DropdownMenuItem(value: 'Just right', child: Text('Just right')),
            DropdownMenuItem(value: 'Too hard', child: Text('Too hard')),
          ],
          onChanged: (v) => setState(() => _difficulty = v),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          // ignore: deprecated_member_use
          value: _wantMore,
          decoration: const InputDecoration(labelText: 'What should we add next?', border: OutlineInputBorder()),
          items: const [
            DropdownMenuItem(value: 'Board games', child: Text('More board games')),
            DropdownMenuItem(value: 'Card games', child: Text('More card games')),
            DropdownMenuItem(value: 'Arcade', child: Text('More arcade')),
            DropdownMenuItem(value: 'Puzzles', child: Text('More puzzles')),
          ],
          onChanged: (v) => setState(() => _wantMore = v),
        ),
        const SizedBox(height: 16),
        const Text('What should we improve?', style: TextStyle(fontWeight: FontWeight.w600)),
        Wrap(
          spacing: 8,
          children: _improveOptions.map((o) {
            final selected = _improvements.contains(o);
            return FilterChip(
              label: Text(o),
              selected: selected,
              onSelected: (v) {
                setState(() {
                  if (v) {
                    _improvements.add(o);
                  } else {
                    _improvements.remove(o);
                  }
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _suggestion,
          decoration: const InputDecoration(
            labelText: 'Your suggestion *',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
          minLines: 3,
          maxLines: 6,
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () {
            final s = _suggestion.text.trim();
            if (s.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a suggestion')));
              return;
            }
            _sendMail(
              context: context,
              subject: 'Classic Games Hub — Survey / Suggestion',
              body: [
                'Play frequency: ${_howOften ?? '(skipped)'}',
                'Difficulty: ${_difficulty ?? '(skipped)'}',
                'Want more: ${_wantMore ?? '(skipped)'}',
                'Improve: ${_improvements.isEmpty ? '(none)' : _improvements.join(', ')}',
                '',
                'Suggestion:',
                s,
              ].join('\n'),
            );
          },
          icon: const Icon(Icons.lightbulb_outline),
          label: const Text('Copy survey for email'),
        ),
      ],
    );
  }
}
