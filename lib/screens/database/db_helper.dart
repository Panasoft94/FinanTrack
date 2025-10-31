import 'dart:io'; //on utilise le fichier
import 'package:budget/screens/accounts/accounts_screen.dart';
import 'package:budget/screens/config/base_config_screen.dart';
import 'package:budget/screens/devises/devises_screen.dart';
import 'package:budget/screens/expense_category/expense_category_screen.dart';
import 'package:budget/screens/user_account/user_account_screen.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';


class DbHelper{

  static Database? _db;
  static const String CONFIG_TABLE = 'config';
  static const String CONFIG_ID = 'config_id';
  static const String APP_NAME = 'app_name';
  static const String DEFAULT_LANGUAGE = 'default_language';
  static const String DEFAULT_YEAR = 'default_year';
  static const String SELECTED_DEVISE_ID = 'selected_devise_id';

  static const String DEVISE_TABLE = 'devises';
  static const String DEVISE_ID = 'devise_id';
  static const String DEVISE_LIB = 'devise_lib';
  static const String DEVISE_VAL = 'devise_val';
  static const String DEVISE_SYMBOLE = 'devise_symbole';

  static const String USERS_TABLE = 'users';
  static const String USER_ID = 'user_id';
  static const String USER_NAME = 'user_name';
  static const String USER_EMAIL = 'user_email';
  static const String USER_PASSWORD = 'user_password';
  static const String USER_PIN = 'user_pin';
  static const String USER_PHONE = 'user_phone';
  static const String USER_ROLE = 'user_role';
  static const String USER_STATUS = 'user_status';
  static const String USER_CREATED_AT = 'user_created_at';
  static const String USER_UPDATED_AT = 'user_updated_at';
  static const String ACEPT_LICENCE = 'acept_licence';

  static const String TABLE_NOTIFICATIONS = 'notifications';
  static const String NOTIFICATION_ID = 'notification_id';
  static const String NOTIFICATION_TITRE = 'notification_titre';
  static const String NOTIFICATION_CONTENU = 'notification_contenu';
  static const String NOTIFICATION_DATE = 'notification_date';

  static const String TRANSACTION_TABLE = 'transactions';
  static const String TRANSACTION_ID = 'transaction_id';
  static const String MONTANT = 'montant';
  static const String TRANSACTION_DATE = 'transaction_date';
  static const String TRANSACTION_TYPE = 'transaction_type';
  static const String TRANSACTION_CREATED_AT = 'transaction_created_at';
  static const String TRANSACTION_UPDATED_AT = 'transaction_updated_at';
  static const String TRANSACTION_DESCRIPTION = 'transaction_description';
  static const String TRANSACTION_ATTACHMENT = 'transaction_attachment';

  static const String ACCOUNTS_TABLE = 'accounts';
  static const String ACCOUNT_ID = 'account_id';
  static const String ACCOUNT_NAME = 'account_name';
  static const String ACCOUNT_TYPE = 'account_type';
  static const String ACCOUNT_BALANCE = 'account_balance';
  static const String ACCOUNT_ICON = 'account_icon';
  static const String ACCOUNT_CREATED_AT = 'account_created_at';
  static const String ACCOUNT_UPDATED_AT = 'account_updated_at';

  static const String CATEGORIES_TABLE = 'categories';
  static const String CATEGORY_ID = 'id';
  static const String CATEGORY_NAME = 'name';
  static const String CATEGORY_TYPE = 'type';
  static const String CATEGORY_ICON = 'icon';
  static const String CATEGORY_COLOR = 'color';

  static const String BUDGET_TABLE = 'budgets';
  static const String BUDGET_ID = 'budget_id';
  static const String BUDGET_NAME = 'budget_name';
  static const String BUDGET_AMOUNT = 'budget_amount';
  static const String BUDGET_START_DATE = 'budget_start_date';
  static const String BUDGET_END_DATE = 'budget_end_date';
  static const String BUDGET_CREATED_AT = 'budget_created_at';
  static const String BUDGET_UPDATED_AT = 'budget_updated_at';
  static const String BUDGET_STATUS = 'budget_status';


