[![Build
Status](https://semaphoreci.com/api/v1/continuum/transbankdevelopers-web/branches/master/badge.svg)](https://semaphoreci.com/continuum/transbankdevelopers-web)

# transbankdevelopers-web

This is a auxiliary repository to help us sync the content changes made on
https://github.com/TransbankDevelopers/transbank-developers-docs into the
repositories used by Cumbre to build the TransbankDevelopers.cl website.

Most commits here will be automated updates to the latest commit of the master
branch of the three submodules:

- `slate-tbk` (a.k.a *"slate"*), pointing to our clone of Cumbre's slate machinery
  used to generate html from markdown sources.

- tbkdev_3.0-public (a.k.a *"web"*), pointing to our clone of a PHP application
  provided by Cumbre for us to "preview" the way the markdown (and the code!)
  will look on the real transbankdevelopers website. It's not really 100%
  fidelity, but it's close enough. The master branch of that repo is continously
  deployed by us to http://transbankdevelopers-3-preview.herokuapp.com.

- transbank-developers-docs (a.k.a *"docs"*), the public repository where the
  documentation lives and is somewhat readable/browsable as we (ab)use Github's
  support for markdown. The main win is that anyone can see the changes in the
  documentation and we can (hopefully) also receive contributions to it without
  the need to understand all the complexity on the slate side nor the PHP side.

In fact, the reason for this repo is exactly that: automate (if possible) the
transition from those simple markdown files published on the TransbankDevelopers
organization into the real thing that Cumbre needs to build the website. 

## How it works

For that, we run the [sync.sh](./sync.sh) script hourly [via
SemaphoreCI](https://semaphoreci.com/continuum/transbankdevelopers-web). It
basically does the following:

1. Integrate slate changes from two sources:
    - Whatever Cumbre changes in their repository is merged into `master` (if
      possible)
    - Whatever is changed on the "docs" repository is copied/translated
      automatically to the way Cumbre expects it (adding the `{{dir}}` stuff,
      renaming every `README.md` to `index.md`, etc) and pushed into the
      `transbank-developers-docs` branch. Then (if possible) it is merged into
      master and pushed to Cumbre's repository too.

2. Integrate web changes from two sources:
    - Whatever Cumbre changes in their repository is merged into `master` (if
      possible)
    - Whatever is produced by the `build-all.sh` script on the slate repository
      is automatically added and pushed to the `slate-tbk` branch. Then (if
      possible ) it is merged into master and pushed to Cumbre's repository too.

There are some drawbacks from doing this in a repository that is itself updated
by the sync process (we push new changes into the submodules and then we need to 
keeping submodules up to date in the parent repository) and therefore triggers
new unnecesary builds. 

But this way provides a lot of traceability: via the CI platform we have full
visibility of which commit of each repository was involved on every build. Given
that this automation is never going to be perfect and we will have to manually
fix conflicts (and bugs on the sync script itself!) from time to time, the 
traceability/repeatability is very, very nice. 
