import 'dart:io'; //on utilise le fichier
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
  static const String ANN_MOIS_COTISATION = 'ann_mois_cotisation';
  static const String DATE = 'date';
  static const String TYPE = 'type';

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
          await db.execute("CREATE TABLE $TRANSACTION_TABLE($TRANSACTION_ID INTEGER PRIMARY KEY AUTOINCREMENT,$MONTANT TEXT,$ANN_MOIS_COTISATION TEXT,$DATE TEXT,$TYPE TEXT)");
          await db.execute("CREATE TABLE $DEVISE_TABLE($DEVISE_ID INTEGER PRIMARY KEY AUTOINCREMENT,$DEVISE_LIB TEXT,$DEVISE_VAL TEXT,$DEVISE_SYMBOLE TEXT)");
          await db.execute("CREATE TABLE $USERS_TABLE($USER_ID INTEGER PRIMARY KEY AUTOINCREMENT,$USER_NAME TEXT,$USER_EMAIL TEXT,$USER_PASSWORD TEXT,$USER_PIN INTEGER,$USER_PHONE TEXT,$USER_ROLE TEXT,$USER_STATUS INTEGER,$USER_CREATED_AT TEXT,$USER_UPDATED_AT TEXT,$ACEPT_LICENCE INTEGER)");
          await db.execute("CREATE TABLE $CONFIG_TABLE($CONFIG_ID INTEGER PRIMARY KEY AUTOINCREMENT,$APP_NAME TEXT,$DEFAULT_LANGUAGE TEXT,$DEFAULT_YEAR INTEGER,$SELECTED_DEVISE_ID TEXT)");
          await db.execute("CREATE TABLE $TABLE_NOTIFICATIONS($NOTIFICATION_ID INTEGER PRIMARY KEY AUTOINCREMENT,$NOTIFICATION_TITRE TEXT,$NOTIFICATION_CONTENU TEXT,$NOTIFICATION_DATE TEXT)");
        });
  }

// Renamed from insertDefaultConfig and signature updated
  static Future<int> addConfig(String app_name, String default_language, int default_year, String selected_devise_id) async {
    final dbClient = await getdb();
    final data = {
      APP_NAME: app_name,
      DEFAULT_LANGUAGE: default_language,
      DEFAULT_YEAR: default_year,
      SELECTED_DEVISE_ID: selected_devise_id,
    };
    return await dbClient!.insert(CONFIG_TABLE, data);
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


  }