  static Future<Database?>getdb() async{
    if(_db != null){
      return _db!;
    }
    _db = await _initDb();
    return _db!;
  }

  //recherche de la base de données
  static Future<Database?> _initDb() async{
    String path = join(await getDatabasesPath(),'finantrack.db');
    return await openDatabase(path,version: 1,
        onCreate: (Database db,int version) async{
          await db.execute("CREATE TABLE $ACCOUNTS_TABLE($ACCOUNT_ID INTEGER PRIMARY KEY AUTOINCREMENT,$ACCOUNT_NAME TEXT,$ACCOUNT_TYPE TEXT,$ACCOUNT_BALANCE REAL,$ACCOUNT_ICON TEXT,$ACCOUNT_CREATED_AT TEXT,$ACCOUNT_UPDATED_AT TEXT)");
          await db.execute("CREATE TABLE $CATEGORIES_TABLE($CATEGORY_ID INTEGER PRIMARY KEY AUTOINCREMENT, $CATEGORY_NAME TEXT NOT NULL,$CATEGORY_TYPE TEXT NOT NULL,$CATEGORY_ICON TEXT,$CATEGORY_COLOR TEXT NOT NULL DEFAULT '#007AFF')");
          await db.execute("""CREATE TABLE $TRANSACTION_TABLE(
            $TRANSACTION_ID INTEGER PRIMARY KEY AUTOINCREMENT,
            $MONTANT REAL NOT NULL,
            $ACCOUNT_ID INTEGER,
            $CATEGORY_ID INTEGER,
            $TRANSACTION_DATE TEXT NOT NULL,
            $TRANSACTION_TYPE TEXT NOT NULL,
            $TRANSACTION_DESCRIPTION TEXT,
            $TRANSACTION_ATTACHMENT TEXT,
            $TRANSACTION_CREATED_AT TEXT,
            $TRANSACTION_UPDATED_AT TEXT,
            FOREIGN KEY ($ACCOUNT_ID) REFERENCES $ACCOUNTS_TABLE ($ACCOUNT_ID) ON DELETE SET NULL,
            FOREIGN KEY ($CATEGORY_ID) REFERENCES $CATEGORIES_TABLE ($CATEGORY_ID) ON DELETE SET NULL
          )""");
          await db.execute("CREATE TABLE $BUDGET_TABLE($BUDGET_ID INTEGER PRIMARY KEY AUTOINCREMENT,$BUDGET_NAME TEXT,$BUDGET_AMOUNT REAL, $CATEGORY_ID INTEGER,$BUDGET_START_DATE TEXT,$BUDGET_END_DATE TEXT,$BUDGET_CREATED_AT TEXT,$BUDGET_UPDATED_AT TEXT,$BUDGET_STATUS INTEGER)");
          await db.execute("CREATE TABLE $DEVISE_TABLE($DEVISE_ID INTEGER PRIMARY KEY AUTOINCREMENT,$DEVISE_LIB TEXT,$DEVISE_VAL TEXT,$DEVISE_SYMBOLE TEXT)");
          await db.execute("CREATE TABLE $USERS_TABLE($USER_ID INTEGER PRIMARY KEY AUTOINCREMENT,$USER_NAME TEXT,$USER_EMAIL TEXT,$USER_PASSWORD TEXT,$USER_PIN INTEGER,$USER_PHONE TEXT,$USER_ROLE TEXT,$USER_STATUS INTEGER,$USER_CREATED_AT TEXT,$USER_UPDATED_AT TEXT,$ACEPT_LICENCE INTEGER)");
          await db.execute("CREATE TABLE $CONFIG_TABLE($CONFIG_ID INTEGER PRIMARY KEY AUTOINCREMENT,$APP_NAME TEXT,$DEFAULT_LANGUAGE TEXT,$DEFAULT_YEAR INTEGER,$SELECTED_DEVISE_ID TEXT)");
          await db.execute("CREATE TABLE $TABLE_NOTIFICATIONS($NOTIFICATION_ID INTEGER PRIMARY KEY AUTOINCREMENT,$NOTIFICATION_TITRE TEXT,$NOTIFICATION_CONTENU TEXT,$NOTIFICATION_DATE TEXT)");
        });
  }

