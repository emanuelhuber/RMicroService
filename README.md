# RMicroService

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