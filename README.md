# 이더리움 연구회 기술 블로그

[![Current Branch](https://img.shields.io/badge/dynamic/yaml.svg?label=current%20branch&url=https%3A%2F%2Fraw.githubusercontent.com%2Fetherstudy%2Fblog.etherstudy.net%2Fmaster%2F.travis.yml&query=%24.default_branch)](https://github.com/etherstudy/blog.etherstudy.net) [![Build Status](https://travis-ci.org/etherstudy/blog.etherstudy.net.svg?branch=ui-18062)](https://travis-ci.org/etherstudy/blog.etherstudy.net) [![GitHub issues](https://img.shields.io/github/issues/etherstudy/blog.etherstudy.net.svg)](https://github.com/etherstudy/blog.etherstudy.net) [![GitHub contributors](https://img.shields.io/github/contributors/etherstudy/blog.etherstudy.net.svg)](https://github.com/etherstudy/blog.etherstudy.net/graphs/contributors/)



이 블로그는 이더리움 연구회에서 운영하는 기술 블로그입니다.



# Hosting

본 블로그는 Github pages를 통해 호스팅됩니다. 호스팅되는 브랜치는 `gh-pages` 브랜치이며, 실제로는 `master` 브랜치의 [`.travis.yml`](https://github.com/etherstudy/blog.etherstudy.net/blob/master/.travis.yml) 파일의 `default_branch` 항목이 가리키는 브랜치[![Current Branch](https://img.shields.io/badge/dynamic/yaml.svg?label=current%20branch&url=https%3A%2F%2Fraw.githubusercontent.com%2Fetherstudy%2Fblog.etherstudy.net%2Fmaster%2F.travis.yml&query=%24.default_branch)](https://github.com/etherstudy/blog.etherstudy.net) 에 변경사항이 발생하면, [Travis CI](https://travis-ci)에 의해 변경사항이 `gh-pages` 브랜치로 Force Push 되는 방식으로 업데이트 됩니다. 따라서 새로운 테마를 적용하는 등의 개편을 진행할 때에는 새로운 브랜치를 생성하여 작업한 뒤 `master`의 [`.travis.yml`](https://github.com/etherstudy/blog.etherstudy.net/blob/master/.travis.yml)의 `default_branch` 항목을 해당 브랜치로 변경하면 됩니다.



# 새로운 포스트 작성하는 방법

1. Fork하기
     레포지토리를 본인 깃허브 계정으로 포크해주세요.  [![Github Fork](https://img.shields.io/github/forks/etherstudy/blog.etherstudy.net.svg?style=social&label=Fork)](https://github.com/etherstudy/blog.etherstudy.net/fork)


2. 포스팅용 브랜치 시작
     ```bash
     git clone https://github.com/$YOUR_GITHUB_ID/blog.etherstudy.net
     ```
     을 통해 클론하신 다음, 게시물 이름으로 새로운 브랜치를 시작해주세요.

     ```bash
     git checkout -b $BRANCH_NAME_WITH_POST_TITLE
     ```

3. 게시물 작성
     `_posts` 폴더에 `yyyy-mm-dd-title.markdown`의 형식으로 파일을 만들어주세요.

     게시물 작성을 완료하였으면 해당 게시물을 Stage에 올린 뒤 Commit합니다.
     ```bash
     git add ./_posts/$YOUR_POSTING_FILE
     git commit -m "$PUT_COMMIT_MESSAGE_HERE"
     ```

     자세한 내용은 [여기](/_posts/2018-06-24-welcome-to-jekyll.markdown)를 참조해주세요.

4. 푸쉬
     본인의 깃허브 계정에 게시물 작성을 위해 만든 브랜치를 푸쉬해주세요.
     ```bash
     git push $YOUR_REPOSITORY_URL $BRANCH_NAME_WITH_POST_TITLE
     ```

5. 풀리퀘스트

     Base branch를 [![Current Branch](https://img.shields.io/badge/dynamic/yaml.svg?label=current%20branch&url=https%3A%2F%2Fraw.githubusercontent.com%2Fetherstudy%2Fblog.etherstudy.net%2Fmaster%2F.travis.yml&query=%24.default_branch)](https://github.com/etherstudy/blog.etherstudy.net)으로 해서 [Pull Request를 만들어주세요](https://github.com/etherstudy/blog.etherstudy.net/compare).

6. Pull Request가 승인되면 게시물이 자동으로 업데이트 됩니다.



# Built with

- [Jekyll](https://jekyllrb.com)



# LICENSE
[MIT](/LICENSE)
