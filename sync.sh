#!/bin/bash
set -o nounset
set -o pipefail
set -o errexit
set -o xtrace

# User for automated commits/merges:
git config user.email "transbankdevelopers@continuum.cl"
git config user.name "Transbank Developers Automated Scripts"

# Git initializes submodules using HTTPS which asks for user/password
# Let's change it to SSH instead
perl -i -p -e 's|https://(.*?)/|git@\1:|g' .gitmodules
perl -i -p -e 's|https://(.*?)/|git@\1:|g' .git/config

# Pull changes, just in case
git pull

# Lets's get to work. First, make sure we are working with the latest repos 
# downstream:
git submodule update --init --remote slate-tbk/ tbkdev_3.0-public/ transbank-developers-docs/
if ! git diff --exit-code; then
  git commit -am "Update downstream slate and web"
  git push
  echo "New commits have been pushed by this script due to incoming changes"
  echo "Syncing will continue on the next run"
  exit
fi

# Then let's make sure we have the latest changes from cumbre:
for repo in slate-tbk tbkdev_3.0-public; do
  cd "$repo"
  git config user.email "transbankdevelopers@continuum.cl"
  git config user.name "Transbank Developers Automated Scripts"
  git fetch origin
  git remote add -f cumbre "https://github.com/Cumbre/$repo.git" || \
    git fetch cumbre
  git checkout master
  git merge --no-edit cumbre/master
  git push origin master
  cd ..
done
git submodule update --remote slate-tbk/ tbkdev_3.0-public/
if ! git diff --exit-code; then
  git commit -am "Sync with downstream slate or web changes from cumbre"
  git push
  echo "New commits have been pushed by this script due to incoming changes"
  echo "Syncing will continue on the next run"
  exit
fi

# And now check if we have pending changes upstream:
if ! git diff --exit-code; then
  git commit -am "Update upstream docs"
  git push
  echo "New commits have been pushed by this script due to incoming changes"
  echo "Syncing will continue on the next run"
  exit
fi

# Alright, everything was in sync. Now let's move files around:
cp -a transbank-developers-docs/images/* slate-tbk/source/images/
cp -a transbank-developers-docs/{producto,documentacion,referencia,plugin} \
  slate-tbk/source/includes/

# And update the slate-tbk thing:
DEV_DOCS_HEAD="$(cd transbank-developers-docs/; git log --pretty=format:'%h' -n 1)"
cd slate-tbk
git checkout transbank-developers-docs
git pull
for f in $(find source/includes -name "README.md"); do 
  # Take README.md
  cat "$f" | \
    # Put {{dir}} on markdown links:
    sed -e 's/\](\//\]({{dir}}\//g' | \
    # Put {{dir}} on HTML links with single quotes
    sed -e 's/='\''\//='\''{{dir}}\//g' | \
    # Put {{dir}} on HTML links with double quotes 
    sed -e 's/="\//="{{dir}}\//g' | \
    # and put the output on index.md
    cat > "${f/README/index}"
  rm "$f" # the original README.md is no longer needed nor wanted
done
git add -A 
git diff --cached --exit-code || \
  git commit -m "Update from transbank-developers-docs $DEV_DOCS_HEAD"
git push origin transbank-developers-docs
# Now let's see if the changes coming from the docs repo are compatible with 
# any changes coming from the cumbre repo. Master is the integration point here
git checkout master
git merge --no-edit transbank-developers-docs
# If it went well, we can push and continue:
git push cumbre master
git push origin master
SLATE_HEAD="$(git log --pretty=format:'%h' -n 1)"
cd ..

# And we are done :)
