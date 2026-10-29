"""Convert the uploaded TuGraph-format movie/person and raw produce CSVs to lgraph_import CSVs.
Run: python scripts/prepare_movie_csv.py --input data/source --output data/movie_csv
"""
import argparse
import csv
from pathlib import Path

def parse_vertices(path, expected_label, fields):
    with path.open(encoding="utf-8-sig", newline="") as f:
        label = f.readline().strip()
        if label != "LABEL=" + expected_label:
            raise ValueError(f"{path}: expected LABEL={expected_label}, got {label}")
        reader = csv.reader(f)
        header = next(reader)
        if [h.split(":")[0] for h in header] != fields:
            raise ValueError(f"{path}: unexpected fields {header}")
        rows = []
        for row in reader:
            if not row:
                continue
            if len(row) != len(fields):
                raise ValueError(f"{path}: malformed row {row}")
            rows.append(row)
    ids = [row[0] for row in rows]
    if len(set(ids)) != len(ids):
        raise ValueError(f"{path}: duplicate IDs")
    return rows

def save(path, header, rows):
    with path.open("w", encoding="utf-8", newline="") as f:
        writer = csv.writer(f)
        writer.writerow(header)
        writer.writerows(rows)

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", type=Path, default=Path("data/source"))
    parser.add_argument("--output", type=Path, default=Path("data/movie_csv"))
    args = parser.parse_args()
    movies = parse_vertices(args.input / "movie.csv", "movie",
        ["id", "title", "tagline", "summary", "poster_image", "duration", "rated"])
    people = parse_vertices(args.input / "person.csv", "person",
        ["id", "name", "born", "poster_image"])
    with (args.input / "produce.csv").open(encoding="utf-8-sig", newline="") as f:
        produces = [row for row in csv.reader(f) if row]
    if any(len(row) != 2 for row in produces):
        raise ValueError("produce.csv must contain 2 columns: person_id,movie_id")
    people_ids = {r[0] for r in people}
    movie_ids = {r[0] for r in movies}
    if any(person not in people_ids or movie not in movie_ids for person,movie in produces):
        raise ValueError("produce.csv references unknown person or movie")
    if len(set(map(tuple, produces))) != len(produces):
        raise ValueError("Duplicate produce edges")
    args.output.mkdir(parents=True, exist_ok=True)
    save(args.output / "movies.csv",
         ["id", "title", "tagline", "summary", "poster_image", "duration", "rated"], movies)
    save(args.output / "people.csv",
         ["id", "name", "born", "poster_image"], people)
    save(args.output / "produced.csv", ["SRC_ID", "DST_ID"], produces)
    print(f"Prepared {len(movies)} movies, {len(people)} people, {len(produces)} PRODUCED edges")

if __name__ == "__main__":
    main()
