import 'package:flutter_test/flutter_test.dart';
import 'package:n_triples_db/n_triples_db.dart';
import 'package:n_triples_parser/n_triple_types.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:tuple/tuple.dart';
import 'package:uuid/uuid.dart';

void main() {
  test('sqlite3.version.libVersion', () {
    expect(sqlite3.version.libVersion, "3.40.1");
  });

  test('uuid.v4', () {
    const uuid = Uuid();
    final uuidV4Pattern = RegExp(
        r"[\dabcdef]{8}-[\dabcdef]{4}-[\dabcdef]{4}-[\dabcdef]{4}-[\dabcdef]{12}");
    expect(uuidV4Pattern.hasMatch(uuid.v4()), true);
  });

  test('insertNTripleTerm and selectNTripleTerm', () {
    final db = NTriplesDb(sqlite3.openInMemory());

    final uuid = db.insertNTripleTerm(
      NTripleTerm(
        termType: NTripleTermType.literal,
        value: "VALUE",
        languageTag: "LANG",
        dataType: "TYPE",
      ),
    );

    final result = db.selectNTripleTerm(uuid);

    expect(
        result,
        NTripleTerm(
          termType: NTripleTermType.literal,
          value: "VALUE",
          languageTag: "LANG",
          dataType: "TYPE",
        ));

    expect(
        uuid,
        db.selectUuid(NTripleTerm(
          termType: NTripleTermType.literal,
          value: "VALUE",
          languageTag: "LANG",
          dataType: "TYPE",
        )));
  });

  test('insertNTriple', () {
    final db = NTriplesDb(sqlite3.openInMemory());

    final subject = db.insertNTripleTerm(
        NTripleTerm(termType: NTripleTermType.iri, value: "Subject"));

    final predicate1 = db.insertNTripleTerm(
        NTripleTerm(termType: NTripleTermType.iri, value: "Predicate1"));
    final object1 = db.insertNTripleTerm(
        NTripleTerm(termType: NTripleTermType.iri, value: "Object1"));

    final predicate2 = db.insertNTripleTerm(
        NTripleTerm(termType: NTripleTermType.iri, value: "Predicate2"));
    final object2 = db.insertNTripleTerm(
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

    final result1 = db.selectNTriples(subject: subject);
    expect(result1.length, 2);

    final result2 = db.selectNTriples(subject: subject, predicate: predicate2);
    expect(result2.length, 1);

    final result3 = db.selectNTriples(subject: "incorrect");
    expect(result3.length, 0);
  });
}
