import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/note_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('notes.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE notes ADD COLUMN color INTEGER DEFAULT 4294967295');
    }
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const intType = 'INTEGER DEFAULT 4294967295';

    await db.execute('''
CREATE TABLE notes (
  id $idType,
  title $textType,
  content $textType,
  timestamp $textType,
  color $intType
)
''');

    // Insert dummy data on creation as requested
    await db.insert('notes', {
      'title': 'شراء احتياجات البيت',
      'content': 'لبن، خبز، قهوة، ومناديل.',
      'timestamp': DateTime.now().toIso8601String(),
    });
    await db.insert('notes', {
      'title': 'أفكار الأسبوع',
      'content': 'ترتيب المكتب وإنهاء قراءة الفصل الثالث.',
      'timestamp': DateTime.now().toIso8601String(),
    });
    await db.insert('notes', {
      'title': 'تذكير',
      'content': 'الاتصال بمحمد يوم الخميس الساعة 6 مساءً.',
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Future<Note> create(Note note) async {
    final db = await instance.database;
    final id = await db.insert('notes', note.toMap());
    note.id = id;
    return note;
  }

  Future<Note?> readNote(int id) async {
    final db = await instance.database;
    final maps = await db.query(
      'notes',
      columns: ['id', 'title', 'content', 'timestamp'],
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Note.fromMap(maps.first);
    } else {
      return null;
    }
  }

  Future<List<Note>> readAllNotes() async {
    final db = await instance.database;
    const orderBy = 'timestamp DESC';
    final result = await db.query('notes', orderBy: orderBy);
    return result.map((json) => Note.fromMap(json)).toList();
  }

  Future<int> update(Note note) async {
    final db = await instance.database;
    return db.update(
      'notes',
      note.toMap(),
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await instance.database;
    return await db.delete(
      'notes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
