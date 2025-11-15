import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/product.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('amazon_tracker.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';
    const realType = 'REAL NOT NULL';
    const intType = 'INTEGER NOT NULL';

    await db.execute('''
      CREATE TABLE products (
        id $idType,
        asin $textType,
        title $textType,
        imageUrl $textType,
        currentPrice $realType,
        originalPrice REAL,
        currency $textType,
        url $textType,
        lastUpdated $textType,
        targetPrice REAL,
        isTracking $intType
      )
    ''');

    await db.execute('''
      CREATE TABLE price_history (
        id $idType,
        productId $textType,
        price $realType,
        timestamp $textType,
        FOREIGN KEY (productId) REFERENCES products (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> insertProduct(Product product) async {
    final db = await database;
    await db.insert(
      'products',
      product.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> insertPriceHistory(PriceHistory history) async {
    final db = await database;
    await db.insert(
      'price_history',
      history.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Product>> getAllProducts() async {
    final db = await database;
    final result = await db.query('products', orderBy: 'lastUpdated DESC');
    return result.map((json) => Product.fromJson(json)).toList();
  }

  Future<Product?> getProduct(String id) async {
    final db = await database;
    final maps = await db.query(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Product.fromJson(maps.first);
    }
    return null;
  }

  Future<List<PriceHistory>> getPriceHistory(String productId) async {
    final db = await database;
    final result = await db.query(
      'price_history',
      where: 'productId = ?',
      whereArgs: [productId],
      orderBy: 'timestamp ASC',
    );
    return result.map((json) => PriceHistory.fromJson(json)).toList();
  }

  Future<void> updateProduct(Product product) async {
    final db = await database;
    await db.update(
      'products',
      product.toJson(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<void> deleteProduct(String id) async {
    final db = await database;
    await db.delete(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
    await db.delete(
      'price_history',
      where: 'productId = ?',
      whereArgs: [id],
    );
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }
}
