import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'main.dart' show Catatan;

class DbHelper {
  DbHelper._(); // private constructor — tidak bisa di-instantiate dari luar
  static final DbHelper instance = DbHelper._(); // satu-satunya instance

  static const _dbName = 'catatan.db';
  static const _dbVersion = 1;
  static const tabel = 'catatan';

  Database? _db;

  /// Getter: return koneksi DB yang sudah ada, atau buka baru kalau belum.
  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _openDb();
    return _db!;
  }

  Future<Database> _openDb() async {
    final dir = await getDatabasesPath();
    final path = join(dir, _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: (db, version) async {
        // Dipanggil HANYA sekali saat file catatan.db belum ada.
        await db.execute('''
          CREATE TABLE $tabel (
            id          INTEGER PRIMARY KEY AUTOINCREMENT,
            judul       TEXT    NOT NULL,
            isi         TEXT    NOT NULL,
            kategori    TEXT    NOT NULL,
            dibuat_pada INTEGER NOT NULL
          )
        ''');
      },
    );
  }

  // ───────────────── CRUD ─────────────────

  /// INSERT — kembalikan id baris baru.
  Future<int> insert(Catatan c) async {
    final db = await database;
    return db.insert(tabel, c.toMap());
  }

  /// READ ALL — diurutkan terbaru di atas.
  Future<List<Catatan>> getAll() async {
    final db = await database;
    final rows = await db.query(tabel, orderBy: 'dibuat_pada DESC');
    return rows.map(Catatan.fromMap).toList();
  }

  /// UPDATE — selalu pakai whereArgs, bukan string interpolation (anti-injection).
  Future<int> update(Catatan c) async {
    assert(c.id != null, 'update dipanggil tapi id masih null');
    final db = await database;
    return db.update(
      tabel,
      c.toMap(),
      where: 'id = ?',
      whereArgs: [c.id],
    );
  }

  /// DELETE — sama, pakai whereArgs.
  Future<int> delete(int id) async {
    final db = await database;
    return db.delete(tabel, where: 'id = ?', whereArgs: [id]);
  }
}
