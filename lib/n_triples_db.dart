library n_triples_db;

import 'package:flutter/foundation.dart';
import 'package:n_triples_parser/n_triple_types.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:tuple/tuple.dart';
import 'package:uuid/uuid.dart';

class NTriplesDb {
  late Database _db;
  final _uuid = const Uuid();

  NTriplesDb(Database db) {
    _db = db;
    _initializeDb();
  }

  _initializeDb() {
    _db.execute(
      "CREATE TABLE IF NOT EXISTS terms"
      "("
      "uuid TEXT NOT NULL PRIMARY KEY,"
      "termType TEXT NOT NULL,"
      "value TEXT NOT NULL,"
      "languageTag TEXT NOT NULL,"
      "dataType TEXT NOT NULL"
      ")",
    );

    _db.execute(
      "CREATE INDEX IF NOT EXISTS terms_idx_uuid "
      "ON terms "
      "(uuid)",
    );

    _db.execute(
      "CREATE INDEX IF NOT EXISTS terms_idx_value "
      "ON terms "
      "(value)",
    );

    _db.execute(
      "CREATE INDEX IF NOT EXISTS terms_idx_all_but_uuid "
      "ON terms "
      "(termType, value, languageTag, dataType)",
    );

    _db.execute(
      "CREATE TABLE IF NOT EXISTS graph"
      "("
      "subject TEXT NOT NULL,"
      "predicate TEXT NOT NULL,"
      "object TEXT NOT NULL,"
      "PRIMARY KEY (subject, predicate, object)"
      ")",
    );

    _db.execute(
      "CREATE INDEX IF NOT EXISTS graph_idx "
      "ON graph "
      "(subject, predicate, object)",
    );

    _db.execute(
      "CREATE INDEX IF NOT EXISTS graph_idx_subject "
      "ON graph "
      "(subject)",
    );

    _db.execute(
      "CREATE INDEX IF NOT EXISTS graph_idx_predicate "
      "ON graph "
      "(predicate)",
    );

    _db.execute(
      "CREATE INDEX IF NOT EXISTS graph_idx_object "
      "ON graph "
      "(object)",
    );
  }

  String insertNTripleTerm(NTripleTerm term) {
    final result = _uuid.v4();
    final statement = _db.prepare(
      "INSERT INTO terms "
      "(uuid, termType, value, languageTag, dataType) "
      "VALUES "
      "(?,?,?,?,?)",
    );

    statement.execute([
      result,
      describeEnum(term.termType!),
      term.value,
      term.languageTag,
      term.dataType,
    ]);

    return result;
  }

  NTripleTerm? selectNTripleTerm(String uuid) {
    final statement = _db.prepare(
      "SELECT * FROM terms "
      "WHERE uuid = ?",
    );

    final results = statement.select([uuid]);

    if (results.isNotEmpty) {
      final row = results.first;
      final result = NTripleTerm();
      switch (row["termType"]) {
        case 'iri':
          result.termType = NTripleTermType.iri;
          break;
        case 'literal':
          result.termType = NTripleTermType.literal;
          break;
        case 'blankNode':
          result.termType = NTripleTermType.blankNode;
          break;
      }

      result.value = row["value"];
      result.languageTag = row["languageTag"];
      result.dataType = row["dataType"];
      return result;
    } else {
      return null;
    }
  }

  String? selectUuid(NTripleTerm term) {
    final statement = _db.prepare(
      "SELECT uuid FROM terms "
      "WHERE termType = ? AND value = ? AND languageTag = ? AND dataType = ?",
    );

    final results = statement.select([
      describeEnum(term.termType!),
      term.value,
      term.languageTag,
      term.dataType,
    ]);

    if (results.isNotEmpty) {
      return results.first["uuid"];
    } else {
      return null;
    }
  }

  bool termExists(NTripleTerm term) => selectUuid(term) != null;

  void insertNTriple(NTriple nt) {
    String? subject = selectUuid(nt.item1);
    subject ??= insertNTripleTerm(nt.item1);

    String? predicate = selectUuid(nt.item2);
    predicate ??= insertNTripleTerm(nt.item2);

    String? object = selectUuid(nt.item3);
    object ??= insertNTripleTerm(nt.item3);

    final statement = _db.prepare(
      "INSERT OR REPLACE INTO graph "
      "(subject, predicate, object) "
      "VALUES "
      "(?,?,?)",
    );

    statement.execute([subject, predicate, object]);
  }

  Iterable<NTriple> selectNTriples({
    String? subject,
    String? predicate,
    String? object,
  }) {
    var where = <String>[];
    var params = <String>[];
    if (subject != null) {
      where.add("subject = ?");
      params.add(subject);
    }
    if (predicate != null) {
      where.add("predicate = ?");
      params.add(predicate);
    }
    if (object != null) {
      where.add("object = ?");
      params.add(object);
    }
    final statement = _db.prepare(
      "SELECT * FROM graph "
      "${where.isNotEmpty ? "WHERE ${where.join(" AND ")}" : ""}",
    );

    final results = statement.select(params);
    return results.map<NTriple>((row) {
      return Tuple3(
        selectNTripleTerm(row["subject"])!,
        selectNTripleTerm(row["predicate"])!,
        selectNTripleTerm(row["object"])!,
      );
    });
  }

  Iterable<Tuple2<String, NTripleTerm>> searchTermsByValue(
    String value, {
    int limit = 0,
    int offset = 0,
  }) {
    if (value.trim().isEmpty) return [];

    final statement = _db.prepare(
      "SELECT * FROM terms "
      "WHERE LIKE('%$value%', value) "
      "ORDER BY value ASC "
      "${limit != 0 ? "LIMIT $limit OFFSET $offset" : ""} ",
    );

    final results = statement.select();

    return results.map<Tuple2<String, NTripleTerm>>((row) {
      NTripleTermType termType;
      switch (row["termType"]) {
        case "iri":
          termType = NTripleTermType.iri;
          break;

        case "literal":
          termType = NTripleTermType.literal;
          break;

        case "blankNode":
          termType = NTripleTermType.blankNode;
          break;

        default:
          throw "Incomprehensible term type `${row["termType"]}`";
      }

      return Tuple2(
        row["uuid"],
        NTripleTerm(
          termType: termType,
          value: row["value"],
          dataType: row["dataType"],
          languageTag: row["languageTag"],
        ),
      );
    });
  }

  Iterable<Tuple2<String, String>> getPredicatesAndObjects(
    String subjectUuid,
  ) {
    final statement = _db.prepare("SELECT * FROM graph WHERE subject = ?");
    final results = statement.select([subjectUuid]);

    return results.map<Tuple2<String, String>>((row) {
      return Tuple2(
        row["predicate"]!,
        row["object"]!,
      );
    });
  }

  Iterable<Tuple2<String, String>> getSubjectsAndPredicates(
    String objectUuid,
  ) {
    final statement = _db.prepare("SELECT * FROM graph WHERE object = ?");
    final results = statement.select([objectUuid]);

    return results.map<Tuple2<String, String>>((row) {
      return Tuple2(
        row["subject"]!,
        row["predicate"]!,
      );
    });
  }
}
