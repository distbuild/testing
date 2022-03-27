# testing

[![Build Status](https://github.com/distbuild/testing/workflows/main/badge.svg?branch=main&event=push)](https://github.com/distbuild/testing/actions?query=workflow%3Amain)
[![Tag](https://img.shields.io/github/tag/distbuild/testing.svg)](https://github.com/distbuild/testing/tags)
[![Gitter chat](https://badges.gitter.im/craftslab/distbuild.png)](https://gitter.im/craftslab/distbuild)



## Introduction

*testing* is the build testing of [distbuild](https://github.com/distbuild) written in Hugo.



## Prerequisites

- Hugo >= 0.95.0



## Deploy

```bash
git clone https://github.com/distbuild/testing.git

cd testing/deploy
./run.sh -g -s compose-buildbarn.yml -c compose-goma.yml -d buildbarn+goma \
  -u ${{ github.server_url }}/${{ github.repository }}/actions/runs/${{ github.run_id }} > buildbarn+goma.json
```



## Run

```bash
git clone https://github.com/distbuild/testing.git

cd testing/site
hugo server
```



## Publish

https://distbuild.github.io/testing/



## License

Project License can be found [here](LICENSE).



## Reference

- [remote-apis-testing](https://gitlab.com/remote-apis-testing/remote-apis-testing)