  // Insère la configuration par défaut si aucune n'existe
  static Future<void> insertDefaultConfig() async {
    final dbClient = await getdb();
    final List<Map<String, dynamic>> configs = await dbClient!.query(CONFIG_TABLE);
    if (configs.isEmpty) {
      final data = {
        APP_NAME: 'FinanTrack',
        DEFAULT_LANGUAGE: 'Français',
        DEFAULT_YEAR: DateTime.now().year,
        SELECTED_DEVISE_ID: '1', // ID par défaut pour la devise
      };
      await dbClient.insert(CONFIG_TABLE, data);
    }
  }

  //recuperation des informations de la config
  static Future<List<Map<String,dynamic>>>getConfig() async{
    final dbClient = await getdb();
    return await dbClient!.query(CONFIG_TABLE);
  }

  static Future<List<Map<String,dynamic>>> getDevise() async{
    final dbClient = await getdb();
    return await dbClient!.query(DEVISE_TABLE);
  }

  static Future<List<Map<String,dynamic>>> getUser() async{
    final dbClient = await getdb();
    return await dbClient!.query(USERS_TABLE);
  }


  //modification de la licence
  static Future<int>updateLicence(int user_id, int acept_licence) async{
    final dbClient = await getdb();
    final data = {'acept_licence':acept_licence};
    return await dbClient!.update(USERS_TABLE, data,where: '$USER_ID = ?',whereArgs: [user_id]);
  }
  //sauvegarde de la base de données
  backUp() async{
    var status = await Permission.manageExternalStorage.status;
    if(!status.isGranted){
      await Permission.manageExternalStorage.request();
    }
    var status1 = await Permission.storage.status;
    if(!status1.isGranted){
      await Permission.storage.request();
    }
    try{
      File ourDBFile = File('/data/user/0/com.example.budget/databases/finantrack.db');
      Directory? folderPathForDBFILE = Directory("/storage/emulated/0/Download/finantrackDatabase/");
      await folderPathForDBFILE.create();
      //suppression du fichier existant
      File ourDBFile2 = File("/storage/emulated/0/Download/finantrackDatabase/finantrack.db");
      // Check if the file exists before attempting to delete
      if (await ourDBFile2.exists()) {
        await ourDBFile2.delete();
      }
      //copie du fichier
      await ourDBFile.copy("/storage/emulated/0/Download/finantrackDatabase/tontine.db");
    } 
    catch (e){
      print(e);
    }
  }
//restauration de la base de données
  restorer() async{
    var status = await Permission.manageExternalStorage.status;
    if(!status.isGranted){
      await Permission.manageExternalStorage.request();
    }
    var status1 = await Permission.storage.status;
    if(!status1.isGranted){
      await Permission.storage.request();
    }
    try{
      File savedDBFile = File("/storage/emulated/0/Download/finantrackDatabase/finantrack.db");
      // Check if the source file exists before attempting to copy
      if (await savedDBFile.exists()) {
        await savedDBFile.copy('/data/user/0/com.example.budget/databases/tontine.db');
      } else {
        print("Source DB file for restore not found: ${savedDBFile.path}");
      }
    }
    catch (e){
      print(e);
    }
  }

