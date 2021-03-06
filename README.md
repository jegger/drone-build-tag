# drone-build-tag

Origin
------
This is a fork of jgreat/drone-build-tag.
New features:
- Fixes missing git
- Get version from python module
- Docker-tag are in a different format, see below

Python-module version usage:
* `build-tags.sh --py-module` will look in the root directory for a file called version.py; reads the variable `__version__`
* `build-tags.sh --py-module mymodule` will look in the `mymodule/` directory for a file called version.py; reads the variable `__version__`


Building
--------
- docker login
- docker build -t jegger/drone-build-tag:<TAG-VERSION> .
- docker push jegger/drone-build-tag:<TAG-VERSION>

Usage
-----

Tags:

* Feature branch: `$VERSION-$BRANCH.$SHA`
* Master: `$VERSION` and `latest` if git-tag is the same as the found version number.
* Master: `$VERSION-$COUNT.$SHA` count = commits since latest git-tag.

Searches for version in the following places (if arg --py-module is not set):

* `"version":` in `package.json`
* `version-string (example: 1.0.1)` in `version`
* `ENV APPLICATION_VERSION` in `Dockerfile`

`.drone.yml example`

``` yaml
pipeline:
  generate-build-tags:
    image: jegger/drone-build-tag
    commands:
      - build-tags.sh

  build:
    image: node:8
    commands:
      - npm install
      - npm test

  publish:
    image: plugins/docker
    repo: me/mynodeapp
    # tags will be read from the .env file generated by jegger/drone-build-tag
    env_file: .env
...
```
