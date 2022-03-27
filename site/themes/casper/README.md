# Casper Matrix Theme

This is a theme for hugo adpated from [jonathanjanssens/hugo-casper3](https://github.com/jonathanjanssens/hugo-casper3) that adds a matrix of pass fails matching the output format
from [remote-apis-testing/remote-apis-testing](https://gitlab.com/remote-apis-testing/remote-apis-testing).

To use the matrix, supply a json file in the data folder with the following format:

```json
{
  "bazel@3.4.1+buildbarn@2deba4-283abe": { "pass": true, "run_time": 102 }
}
```

Here `run_time` is an optional parameter signifying the number of seconds the build
took and, if included, will show the time in the matrix.