  deleteDB() async{
    try{
      String path = join(await getDatabasesPath(), 'tontine.db');
      await databaseExists(path).then((exists) async {
        if (exists) {
          await deleteDatabase(path);
          _db = null; // Reset the static _db instance
          print("Database deleted successfully.");
        } else {
          print("Database not found at path: $path");
        }
      });
    }
    catch (e){
      print("Error deleting database: $e");
    }
  }

//recherche du chemin de la base de données
  getDbPath() async{
    String databasePath = await getDatabasesPath();//on récupère le chemin de la base de données
    // Directory? externalStoragePath = await getExternalStorageDirectory(); // This line seems unused
    print("Database path: $databasePath");
    return databasePath;
  }

// Opérations CRUD pour la table des comptes (Accounts)
  static Future<int> insertAccount(Map<String, dynamic> data) async {
    final dbClient = await getdb();
    // Ajoute la date de création avant l'insertion
    data[ACCOUNT_CREATED_AT] = DateTime.now().toIso8601String();
    return await dbClient!.insert(ACCOUNTS_TABLE, data);
  }

  static Future<List<Account>> getAccounts() async {
    final dbClient = await getdb();
    final List<Map<String, dynamic>> maps = await dbClient!.query(ACCOUNTS_TABLE, orderBy: '$ACCOUNT_ID DESC');
    return List.generate(maps.length, (i) {
      return Account.fromMap(maps[i]);
    });
  }

  static Future<int> updateAccount(Map<String, dynamic> data) async {
    final dbClient = await getdb();
    final int accountId = data[ACCOUNT_ID];
    // La date de mise à jour est déjà dans le .toMap() du modèle
    return await dbClient!.update(ACCOUNTS_TABLE, data, where: '$ACCOUNT_ID = ?', whereArgs: [accountId]);
  }

  static Future<int> deleteAccount(int id) async {
    final dbClient = await getdb();
    return await dbClient!.delete(ACCOUNTS_TABLE, where: '$ACCOUNT_ID = ?', whereArgs: [id]);
  }
  
  // Opérations CRUD pour la table des catégories (Categories)
  static Future<int> insertCategory(Map<String, dynamic> data) async {
    final dbClient = await getdb();
    return await dbClient!.insert(CATEGORIES_TABLE, data);
  }

  static Future<List<Category>> getCategories(String type) async {
    final dbClient = await getdb();
    final List<Map<String, dynamic>> maps = await dbClient!.query(
      CATEGORIES_TABLE,
      where: '$CATEGORY_TYPE = ?',
      whereArgs: [type],
      orderBy: '$CATEGORY_ID DESC',
    );
    return List.generate(maps.length, (i) {
      return Category.fromMap(maps[i]);
    });
  }

  static Future<int> updateCategory(Map<String, dynamic> data) async {
    final dbClient = await getdb();
    final int categoryId = data[CATEGORY_ID];
    return await dbClient!.update(CATEGORIES_TABLE, data, where: '$CATEGORY_ID = ?', whereArgs: [categoryId]);
  }

  static Future<int> deleteCategory(int id) async {
    final dbClient = await getdb();
    return await dbClient!.delete(CATEGORIES_TABLE, where: '$CATEGORY_ID = ?', whereArgs: [id]);
  }
  
  // Opérations CRUD pour la table des devises (Devises)
  static Future<int> insertDevise(Map<String, dynamic> data) async {
    final dbClient = await getdb();
    return await dbClient!.insert(DEVISE_TABLE, data);
  }

  static Future<List<Devise>> getDevises() async {
    final dbClient = await getdb();
    final List<Map<String, dynamic>> maps = await dbClient!.query(DEVISE_TABLE);
    return List.generate(maps.length, (i) {
      return Devise.fromMap(maps[i]);
    });
  }

  static Future<int> updateDevise(Map<String, dynamic> data) async {
    final dbClient = await getdb();
    final int deviseId = data[DEVISE_ID];
    return await dbClient!.update(DEVISE_TABLE, data, where: '$DEVISE_ID = ?', whereArgs: [deviseId]);
  }

