import 'package:flutter_test/flutter_test.dart';
import 'package:n_triples_db/n_triples_db.dart';
import 'package:n_triples_parser/n_triples_types.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:tuple/tuple.dart';

void main() {
  test('insertOrReplaceNTripleTerm and selectNTripleTerm', () {
    final db = NTriplesDb(sqlite3.openInMemory());

    final hash = db.insertOrReplaceNTripleTerm(
      NTripleTerm(
        termType: NTripleTermType.literal,
        value: "VALUE",
        languageTag: "LANG",
        dataType: "TYPE",
      ),
    );

    final result = db.selectNTripleTerm(hash);

    expect(
        result,
        NTripleTerm(
          termType: NTripleTermType.literal,
          value: "VALUE",
          languageTag: "LANG",
          dataType: "TYPE",
        ));
  });

  test('insertNTriple', () {
    final db = NTriplesDb(sqlite3.openInMemory());

    final subject = db.insertOrReplaceNTripleTerm(
        NTripleTerm(termType: NTripleTermType.iri, value: "Subject"));

    final predicate1 = db.insertOrReplaceNTripleTerm(
        NTripleTerm(termType: NTripleTermType.iri, value: "Predicate1"));
    final object1 = db.insertOrReplaceNTripleTerm(
        NTripleTerm(termType: NTripleTermType.iri, value: "Object1"));

    final predicate2 = db.insertOrReplaceNTripleTerm(
        NTripleTerm(termType: NTripleTermType.iri, value: "Predicate2"));
    final object2 = db.insertOrReplaceNTripleTerm(
        NTripleTerm(termType: NTripleTermType.iri, value: "Object2"));

    db.insertNTriple(
      Tuple3(
        NTripleTerm(termType: NTripleTermType.iri, value: "Subject"),
        NTripleTerm(termType: NTripleTermType.iri, value: "Predicate1"),
        NTripleTerm(termType: NTripleTermType.iri, value: "Object1"),
      ),
    );

    db.insertNTriple(
      Tuple3(
        NTripleTerm(termType: NTripleTermType.iri, value: "Subject"),
        NTripleTerm(termType: NTripleTermType.iri, value: "Predicate2"),
        NTripleTerm(termType: NTripleTermType.iri, value: "Object2"),
      ),
    );

    final result1 = db.selectNTriplesByHash(subject: subject);
    expect(result1.length, 2);

    final result2 =
        db.selectNTriplesByHash(subject: subject, predicate: predicate2);
    expect(result2.length, 1);

    final result3 = db.selectNTriplesByHash(subject: "incorrect");
    expect(result3.length, 0);
  });

  test("insertOrReplaceNTripleTerm, replace same record does not throw", () {
    final db = NTriplesDb(sqlite3.openInMemory());
    db.insertOrReplaceNTripleTerm(
      NTripleTerm(
        termType: NTripleTermType.literal,
        value: "VALUE",
        languageTag: "LANG",
        dataType: "TYPE",
      ),
    );
    db.insertOrReplaceNTripleTerm(
      NTripleTerm(
        termType: NTripleTermType.literal,
        value: "VALUE",
        languageTag: "LANG",
        dataType: "TYPE",
      ),
    );
  });
}
