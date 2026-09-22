import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._();
  static Database? _db;

  DatabaseHelper._();

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final path = join(await getDatabasesPath(), 'notes.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, _) => db.execute(
        'CREATE TABLE notes(id INTEGER PRIMARY KEY AUTOINCREMENT, text TEXT NOT NULL)',
      ),
    );
  }

  Future<void> insert(String text) async {
    final db = await database;
    await db.insert('notes', {'text': text});
  }

  Future<List<String>> getAll() async {
    final db = await database;
    final rows = await db.query('notes', orderBy: 'id ASC');
    return rows.map((r) => r['text'] as String).toList();
  }

  Future<void> deleteAll() async {
    final db = await database;
    await db.delete('notes');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Notas',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _controller = TextEditingController();
  List<String> _notes = [];

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    final notes = await DatabaseHelper.instance.getAll();
    setState(() => _notes = notes);
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    await DatabaseHelper.instance.insert(text);
    _controller.clear();
    await _loadNotes();
  }

  Future<void> _deleteAll() async {
    await DatabaseHelper.instance.deleteAll();
    setState(() => _notes = []);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notas'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever),
            tooltip: 'Apagar tudo',
            onPressed: _notes.isEmpty ? null : _deleteAll,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Digite algo...',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: _send,
                  icon: const Icon(Icons.send),
                  label: const Text('Enviar'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _notes.isEmpty
                  ? const Center(
                      child: Text(
                        'Nenhuma nota ainda.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _notes.length,
                      itemBuilder: (context, index) {
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text(_notes[index]),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
