# RMicroService

## TO DO

Use this table format:

```
CREATE TABLE gpr.gpr_trace
(
    id_trace integer NOT NULL DEFAULT nextval('gpr.gpr_trace_id_trace_seq'::regclass),
    geometry geometry(Point,4326),
    altitude numeric(5,2),
    traces smallint[],
    id_gpr_line integer NOT NULL,
    traces_count integer NOT NULL,
    CONSTRAINT gpr_trace_pkey PRIMARY KEY (id_trace),
    CONSTRAINT gpr_trace_id_gpr_line_678a36a92952f8bb_fk_gpr_line_id_gpr_line FOREIGN KEY (id_gpr_line)
        REFERENCES gpr.gpr_line (id_gpr_line) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
        DEFERRABLE INITIALLY DEFERRED
)
```

## how to run

```r
library(plumber)
r <- plumb("./upload.R")
r$run(port=8000)
```

Then use `POST` to upload a file (see `data/...` for file samples).

```
curl -v http://localhost:8000/upload -F "bin=@FILE____050.DZT"
```

If you upload a GPR file + coordinates, the GPR + coordinates are inserted
into a database (slow, old way)