import 'dart:convert';

// Keep the Material import compatible with earlier Flutter SDKs.
// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const themeKey = 'app_theme_dark_mode';
const nameKey = 'user_display_name';
const notesKey = 'notes_json';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final isDark = prefs.getBool(themeKey) ?? false;
  final name = prefs.getString(nameKey) ?? 'Guest User';
  final storedNotes = prefs.getString(notesKey);
  var notes = <NoteItem>[];
  if (storedNotes != null) {
    try {
      final decoded = jsonDecode(storedNotes) as List<dynamic>;
      notes = decoded
          .map((item) => NoteItem.fromJson(item as Map<String, dynamic>))
          .toList();
    } on FormatException {
      debugPrint('Could not decode cached notes.');
    } on TypeError {
      debugPrint('Cached notes have an invalid structure.');
    }
  }
  runApp(NotesVault(prefs: prefs, isDark: isDark, name: name, notes: notes));
}

class NoteItem {
  const NoteItem({
    required this.id,
    required this.title,
    required this.dateText,
    required this.isCompleted,
  });

  final String id;
  final String title;
  final String dateText;
  final bool isCompleted;

  factory NoteItem.fromJson(Map<String, dynamic> json) => NoteItem(
    id: json['id'] as String,
    title: json['title'] as String,
    dateText: json['dateText'] as String,
    isCompleted: json['isCompleted'] as bool,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'dateText': dateText,
    'isCompleted': isCompleted,
  };
}

class NotesVault extends StatefulWidget {
  const NotesVault({
    super.key,
    required this.prefs,
    required this.isDark,
    required this.name,
    required this.notes,
  });

  final SharedPreferences prefs;
  final bool isDark;
  final String name;
  final List<NoteItem> notes;

  @override
  State<NotesVault> createState() => _NotesVaultState();
}

class _NotesVaultState extends State<NotesVault> {
  final _messenger = GlobalKey<ScaffoldMessengerState>();
  late bool _isDark = widget.isDark;
  late String _name = widget.name;
  late List<NoteItem> _notes = widget.notes;
  late final _nameInput = TextEditingController(text: _name);
  final _noteInput = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _nameInput.dispose();
    _noteInput.dispose();
    super.dispose();
  }

  Future<void> _save(Future<bool> Function() write, VoidCallback apply) async {
    if (_saving) return;
    setState(() => _saving = true);
    var success = false;
    try {
      success = await write();
    } catch (error) {
      debugPrint('Local save failed: $error');
    }
    if (!mounted) return;
    setState(() {
      if (success) apply();
      _saving = false;
    });
    if (!success) {
      _messenger.currentState?.showSnackBar(
        const SnackBar(content: Text('Could not save changes. Try again.')),
      );
    }
  }

  void _saveName() {
    final input = _nameInput.text.trim();
    final name = input.isEmpty ? 'Guest User' : input;
    _save(() => widget.prefs.setString(nameKey, name), () {
      _name = name;
      if (_nameInput.text.trim() == input) _nameInput.text = name;
    });
  }

  void _saveNotes(List<NoteItem> notes, {VoidCallback? afterSave}) {
    final json = jsonEncode(notes.map((note) => note.toJson()).toList());
    _save(() => widget.prefs.setString(notesKey, json), () {
      _notes = notes;
      afterSave?.call();
    });
  }

  void _addNote(BuildContext context) {
    final title = _noteInput.text.trim();
    if (title.isEmpty) return;
    final now = DateTime.now();
    final note = NoteItem(
      id: now.microsecondsSinceEpoch.toString(),
      title: title,
      dateText: MaterialLocalizations.of(context).formatMediumDate(now),
      isCompleted: false,
    );
    _saveNotes(
      [note, ..._notes],
      afterSave: () {
        if (_noteInput.text.trim() == title) _noteInput.clear();
      },
    );
  }

  void _toggleNote(NoteItem selected, bool completed) {
    _saveNotes([
      for (final note in _notes)
        if (note.id == selected.id)
          NoteItem(
            id: note.id,
            title: note.title,
            dateText: note.dateText,
            isCompleted: completed,
          )
        else
          note,
    ]);
  }

  ThemeData _theme(Brightness brightness) => ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xff21695e),
      brightness: brightness,
    ),
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
    ),
  );

  Widget _inputRow({
    required TextEditingController controller,
    required String label,
    required String action,
    required int limit,
    required VoidCallback onSubmit,
  }) => LayoutBuilder(
    builder: (context, constraints) {
      final input = TextField(
        controller: controller,
        maxLength: limit,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => onSubmit(),
        decoration: InputDecoration(labelText: label, counterText: ''),
      );
      final button = FilledButton(
        onPressed: _saving ? null : onSubmit,
        child: Text(action),
      );
      if (constraints.maxWidth < 340) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [input, const SizedBox(height: 8), button],
        );
      }
      return Row(
        children: [
          Expanded(child: input),
          const SizedBox(width: 12),
          button,
        ],
      );
    },
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scaffoldMessengerKey: _messenger,
      title: 'Notes Vault',
      debugShowCheckedModeBanner: false,
      theme: _theme(Brightness.light),
      darkTheme: _theme(Brightness.dark),
      themeMode: _isDark ? ThemeMode.dark : ThemeMode.light,
      home: Builder(
        builder: (context) {
          final theme = Theme.of(context);
          return Scaffold(
            appBar: AppBar(title: const Text('Notes Vault')),
            body: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    children: [
                      Text(
                        'Hello, $_name',
                        style: theme.textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 16),
                      _inputRow(
                        controller: _nameInput,
                        label: 'Display name',
                        action: 'Save',
                        limit: 48,
                        onSubmit: _saveName,
                      ),
                      const SizedBox(height: 12),
                      Card(
                        margin: EdgeInsets.zero,
                        child: SwitchListTile(
                          secondary: const Icon(Icons.dark_mode_outlined),
                          title: const Text('Dark mode'),
                          value: _isDark,
                          onChanged: _saving
                              ? null
                              : (value) => _save(
                                  () => widget.prefs.setBool(themeKey, value),
                                  () => _isDark = value,
                                ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      Text('Notes', style: theme.textTheme.titleLarge),
                      const SizedBox(height: 12),
                      _inputRow(
                        controller: _noteInput,
                        label: 'Note title',
                        action: 'Add note',
                        limit: 160,
                        onSubmit: () => _addNote(context),
                      ),
                      const SizedBox(height: 12),
                      if (_notes.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Text('No notes yet.'),
                        ),
                      for (final note in _notes)
                        Card(
                          key: ValueKey(note.id),
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: Checkbox(
                              semanticLabel: 'Complete ${note.title}',
                              value: note.isCompleted,
                              onChanged: _saving
                                  ? null
                                  : (checked) =>
                                        _toggleNote(note, checked ?? false),
                            ),
                            title: Text(
                              note.title,
                              style: note.isCompleted
                                  ? const TextStyle(
                                      decoration: TextDecoration.lineThrough,
                                    )
                                  : null,
                            ),
                            subtitle: Text(note.dateText),
                            trailing: IconButton(
                              tooltip: 'Delete note',
                              icon: const Icon(Icons.delete_outline),
                              onPressed: _saving
                                  ? null
                                  : () => _saveNotes([
                                      for (final item in _notes)
                                        if (item.id != note.id) item,
                                    ]),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
