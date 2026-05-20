import 'package:epmsa_mobile/core/models/user.dart';
import 'package:epmsa_mobile/features/penalties/domain/penalty.dart';
import 'package:epmsa_mobile/features/penalties/domain/penalty_catalog.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class SqliteHandler {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await initDB(); // Inicializar la base si no existe
    return _database!;
  }

  Future<Database> initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'epmsa.db');
    // await deleteDatabase(path); 

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // tablas para offline de arribos - inspecciones
        await db.execute('''
        CREATE TABLE arrivals (
          id_arrivals INTEGER PRIMARY KEY,
          json_all TEXT
        )
      ''');

        await db.execute('''
        CREATE TABLE inspecciones_activas (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            id_inspeccion INTEGER NOT NULL
        )
      ''');
        //tablas del modulo de auditoria
        await db.execute('''
        CREATE TABLE auditoria_inspecciones (
          id_inspeccion INTEGER PRIMARY KEY,
          json_inspeccion TEXT,
          json_photos TEXT
        )
      ''');

        await db.execute('''
        CREATE TABLE auditoria_prueba (
          id_prueba INTEGER PRIMARY KEY,
          json_prueba TEXT,
          json_photos TEXT
        )
      ''');
        // fin tablas del modulo de auditoria
        await db.execute('''
          CREATE TABLE epmsatca_penaltiescatalog (
            id TEXT PRIMARY KEY,
            server_id INTEGER UNIQUE,
            parent_id INTEGER,         
            name TEXT,
            active INTEGER
          )
        ''');
        await db.execute('''
        CREATE TABLE epmsatca_penalties (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT , -- Número de Acta
          partner_id INTEGER , -- ID del Infractor
          parent_id INTEGER , -- Relación con `epmsatca_penaltiescatalog`
          penalty_id INTEGER , -- Falta Cometida
          date TEXT , -- Fecha de Infracción
          amount REAL, -- Monto de Multa
          status TEXT CHECK( status IN ('pending', 'paid') ) DEFAULT 'pending', -- Estado de la Multa
          observations TEXT, -- Observaciones
          synced INTEGER DEFAULT 0, -- 0 = No sincronizado, 1 = Sincronizado con Odoo
          FOREIGN KEY (parent_id) REFERENCES epmsatca_penaltiescatalog(id),
          FOREIGN KEY (penalty_id) REFERENCES epmsatca_penaltiescatalog(id)
        )
      ''');
        await db.execute('''
          CREATE TABLE epmsatca_users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT , -- Número de Acta
            active INTEGER
          )
        ''');
        await db.execute('''
          CREATE TABLE epmsatca_inspections (
              id INTEGER PRIMARY KEY,              -- ID único de la inspección asignada
              type TEXT ,               -- Tipo de inspección (e.g. NationalArrivals, Cargo, Departures)
              assigned_user TEXT ,        -- Fecha y hora asignada (ISO 8601)
              status TEXT ,             -- Estado: Asignada, En progreso, Finalizada
              started_at TEXT,                  -- Hora en la que se inició (nullable)
              synced INTEGER DEFAULT 0          -- 0 = No sincronizado, 1 = Ya sincronizado
          );

        ''');
        await db.execute('''
          CREATE TABLE epmsatca_national_arrivals (
            id INTEGER PRIMARY KEY AUTOINCREMENT,

            inspection_id INTEGER, -- Foreign key to epmsatca_inspections
            -- General Data
            general_data_measurement_date TEXT ,
            general_data_peak_hour TEXT,            
            general_data_hour TEXT,
            general_data_flight_count INTEGER  DEFAULT 0,
            general_data_prepared_by_id INTEGER,
            general_data_prepared_by TEXT ,
            general_data_reviewed_by_id INTEGER,
            general_data_reviewed_by TEXT,

            -- Public Hall
            public_hall_time TEXT,
            public_hall_pax_waiting_area INTEGER,
            public_hall_nds_area TEXT,
            public_hall_nds_time TEXT,
            --public_hall_photo TEXT,

            -- Baggage Claim - Area (9th Ed.)
            baggage_claim_belts TEXT,
            notes_belts TEXT,
            baggage_claim_time_1 TEXT,
            baggage_claim_pax_waiting_area_1 INTEGER,
            baggage_claim_time_2 TEXT,
            baggage_claim_pax_waiting_area_2 INTEGER,            
            baggage_claim_time_3 TEXT,
            baggage_claim_pax_waiting_area_3 INTEGER,
            baggage_claim_area_function TEXT,

            -- Observations and Events
            observations_event_time TEXT,
            observations_location TEXT,
            observations_description TEXT,
            observations_consequence TEXT,
            --observations_photo TEXT,

            -- Sync & Control
            synced INTEGER DEFAULT 0, -- 0 = Not synced, 1 = Synced with Odoo
            FOREIGN KEY (inspection_id) REFERENCES epmsatca_inspections(id)
          );
        ''');

        await db.execute('''
          CREATE TABLE arrival_baggage_time_details (
            id INTEGER PRIMARY KEY,
            national_arrival_id INTEGER, -- FK hacia epmsatca_national_arrivals(id)
            international_arrival_id INTEGER,
            flight_number INTEGER,
            origin TEXT,
            scheduled_time_a_hhmm TEXT,
            arrival_time_b_hhmm TEXT,
            --diff_ba TEXT,
            assigned_belt TEXT,
            first_pax_arrival_c_hhmm TEXT,
            first_bag_arrival_d_hhmm TEXT,
            last_bag_arrival_e_hhmm TEXT,
            --diff_dc TEXT,
            --diff_ed TEXT,
            --nds_time_function TEXT,

            synced INTEGER DEFAULT 0, -- 0 = no sincronizado, 1 = sincronizado
            FOREIGN KEY (national_arrival_id) REFERENCES epmsatca_national_arrivals(id)
            FOREIGN KEY (international_arrival_id) REFERENCES epmsatca_international_arrivals(id)
         );
        ''');

        await db.execute('''
          CREATE TABLE epmsatca_international_arrivals (
            id INTEGER PRIMARY KEY AUTOINCREMENT,

            inspection_id INTEGER, -- Foreign key to epmsatca_inspections
            -- General Data
            general_data_measurement_date TEXT ,
            general_data_peak_hour TEXT,
            general_data_hour TEXT,
            general_data_flight_count INTEGER  DEFAULT 0,
            general_data_prepared_by_id INTEGER,
            general_data_prepared_by TEXT ,
            general_data_reviewed_by_id INTEGER,
            general_data_reviewed_by TEXT,

            -- Public Hall
            public_hall_time TEXT,
            public_hall_pax_waiting_area INTEGER,
            public_hall_nds_area TEXT,
            public_hall_nds_time TEXT,
            --public_hall_photo TEXT,

            -- Baggage Claim - Area (9th Ed.)
            baggage_claim_belts TEXT,
            notes_belts TEXT,
            baggage_claim_time_1 TEXT,
            baggage_claim_pax_waiting_area_1 INTEGER, 
            baggage_claim_time_2 TEXT,
            baggage_claim_pax_waiting_area_2 INTEGER,            
            baggage_claim_time_3 TEXT,
            baggage_claim_pax_waiting_area_3 INTEGER,
            baggage_claim_area_function TEXT,

            migration_id INTEGER,
            migration_area_time TEXT ,
            migration_area_national_working_counters INTEGER,
            migration_area_national_pax_waiting_area INTEGER,
            migration_area_national_occupancy REAL,
            migration_area_national_offline_time TEXT,
            
            migration_area_international_working_counters INTEGER,
            migration_area_international_pax_waiting_area INTEGER,
            migration_area_international_occupancy REAL,
            migration_area_international_offline_time TEXT,
            
            migration_time_national_attention_time_per_pax_1 TEXT,
            migration_time_national_attention_time_per_pax_2 TEXT,
            migration_time_national_attention_time_per_pax_3 TEXT,
            migration_time_national_attention_time_per_pax_max TEXT,
            migration_time_national_average TEXT,

            migration_time_international_pax_waiting_time_1 TEXT,
            migration_time_international_pax_waiting_time_2 TEXT,
            migration_time_international_pax_waiting_time_3 TEXT,
            migration_time_international_pax_waiting_time_max TEXT,
            migration_time_international_average TEXT,

            migration_total_counters_attending INTEGER,
            migration_total_pax_waiting_area INTEGER,
            migration_max_waiting_time TEXT,
            migration_nds_area TEXT,
            migration_nds_time TEXT,
            
            customs_time TEXT,
            customs_maq_rx_oper INTEGER,
            customs_kiosko_pass INTEGER,
            customs_pax_waiting_area INTEGER,
            customs_area_occupancy REAL,
            customs_offline_time TEXT,
            customs_waiting_time_max TEXT,
            customs_nds_area TEXT,
            customs_nds_time TEXT,

            -- Observations and Events
            observations_event_time TEXT,
            observations_location TEXT,
            observations_description TEXT,
            observations_consequence TEXT,
            --observations_photo TEXT,

            -- Sync & Control
            synced INTEGER DEFAULT 0, -- 0 = Not synced, 1 = Synced with Odoo
            FOREIGN KEY (inspection_id) REFERENCES epmsatca_inspections(id)
          );
        ''');

        await db.execute('''
          CREATE TABLE epmsatca_inspection_photos (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            inspection_id INTEGER ,   -- ID de la inspección relacionada
            section TEXT ,            -- Sección a la que pertenece la foto (public_hall, observations, etc.)
            path TEXT ,               -- Ruta local de la imagen
            caption TEXT ,            -- Comentario adicional
            timestamp TEXT ,          -- Fecha y hora en que se tomó la foto (ISO 8601)
            synced INTEGER DEFAULT 0,         -- 0 = No sincronizado, 1 = Sincronizado con Odoo
            FOREIGN KEY (inspection_id) REFERENCES epmsatca_inspections(id) ON DELETE CASCADE
          )
        ''');
        await db.execute('''
          CREATE TABLE epmsatca_international_departures (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            inspection_id INTEGER ,

            -- Datos Generales
            
            general_data_measurement_date TEXT ,            
            general_data_peak_hour TEXT,
            general_data_hour TEXT,
            general_data_flight_count INTEGER  DEFAULT 0,
            general_data_prepared_by_id INTEGER,
            general_data_prepared_by TEXT ,
            general_data_reviewed_by_id INTEGER,
            general_data_reviewed_by TEXT,

            -- Datos vuelo
            flight_count INTEGER ,
            flight_pax_number INTEGER ,
            flight_number TEXT ,
            flight_destiny TEXT ,
            flight_check_counter_number INTEGER ,
            flight_preboarding_room TEXT ,
            flight_scheduled_time TEXT ,
            flight_actual_departure_time TEXT ,
            --flight_counter_id     INTEGER,              -- FK al catálogo

            -- Hall Público
            public_hall_time TEXT,
            public_hall_pax_waiting_area INTEGER,
            public_hall_nds_area TEXT,
            public_hall_nds_time TEXT,

            -- Quioscos de Autochequeo
            self_checkin_kiosks_time TEXT ,
            self_checkin_kiosks_service_time_per_pax_1 TEXT ,
            self_checkin_kiosks_service_time_per_pax_2 TEXT ,
            self_checkin_kiosks_average TEXT ,
            self_checkin_kiosks_maximum_waiting_time TEXT ,
            self_checkin_kiosks_nds_time_function TEXT ,

            -- Check-in Counter
            --Area
            checkin_counter_time TEXT ,
            --checkin_counter_assigned_counters_zone TEXT ,
            checkin_counter_assigned_counters INTEGER ,
            checkin_counter_operating_counters INTEGER ,
            checkin_counter_pax_waiting_area INTEGER ,
            checkin_counter_waiting_area_occupancy_percentage REAL,
            checkin_counter_offline_time TEXT ,
            checkin_counter_nds_area_function TEXT,
            --Time
            checkin_counter_attention_time_per_pax_1 TEXT ,
            checkin_counter_attention_time_per_pax_2 TEXT ,
            checkin_counter_attention_time_per_pax_3 TEXT ,
            checkin_counter_attention_time_per_pax_4 TEXT ,
            checkin_counter_attention_time_per_pax_5 TEXT ,
            checkin_counter_attention_time_average TEXT ,
            checkin_counter_attention_time_per_pax_max TEXT ,
            checkin_counter_nds_time_area_function TEXT ,
--
            -- Filtros Seguridad 
            --Area
            security_filters_time TEXT ,
            security_filters_observed_domestic_operators INTEGER ,
            security_filters_observed_international_operators INTEGER ,
            security_filters_observed_document_review_agents INTEGER ,
            security_filters_pax_waiting_area INTEGER ,
            security_filters_waiting_area_occupancy REAL,
            security_filters_offline_time TEXT ,
            security_filters_nds_area TEXT ,

            --Time
            security_filters_attention_time_per_pax_1 TEXT ,
            security_filters_attention_time_per_pax_2 TEXT ,
            security_filters_attention_time_per_pax_3 TEXT ,
            security_filters_attention_time_per_pax_4 TEXT ,
            security_filters_attention_time_per_pax_5 TEXT ,
            security_filters_waiting_time_average TEXT ,
            security_filters_nds_time_function TEXT ,

            -- Migración
            --Area
            migration_id INTEGER,
            migration_area_time TEXT ,

            --national
            migration_area_national_working_counters INTEGER ,
            migration_area_national_pax_waiting_area INTEGER ,
            migration_area_national_waiting_area_occupancy REAL,
            migration_area_national_offline_time TEXT ,
            migration_area_national_occupancy REAL,

            --international
            migration_area_international_working_counters INTEGER ,
            migration_area_international_pax_waiting_area INTEGER ,
            migration_area_international_waiting_area_occupancy REAL,
            migration_area_international_offline_time TEXT ,
            migration_area_international_occupancy REAL,

            migration_area_total_working_counters INTEGER ,
            migration_area_total_pax_waiting_area INTEGER ,
            migration_area_waiting_area_occupancy_standard TEXT ,

            migration_time_nds_function_area TEXT ,

            migration_total_counters_attending INTEGER,
            migration_total_pax_waiting_area INTEGER,
            migration_max_waiting_time TEXT,
            migration_nds_area TEXT,
            migration_nds_time TEXT,

            --Tiempo
            --national
            
            migration_time_national_attention_time_per_pax_1 TEXT,
            migration_time_national_attention_time_per_pax_2 TEXT,
            migration_time_national_attention_time_per_pax_3 TEXT,
            migration_time_national_attention_time_per_pax_max TEXT,
            migration_time_national_max_waiting_time TEXT ,
            migration_time_national_nds_function_time TEXT ,
            migration_time_national_average TEXT,

            --international 
            migration_time_international_pax_waiting_time_1 TEXT,
            migration_time_international_pax_waiting_time_2 TEXT,
            migration_time_international_pax_waiting_time_3 TEXT,
            migration_time_international_pax_waiting_time_max TEXT,
            migration_time_international_average TEXT,
            migration_time_international_nds_function_time TEXT ,

            -- Pre-embarque
            --Area
            preboarding_rooms_area_time REAL ,
            preboarding_rooms_area_occupancy REAL ,
            preboarding_rooms_area_pax_number INTEGER ,
            preboarding_rooms_area_area_function_a_rooms TEXT ,
            preboarding_rooms_area_occupancy_pax_other_rooms TEXT ,
            preboarding_rooms_area_area_function_b_d_rooms TEXT ,

            --Time
            preboarding_rooms_time_total_occupancy REAL ,
            preboarding_rooms_time_occupancy_function TEXT ,

            -- Observations and Events
            observations_event_time TEXT,
            observations_location TEXT,
            observations_description TEXT,
            observations_consequence TEXT,
            --observations_photo TEXT,
            
            synced INTEGER DEFAULT 0, -- 0 = Not synced, 1 = Synced with Odoo
            FOREIGN KEY (inspection_id) REFERENCES epmsatca_inspections(id) ON DELETE CASCADE          
            --FOREIGN KEY (flight_counter_id) REFERENCES flight_check_counter_catalog(id)
          );
        ''');

        await db.execute('''
          CREATE TABLE epmsatca_national_departures (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            inspection_id INTEGER ,

            -- Datos Generales
            
            general_data_measurement_date TEXT ,            
            general_data_peak_hour TEXT,
            general_data_hour TEXT,
            general_data_flight_count INTEGER  DEFAULT 0,
            general_data_prepared_by_id INTEGER,
            general_data_prepared_by TEXT ,
            general_data_reviewed_by_id INTEGER,
            general_data_reviewed_by TEXT,

            -- Datos vuelo
            flight_count INTEGER ,
            flight_pax_number INTEGER ,
            flight_number TEXT ,
            flight_destiny TEXT ,
            flight_check_counter_number INTEGER ,
            flight_preboarding_room TEXT ,
            flight_scheduled_time TEXT ,
            flight_actual_departure_time TEXT , 

            -- Hall Público
            public_hall_time TEXT,
            public_hall_pax_waiting_area INTEGER,
            public_hall_nds_area TEXT,
            public_hall_nds_time TEXT,

            -- Quioscos de Autochequeo
            self_checkin_kiosks_time TEXT ,
            self_checkin_kiosks_service_time_per_pax_1 TEXT ,
            self_checkin_kiosks_service_time_per_pax_2 TEXT ,
            self_checkin_kiosks_average TEXT ,
            self_checkin_kiosks_maximum_waiting_time TEXT ,
            self_checkin_kiosks_nds_time_function TEXT ,

            -- Check-in Counter
            --Area
            checkin_counter_time TEXT ,
            --checkin_counter_assigned_counters_zone TEXT ,
            checkin_counter_assigned_counters INTEGER ,
            checkin_counter_operating_counters INTEGER ,
            checkin_counter_pax_waiting_area INTEGER ,
            checkin_counter_waiting_area_occupancy_percentage REAL,
            checkin_counter_offline_time TEXT ,
            checkin_counter_nds_area_function TEXT,
            --Time
            checkin_counter_attention_time_per_pax_1 TEXT ,
            checkin_counter_attention_time_per_pax_2 TEXT ,
            checkin_counter_attention_time_per_pax_3 TEXT ,
            checkin_counter_attention_time_per_pax_4 TEXT ,
            checkin_counter_attention_time_per_pax_5 TEXT ,
            checkin_counter_attention_time_average TEXT ,
            checkin_counter_attention_time_per_pax_max TEXT ,
            checkin_counter_nds_time_area_function TEXT ,

            -- Filtros Seguridad 
            --Area
            security_filters_time TEXT ,
            security_filters_observed_domestic_operators INTEGER ,
            security_filters_observed_international_operators INTEGER ,
            security_filters_observed_document_review_agents INTEGER ,
            security_filters_pax_waiting_area INTEGER ,
            security_filters_waiting_area_occupancy REAL,
            security_filters_offline_time TEXT ,
            security_filters_nds_area TEXT ,

            --Time
            security_filters_attention_time_per_pax_1 TEXT ,
            security_filters_attention_time_per_pax_2 TEXT ,
            security_filters_attention_time_per_pax_3 TEXT ,
            security_filters_attention_time_per_pax_4 TEXT ,
            security_filters_attention_time_per_pax_5 TEXT ,
            security_filters_waiting_time_average TEXT ,
            security_filters_nds_time_function TEXT ,

            -- Pre-embarque
            --Area
            preboarding_rooms_area_time REAL ,
            preboarding_rooms_area_occupancy REAL ,
            preboarding_rooms_area_pax_number INTEGER ,
            preboarding_rooms_area_area_function_a_rooms TEXT ,
            preboarding_rooms_area_occupancy_pax_other_rooms TEXT ,
            preboarding_rooms_area_area_function_b_d_rooms TEXT ,

            --Time
            preboarding_rooms_time_total_occupancy REAL ,
            preboarding_rooms_time_occupancy_function TEXT ,

            -- Observations and Events
            observations_event_time TEXT,
            observations_location TEXT,
            observations_description TEXT,
            observations_consequence TEXT,
            --observations_photo TEXT,

            synced INTEGER DEFAULT 0, -- 0 = Not synced, 1 = Synced with Odoo
            FOREIGN KEY (inspection_id) REFERENCES epmsatca_inspections(id) ON DELETE CASCADE
          );
        ''');

        await db.execute('''
          CREATE TABLE IF NOT EXISTS departures_preboarding_details (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            national_departure_id INTEGER ,
            international_departure_id INTEGER ,
            area TEXT,
            used INTEGER,
            used_chairs INTEGER,
            available_chairs INTEGER,
            used_area INTEGER,
            available_area INTEGER,
            occupancy_percentage INTEGER,
            
            synced INTEGER DEFAULT 0, -- 0 = Not synced, 1 = Synced with Odoo
            
            FOREIGN KEY (national_departure_id) REFERENCES epmsatca_national_departures(id) ON DELETE CASCADE,
            FOREIGN KEY (international_departure_id) REFERENCES epmsatca_international_departures(id) ON DELETE CASCADE
          );
        ''');

        await db.execute('''
        CREATE TABLE departure_flight_options (
          id            INTEGER PRIMARY KEY,          --id de la API
          international_departure_id  INTEGER,      
          national_departure_id  INTEGER,               
          name          TEXT,
          destiny       TEXT,
          time       TEXT,
          selected      INTEGER DEFAULT 0,
          synced        INTEGER DEFAULT 0,
          CHECK (
              (international_departure_id IS NOT NULL AND national_departure_id IS NULL)
              OR (international_departure_id IS NULL     AND national_departure_id IS NOT NULL)
          ),
          FOREIGN KEY (international_departure_id)
            REFERENCES epmsatca_international_departures(id)
            ON DELETE CASCADE,
          FOREIGN KEY (national_departure_id)
            REFERENCES epmsatca_national_departures(id)
            ON DELETE CASCADE
        );
        ''');
        await db.execute('''
        CREATE TABLE departure_flight_check_counters (
          rowid   INTEGER PRIMARY KEY AUTOINCREMENT,
          id                           INTEGER,   -- id que viene de la API
          international_departure_id  INTEGER,      
          national_departure_id  INTEGER,               
          name                         TEXT,                  -- “A1-A2”, “A3-A4”.
          selected                     INTEGER DEFAULT 0,     -- 0 = false, 1 = true
          synced                       INTEGER DEFAULT 0,     -- 0 = pendiente, 1 = OK

          FOREIGN KEY (international_departure_id)
            REFERENCES epmsatca_international_departures(id)
            ON DELETE CASCADE,
          FOREIGN KEY (national_departure_id)
            REFERENCES epmsatca_national_departures(id)
            ON DELETE CASCADE
        );
      ''');

        await db.execute('''
        CREATE TABLE departure_flight_preboarding_rooms (
          rowid   INTEGER PRIMARY KEY AUTOINCREMENT,
          id                           INTEGER,   -- id que viene de la API
          international_departure_id  INTEGER,      
          national_departure_id  INTEGER,               
          name                         TEXT,                  -- “P1”, “P2”
          selected                     INTEGER DEFAULT 0,     -- 0 = false, 1 = true
          synced                       INTEGER DEFAULT 0,     -- 0 = pendiente, 1 = OK

          FOREIGN KEY (international_departure_id)
            REFERENCES epmsatca_international_departures(id)
            ON DELETE CASCADE,
          FOREIGN KEY (national_departure_id)
            REFERENCES epmsatca_national_departures(id)
            ON DELETE CASCADE
        );
      ''');

        await db.execute('''
        CREATE TABLE departure_checkin_assigned_counters (
          rowid   INTEGER PRIMARY KEY AUTOINCREMENT,
          id                           INTEGER,   -- id que viene de la API
          international_departure_id  INTEGER,      
          national_departure_id  INTEGER,               
          name                         TEXT,                  -- “A1-A2”, “A3-A4”.
          selected                     INTEGER DEFAULT 0,     -- 0 = false, 1 = true
          synced                       INTEGER DEFAULT 0,     -- 0 = pendiente, 1 = OK

          FOREIGN KEY (international_departure_id)
            REFERENCES epmsatca_international_departures(id)
            ON DELETE CASCADE,
          FOREIGN KEY (national_departure_id)
            REFERENCES epmsatca_national_departures(id)
            ON DELETE CASCADE
        );
      ''');

        await db.execute('''
          CREATE TABLE epmsatca_inspection_cargo (
            id INTEGER PRIMARY KEY,
            inspection_id INTEGER,

            -- Datos Generales
            general_data_measurement_date TEXT,
            general_data_prepared_by_id INTEGER,
            general_data_prepared_by TEXT,
            general_data_reviewed_by_id INTEGER,
            general_data_reviewed_by TEXT,
            general_data_peak_hour TEXT,
            general_data_hour TEXT,
            general_data_flight_count INTEGER  DEFAULT 0,

            earthside_national_hour                 TEXT,
            earthside_international_hour            TEXT,
            earthside_international_building_hour   TEXT,
            airside_national_international_hour     TEXT,

            synced INTEGER DEFAULT 0,
            FOREIGN KEY (inspection_id) REFERENCES epmsatca_inspections(id) ON DELETE CASCADE
          );
        ''');

        await db.execute('''
          CREATE TABLE IF NOT EXISTS cargo_landside (
            rowid   INTEGER PRIMARY KEY AUTOINCREMENT,
            id INTEGER, --ID que viene desde la API
            cargo_id INTEGER,
            parent TEXT,
            sequence INTEGER,
            name TEXT,
            qualification TEXT,
            note TEXT,
            max_value REAL,
            control_value REAL,
            percentage REAL,

            synced INTEGER DEFAULT 0,
            FOREIGN KEY (cargo_id) REFERENCES epmsatca_inspection_cargo(id) ON DELETE CASCADE
          );
        ''');

        await db.execute('''
          CREATE TABLE IF NOT EXISTS cargo_airside (
            rowid   INTEGER PRIMARY KEY AUTOINCREMENT,
            id INTEGER, --ID que viene desde la API
            cargo_id INTEGER,
            parent TEXT,
            type TEXT,
            sequence INTEGER,
            name TEXT,
            qualification TEXT,
            note TEXT,
            max_value REAL,
            control_value REAL,
            percentage REAL,

            synced INTEGER DEFAULT 0,
            FOREIGN KEY (cargo_id) REFERENCES epmsatca_inspection_cargo(id) ON DELETE CASCADE
          );
        ''');

        await db.execute('''
        CREATE TABLE inspections_public_halls (
          rowid       INTEGER PRIMARY KEY AUTOINCREMENT, -- PK local
          id       INTEGER,                           -- id que viene de la API
          inspection_id INTEGER NOT NULL,                 -- FK genérica a inspecciones
          name         TEXT,
          selected     INTEGER DEFAULT 0,                 -- 0|1
          synced       INTEGER DEFAULT 0,
          FOREIGN KEY (inspection_id)
            REFERENCES epmsatca_inspections(id)
            ON DELETE CASCADE
        );
        CREATE INDEX idx_inspections_public_halls_inspection
          ON inspections_public_halls(inspection_id);
        ''');
      },
    );
  }

  Future<List<PenaltyCatalog>> getPenaltiesCatalog() async {
    final db =
        await database; // Asegurar que la base de datos está inicializada
    final List<Map<String, dynamic>> maps = await db.query(
        'epmsatca_penaltiescatalog',
        where: 'active = ?',
        whereArgs: [1]);

    return maps.map((penalty) => PenaltyCatalog.fromJson(penalty)).toList();
  }

  Future<void> savePenaltiesCatalog(List<PenaltyCatalog> penalties) async {
    final db = await database;

    for (var penalty in penalties) {
      await db.insert(
        'epmsatca_penaltiescatalog',
        penalty.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace, // Evitar duplicados
      );
    }

    print("✅ Penalizaciones insertadas en SQLite");
  }

  Future<List<Penalty>> getPenalties() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'epmsatca_penalties',
    );

    return maps.map((penalty) => Penalty.fromJson(penalty)).toList();
  }

  Future<List<Penalty>> getPendingPenalties() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'epmsatca_penalties',
      where: 'synced = 0',
    );

    return maps.map((penalty) => Penalty.fromJson(penalty)).toList();
  }

  Future<void> savePenalty(Penalty penalty) async {
    final db = await database;
    await db.insert(
      'epmsatca_penalties',
      penalty.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    print("✅ Multa guardada en SQLite (Pendiente de sincronización).");
  }

  Future<List<User>> getUsers() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('epmsatca_users');

    return maps.map((penalty) => User.fromJson(penalty)).toList();
  }

  Future<void> saveUsers(List<User> users) async {
    final db = await database;
    final batch = db.batch(); // Usamos batch para mayor eficiencia

    for (var user in users) {
      batch.insert(
        'epmsatca_users',
        {'id': user.serverId, 'name': user.name, 'active': 1},
        conflictAlgorithm: ConflictAlgorithm.replace, // Evita duplicados
      );
    }

    await batch.commit();
  }

  Future<int> insertAuditoriaInspeccion({
    required int idInspeccion,
    required String jsonInspeccion,
    required String jsonPhotos,
  }) async {
    final db = await database;

    return await db.insert(
      'auditoria_inspecciones',
      {
        'id_inspeccion': idInspeccion,
        'json_inspeccion': jsonInspeccion,
        'json_photos': jsonPhotos,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> getAuditoriaInspeccionById(int idInspeccion) async {
    final db = await database;

    final result = await db.query(
      'auditoria_inspecciones',
      where: 'id_inspeccion = ?',
      whereArgs: [idInspeccion],
      limit: 1,
    );

    if (result.isNotEmpty) {
      return result.first;
    }
    return null; // No se encontró registro
  }

  Future<Map<String, dynamic>?> getAuditoriaTestById(int idTest) async {
    final db = await database;

    final result = await db.query(
      'auditoria_prueba',
      where: 'id_prueba = ?',
      whereArgs: [idTest],
      limit: 1,
    );

    if (result.isNotEmpty) {
      return result.first;
    }
    return null; // No se encontró registro
  }

  Future<int> insertAuditoriaTest({
    required int idPrueba,
    required String jsonPrueba,
    required String jsonPhotos,
  }) async {
    try {
      final db = await database;

      return await db.insert(
        'auditoria_prueba',
        {
          'id_prueba': idPrueba,
          'json_prueba': jsonPrueba,
          'json_photos': jsonPhotos,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }catch(e){
      print(e);
      return 0;
    }
  }

  Future<void> saveInspeccionActiva(int idInspeccion) async {
    final db = await database;
    try {
      await db.insert(
        'inspecciones_activas',
        {
          'id_inspeccion': idInspeccion,
        },
        conflictAlgorithm:
            ConflictAlgorithm.ignore,
      );
    } catch (e) {
      print(e);
    }
  }

  Future<List<int>> getInspeccionesActivas() async {
    final db = await database;

    final result = await db.query(
      'inspecciones_activas',
      columns: ['id_inspeccion'],
    );
    return result
        .map((row) => row['id_inspeccion'] as int)
        .toList();
  }

}