  static Future<int> deleteDevise(int id) async {
    final dbClient = await getdb();
    return await dbClient!.delete(DEVISE_TABLE, where: '$DEVISE_ID = ?', whereArgs: [id]);
  }

  // Opérations CRUD pour la table des utilisateurs (Users)
  static Future<User?> getFirstUser() async {
    final dbClient = await getdb();
    final List<Map<String, dynamic>> maps = await dbClient!.query(USERS_TABLE, limit: 1);
    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    } else {
      return null;
    }
  }

  static Future<int> updateUser(Map<String, dynamic> data) async {
    final dbClient = await getdb();
    final int userId = data[USER_ID];
    return await dbClient!.update(USERS_TABLE, data, where: '$USER_ID = ?', whereArgs: [userId]);
  }

  static Future<bool> updateUserPin(String oldPin, String newPin) async {
    final dbClient = await getdb();
    final List<Map<String, dynamic>> users = await dbClient!.query(USERS_TABLE, where: '$USER_PIN = ?', whereArgs: [oldPin], limit: 1);
    if (users.isNotEmpty) {
      final user = users.first;
      final data = {USER_PIN: newPin, USER_UPDATED_AT: DateTime.now().toIso8601String()};
      await dbClient.update(USERS_TABLE, data, where: '$USER_ID = ?', whereArgs: [user[USER_ID]]);
      return true;
    } else {
      return false;
    }
  }

  // Opérations CRUD pour la table de configuration (Config)
  static Future<Config?> getFirstConfig() async {
    final dbClient = await getdb();
    final List<Map<String, dynamic>> maps = await dbClient!.query(CONFIG_TABLE, limit: 1);
    if (maps.isNotEmpty) {
      return Config.fromMap(maps.first);
    } else {
      return null;
    }
  }

  static Future<int> updateConfig(Map<String, dynamic> data) async {
    final dbClient = await getdb();
    final int configId = data[CONFIG_ID];
    return await dbClient!.update(CONFIG_TABLE, data, where: '$CONFIG_ID = ?', whereArgs: [configId]);
  }

  // Opérations CRUD pour la table des transactions (Transactions)
  static Future<int> insertTransaction(Map<String, dynamic> data) async {
    final dbClient = await getdb();
    data[TRANSACTION_CREATED_AT] = DateTime.now().toIso8601String();
    return await dbClient!.insert(TRANSACTION_TABLE, data);
  }

  static Future<List<Map<String, dynamic>>> getTransactionsWithDetails() async {
    final dbClient = await getdb();
    final String query = '''
      SELECT 
        t.*,
        a.$ACCOUNT_NAME,
        a.$ACCOUNT_ICON,
        c.$CATEGORY_NAME,
        c.$CATEGORY_ICON,
        c.$CATEGORY_COLOR
      FROM $TRANSACTION_TABLE t
      LEFT JOIN $ACCOUNTS_TABLE a ON t.$ACCOUNT_ID = a.$ACCOUNT_ID
      LEFT JOIN $CATEGORIES_TABLE c ON t.$CATEGORY_ID = c.$CATEGORY_ID
      ORDER BY t.$TRANSACTION_DATE DESC
    ''';
    return await dbClient!.rawQuery(query);
  }
  
  static Future<List<Map<String, dynamic>>> getTransactionsForAccount(int accountId) async {
    final dbClient = await getdb();
    final String query = '''
      SELECT 
        t.*,
        a.$ACCOUNT_NAME,
        c.$CATEGORY_NAME,
        c.$CATEGORY_ICON,
        c.$CATEGORY_COLOR
      FROM $TRANSACTION_TABLE t
      LEFT JOIN $ACCOUNTS_TABLE a ON t.$ACCOUNT_ID = a.$ACCOUNT_ID
      LEFT JOIN $CATEGORIES_TABLE c ON t.$CATEGORY_ID = c.$CATEGORY_ID
      WHERE t.$ACCOUNT_ID = ?
      ORDER BY t.$TRANSACTION_DATE DESC
    ''';
    return await dbClient!.rawQuery(query, [accountId]);
  }

  static Future<int> updateTransaction(Map<String, dynamic> data) async {
    final dbClient = await getdb();
    final int transactionId = data[TRANSACTION_ID];
    data[TRANSACTION_UPDATED_AT] = DateTime.now().toIso8601String();
    return await dbClient!.update(TRANSACTION_TABLE, data, where: '$TRANSACTION_ID = ?', whereArgs: [transactionId]);
  }

  static Future<int> deleteTransaction(int id) async {
    final dbClient = await getdb();
    return await dbClient!.delete(TRANSACTION_TABLE, where: '$TRANSACTION_ID = ?', whereArgs: [id]);
  }

  // Opérations CRUD pour la table des budgets (Budgets)
  static Future<int> insertBudget(Map<String, dynamic> data) async {
    final dbClient = await getdb();
    data[BUDGET_CREATED_AT] = DateTime.now().toIso8601String();
    return await dbClient!.insert(BUDGET_TABLE, data);
  }

  static Future<List<Map<String, dynamic>>> getBudgetsWithDetails() async {
    final dbClient = await getdb();
    final String query = '''
      SELECT
        b.*,
        c.$CATEGORY_NAME,
        c.$CATEGORY_ICON,
        c.$CATEGORY_COLOR,
        (SELECT SUM(t.$MONTANT)
         FROM $TRANSACTION_TABLE t
         WHERE t.$CATEGORY_ID = b.$CATEGORY_ID
           AND t.$TRANSACTION_TYPE = 'expense'
           AND t.$TRANSACTION_DATE BETWEEN b.$BUDGET_START_DATE AND b.$BUDGET_END_DATE
        ) as spent_amount
      FROM $BUDGET_TABLE b
      LEFT JOIN $CATEGORIES_TABLE c ON b.$CATEGORY_ID = c.$CATEGORY_ID
      ORDER BY b.$BUDGET_ID DESC
    ''';
    return await dbClient!.rawQuery(query);
  }

  static Future<int> updateBudget(Map<String, dynamic> data) async {
    final dbClient = await getdb();
    data[BUDGET_UPDATED_AT] = DateTime.now().toIso8601String();
    final int budgetId = data[BUDGET_ID];
    return await dbClient!.update(BUDGET_TABLE, data, where: '$BUDGET_ID = ?', whereArgs: [budgetId]);
  }

  static Future<int> deleteBudget(int id) async {
    final dbClient = await getdb();
    return await dbClient!.delete(BUDGET_TABLE, where: '$BUDGET_ID = ?', whereArgs: [id]);
  }

  // Récupère les transactions avec détails dans une plage de dates
  static Future<List<Map<String, dynamic>>> getTransactionsWithDetailsInRange(String startDate, String endDate) async {
    final dbClient = await getdb();
    final String query = '''
      SELECT 
        t.*,
        a.$ACCOUNT_NAME,
        a.$ACCOUNT_ICON,
        c.$CATEGORY_NAME as category_name,
        c.$CATEGORY_ICON as category_icon,
        c.$CATEGORY_COLOR as category_color
      FROM $TRANSACTION_TABLE t
      LEFT JOIN $ACCOUNTS_TABLE a ON t.$ACCOUNT_ID = a.$ACCOUNT_ID
      LEFT JOIN $CATEGORIES_TABLE c ON t.$CATEGORY_ID = c.$CATEGORY_ID
      WHERE t.$TRANSACTION_DATE BETWEEN ? AND ?
      ORDER BY t.$TRANSACTION_DATE DESC
    ''';
    return await dbClient!.rawQuery(query, [startDate, endDate]);
  }
}
