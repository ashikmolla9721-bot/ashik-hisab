import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Local SQLite database for all modules:
///  - calc_history : every finished calculation with timestamp
///  - customers    : customer profiles (name, phone, address)
///  - transactions : জমা (credit=1) / বাকি (debit=0) entries per customer
///  - notes        : notepad entries with creation/update timestamps
class DbHelper {
  DbHelper._();
  static final DbHelper instance = DbHelper._();

  static Database? _db;

  Future<Database> get database async {
    _db ??= await _init();
    return _db!;
  }

  Future<Database> _init() async {
    final dir = await getDatabasesPath();
    final path = join(dir, 'ashik_hisab.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, v) async {
        await db.execute('''
          CREATE TABLE calc_history (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            expression TEXT NOT NULL,
            result TEXT NOT NULL,
            created_at INTEGER NOT NULL
          )''');
        await db.execute('''
          CREATE TABLE customers (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            phone TEXT,
            address TEXT,
            created_at INTEGER NOT NULL
          )''');
        await db.execute('''
          CREATE TABLE transactions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            customer_id INTEGER NOT NULL,
            is_jama INTEGER NOT NULL,
            amount REAL NOT NULL,
            note TEXT,
            created_at INTEGER NOT NULL,
            FOREIGN KEY (customer_id) REFERENCES customers(id)
              ON DELETE CASCADE
          )''');
        await db.execute('''
          CREATE TABLE notes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            body TEXT NOT NULL,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL
          )''');
        await db.execute(
            'CREATE INDEX idx_tx_customer ON transactions(customer_id)');
        await db.execute(
            'CREATE INDEX idx_calc_time ON calc_history(created_at)');
      },
    );
  }

  // ---------- calc_history ----------
  Future<int> insertCalc(String expression, String result, int createdAt) async {
    final db = await database;
    return db.insert('calc_history', {
      'expression': expression,
      'result': result,
      'created_at': createdAt,
    });
  }

  Future<List<Map<String, Object?>>> getAllCalcs() async {
    final db = await database;
    return db.query('calc_history', orderBy: 'created_at DESC');
  }

  Future<int> clearCalcs() async {
    final db = await database;
    return db.delete('calc_history');
  }

  // ---------- customers ----------
  Future<int> insertCustomer(Map<String, Object?> row) async {
    final db = await database;
    return db.insert('customers', row);
  }

  Future<int> updateCustomer(int id, Map<String, Object?> row) async {
    final db = await database;
    return db.update('customers', row, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteCustomer(int id) async {
    final db = await database;
    return db.delete('customers', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, Object?>>> getAllCustomers() async {
    final db = await database;
    return db.query('customers', orderBy: 'name COLLATE NOCASE');
  }

  // ---------- transactions ----------
  Future<int> insertTx(Map<String, Object?> row) async {
    final db = await database;
    return db.insert('transactions', row);
  }

  Future<int> deleteTx(int id) async {
    final db = await database;
    return db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, Object?>>> getTxForCustomer(int customerId) async {
    final db = await database;
    return db.query('transactions',
        where: 'customer_id = ?',
        whereArgs: [customerId],
        orderBy: 'created_at DESC');
  }

  /// Per-customer totals: SUM(jama), SUM(baki), net balance.
  Future<Map<int, List<double>>> getCustomerTotals() async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT customer_id,
             SUM(CASE WHEN is_jama = 1 THEN amount ELSE 0 END) AS jama,
             SUM(CASE WHEN is_jama = 0 THEN amount ELSE 0 END) AS baki
      FROM transactions GROUP BY customer_id
    ''');
    final map = <int, List<double>>{};
    for (final r in rows) {
      final j = (r['jama'] as num?)?.toDouble() ?? 0;
      final b = (r['baki'] as num?)?.toDouble() ?? 0;
      map[r['customer_id'] as int] = [j, b, b - j]; // net due = baki - jama
    }
    return map;
  }

  /// Grand totals for the dashboard: [totalJama, totalBaki, netDue].
  Future<List<double>> getGrandTotals() async {
    final db = await database;
    final r = (await db.rawQuery('''
      SELECT SUM(CASE WHEN is_jama = 1 THEN amount ELSE 0 END) AS jama,
             SUM(CASE WHEN is_jama = 0 THEN amount ELSE 0 END) AS baki
      FROM transactions
    ''')).first;
    final j = (r['jama'] as num?)?.toDouble() ?? 0;
    final b = (r['baki'] as num?)?.toDouble() ?? 0;
    return [j, b, b - j];
  }

  // ---------- notes ----------
  Future<int> insertNote(Map<String, Object?> row) async {
    final db = await database;
    return db.insert('notes', row);
  }

  Future<int> updateNote(int id, Map<String, Object?> row) async {
    final db = await database;
    return db.update('notes', row, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteNote(int id) async {
    final db = await database;
    return db.delete('notes', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, Object?>>> getAllNotes() async {
    final db = await database;
    return db.query('notes', orderBy: 'updated_at DESC');
  }

  // ---------- settings ----------
  Future<void> wipeAllData() async {
    final db = await database;
    await db.delete('transactions');
    await db.delete('customers');
    await db.delete('notes');
    await db.delete('calc_history');
  }
}
