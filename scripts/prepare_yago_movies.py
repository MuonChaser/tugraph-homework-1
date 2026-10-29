"""Extract a movie subgraph from a local YAGO RDF dump (Turtle or N-Triples).

This script does not ship or invent YAGO observations. Use a reasonably sized
YAGO subset; rdflib parses the supplied file into memory.
"""
import argparse
import csv
from pathlib import Path
from rdflib import Graph, URIRef
from rdflib.namespace import RDF, RDFS, Namespace

SCHEMA = Namespace("http://schema.org/")
HTTPS_SCHEMA = Namespace("https://schema.org/")

def predicate_is(p, name):
    return str(p) in (str(SCHEMA[name]), str(HTTPS_SCHEMA[name]))

def write_csv(path, header, rows):
    with path.open("w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f)
        writer.writerow(header)
        writer.writerows(sorted(rows))

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("source", type=Path, help="Local YAGO Turtle / N-Triples file (or prepared subset)")
    parser.add_argument("--format", choices=["turtle", "nt"], default=None)
    parser.add_argument("--output", type=Path, default=Path("data/yago"))
    args = parser.parse_args()
    g = Graph()
    g.parse(args.source, format=args.format or ("nt" if args.source.suffix == ".nt" else "turtle"))
    movies = {s for s, p, o in g.triples((None, RDF.type, None))
              if predicate_is(o, "Movie") and isinstance(s, URIRef)}
    # schema:Movie may be declared through another compatible vocabulary spelling.
    # Only actual YAGO entities and observed facts are exported.
    labels = {}
    for s, p, o in g.triples((None, None, None)):
        if (p == RDFS.label or predicate_is(p, "name")) and s not in labels:
            labels[s] = str(o)
    people, genres = set(), set()
    actors, directors, movie_genres = set(), set(), set()
    for movie in movies:
        for p, o in g.predicate_objects(movie):
            if not isinstance(o, URIRef):
                continue
            if predicate_is(p, "actor"):
                people.add(o); actors.add((str(movie), str(o)))
            elif predicate_is(p, "director"):
                people.add(o); directors.add((str(movie), str(o)))
            elif predicate_is(p, "genre"):
                genres.add(o); movie_genres.add((str(movie), str(o)))
    out = args.output
    out.mkdir(parents=True, exist_ok=True)
    write_csv(out / "movies.csv", ["id", "name"], [(str(x), labels.get(x, str(x).rsplit("/", 1)[-1])) for x in movies])
    write_csv(out / "people.csv", ["id", "name"], [(str(x), labels.get(x, str(x).rsplit("/", 1)[-1])) for x in people])
    write_csv(out / "genres.csv", ["id", "name"], [(str(x), labels.get(x, str(x).rsplit("/", 1)[-1])) for x in genres])
    for name, rows in (("acted_in.csv", actors), ("directed.csv", directors), ("has_genre.csv", movie_genres)):
        write_csv(out / name, ["SRC_ID", "DST_ID"], rows)
    print(f"Exported {len(movies)} movies, {len(people)} people, {len(genres)} genres; "
          f"{len(actors)} actor, {len(directors)} director, {len(movie_genres)} genre links")
    if not movies:
        raise SystemExit("No schema:Movie type triples found. Check YAGO version and input scope.")

if __name__ == "__main__":
    main()
