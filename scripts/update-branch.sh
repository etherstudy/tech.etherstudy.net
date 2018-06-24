#!/bin/bash

DEFAULT_BRANCH=$(curl 'https://api.github.com/repos/etherstudy/tech.etherstudy.net' | jq '.default_branch' | tr -d \")

eval "$(ssh-agent -s)" #start the ssh agent
echo -e $SSHKEY > deploy_key.pem
chmod 600 deploy_key.pem # this key should have push access
ssh-add deploy_key.pem

if [ "$TRAVIS_BRANCH" = "$DEFAULT_BRANCH" ]; then
  git checkout -b gh-pages $TRAVIS_BRANCH && git push git@github.com:etherstudy/tech.etherstudy.net.git gh-pages --force;
fi

if [ "$TRAVIS_BRANCH" = "master" ]; then
  echo "This branch is the 'master' branch"
  if [ "$(grep "default_branch: $DEFAULT_BRANCH" .travis.yml)" ]; then
    echo "Current default branch is $DEFAULT_BRANCH"
    exit 0
  else
    echo "Please go to the setting page https://github.com/etherstudy/tech.etherstudy.net/settings/branches and change the default branch"
    exit 1
  fi
else
  git fetch origin master
  git checkout -b master remotes/origin/master
  sed -i "s/^default_branch.*/default_branch: $DEFAULT_BRANCH/" .travis.yml
  if [ "$(git diff .travis.yml)" ]; then
    echo "Change the value of .travis.yml's default_branch variable."
    echo "You can set default branch at the setting page. https://github.com/etherstudy/tech.etherstudy.net/settings/branches"
    git config --global user.name "Etherstudy"
    git config --global user.email info@etherstudy.net
    git add .travis.yml
    git commit -m "Update default branch"
    git push git@github.com:etherstudy/tech.etherstudy.net.git master
  fi
fi
