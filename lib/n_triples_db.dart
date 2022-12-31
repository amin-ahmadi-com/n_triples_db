library n_triples_db;

import 'package:flutter/foundation.dart';
import 'package:n_triples_parser/n_triples_types.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:tuple/tuple.dart';

class NTriplesDb {
  late Database _db;

  NTriplesDb(Database db) {
    _db = db;
    _initializeDb();
  }

  _initializeDb() {
    _db.execute(
      "CREATE TABLE IF NOT EXISTS terms"
      "("
      "hash TEXT NOT NULL PRIMARY KEY,"
      "termType TEXT NOT NULL,"
      "value TEXT NOT NULL,"
      "languageTag TEXT NOT NULL,"
      "dataType TEXT NOT NULL"
      ")",
    );

    _db.execute(
      "CREATE INDEX IF NOT EXISTS terms_idx_hash "
      "ON terms "
      "(hash)",
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

    _db.execute(
      "CREATE INDEX IF NOT EXISTS graph_idx_all "
      "ON graph "
      "(subject, predicate, object)",
    );
  }

  String insertOrReplaceNTripleTerm(NTripleTerm term) {
    // calculate once
    final hash = term.hashDigest;

    final statement = _db.prepare(
      "INSERT OR REPLACE INTO terms "
      "(hash, termType, value, languageTag, dataType) "
      "VALUES "
      "(?,?,?,?,?)",
    );

    statement.execute([
      hash,
      describeEnum(term.termType!),
      term.value,
      term.languageTag,
      term.dataType,
    ]);

    return hash;
  }

  NTripleTerm? selectNTripleTerm(String hash) {
    final statement = _db.prepare(
      "SELECT * FROM terms "
      "WHERE hash = ?",
    );

    final results = statement.select([hash]);

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

  bool termExists(NTripleTerm term) =>
      selectNTripleTerm(term.hashDigest) != null;

  void insertNTriple(NTriple nt) {
    final subject = insertOrReplaceNTripleTerm(nt.item1);
    final predicate = insertOrReplaceNTripleTerm(nt.item2);
    final object = insertOrReplaceNTripleTerm(nt.item3);

    final statement = _db.prepare(
      "INSERT OR REPLACE INTO graph "
      "(subject, predicate, object) "
      "VALUES "
      "(?,?,?)",
    );

    statement.execute([subject, predicate, object]);
  }

  Iterable<NTriple> selectNTriples({
    NTripleTerm? subject,
    NTripleTerm? predicate,
    NTripleTerm? object,
  }) {
    return selectNTriplesByHash(
      subject: subject?.hashDigest,
      predicate: predicate?.hashDigest,
      object: object?.hashDigest,
    );
  }

  Iterable<NTriple> selectNTriplesByHash({
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
      "SELECT * FROM graph ${where.isNotEmpty ? "WHERE ${where.join(" AND ")}" : ""}",
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
}
