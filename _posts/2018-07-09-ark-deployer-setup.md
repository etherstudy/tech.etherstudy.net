---
layout: post
title:  "ARK deployer setup"
date:   2018-07-09 18:23:00 +0900
categories: ark deployer
author:  이동식
---

# ARK Deployer Setup

ARK Deploy를 이용해서 자신만의 Bridgechain 구성

![ARK deployer guide]({{site.url}}/assets/posts/ark-deployer-setup/1.png)

# ARK Deployer란?

ARK Deployer는 ARK 기반 블록 체인을 만들기위한 간단한 배포 스크립트입니다. ARK Deployer를 사용하여 개발자는 단 몇 분만에 자체 블록 체인을 만들 수 있습니다. ARK Deployer는 사용자 친화적이고 사용자 정의가 가능하며 ARK 프
로젝트에서 기대할 수있는 것과 동일한 사용자 경험을 제공하는보다 견고한 에코시스템을 구축하기 위한 첫 번째 단계 입니다.


ARK Deployer 스크립트는 ARK 기술을 기반으로 자신의 블록 체인을 시작하고 ARK 생태계가 어떻게 작동하는지 배우며 코드에 익숙해지기 위해 개발자, 해커 및 기술 애호가를 위해 발표되었습니다. 또한 해커톤 참가자들을 위한 커스텀 블록 체
인을 신속하게 보여주고 참가자들이 자신의 블록 체인을 설정할 수있게 해주는 특색있는 도구입니다.


설치 가이드 및 코드는 아래 사이트를 참조  
[https://github.com/ArkEcosystem/deployer](https://github.com/ArkEcosystem/deployer)


ARK Chain은 사전 설정된 ARK blockchain 매개 변수로 시작되며 사용자 정의 요구에 맞게 조정할 수도 있습니다.


ARK Deployer는 아래 항목에 대해 구성, 배포 및 통합합니다.

1. **Deploys ARK node** : 51명의 Forging genesis delegates(대리인)과 Autoforging 모드로 단일 컴퓨터 / 서버에 ARK Node를 배포 합니다. (ARK 노드를 복제하고 사용자 지정 매개 변수를 설정하고 Auto-forging delegate들과 함께 자신의 genesis 파일을 만듭니다).

    > 주) PoW기반의 블록 체인에서 블록의 유효성을 확인하고 새 블록을 만드는 과정을 마이닝(Mining)이라고 한다면, PoS기반의 블록 체인에서는 단조(Forging) 이라고 부릅니다. 두 용어가 같이 쓰이는 경우도 종종 있습니다.

1. **Deploys ARK Explorer** : 이미 구성된 ARK 탐색기를 설치하고 설치된 ARK 노드와 통신합니다.(복제, 구성, 설치 및 ARK 탐색기를 ARK 노드와 통합).

1. **Configures ARK API** : 개발자가 ARK 에코 시스템 기술 (REST API Swagger 문서 http://ark.brianfaust.me에서 제공)을 기반으로 솔루션을 탐색 및 개발을 시작할 수 있도록 ARK API를 구성합니다.


본격적으로 설치를 시작합니다.


# ARK Deployer Guide

자체 ARK Bridgechain을 설정하기 위한 가이드 입니다. 자체 ARK Clone Bridgechain을 시작하고, Auto-forging 설정, 자체 위임 노드를 추가하고, ARK 지갑(wallet)을 통해 액세스 할 수 있도록 합니다.

필요한 사전 준비 항목

- 신규 Ubuntu 16.04 장비 (Virtualbox 가상머신으로 준비)
- 시스템 Administration, command 라인 및 bash에 대한 기본 지식

이 가이드는 이미 사용된 특정 구성 집합을 기반으로 작성되었습니다. 따라서 브리지 체인과 노드의 IP 주소 설정면에서 차이가 있습니다. (자신의 정보에 맞게 바꿔주시기 바랍니다.)


Setup 순서

- 브릿지체인 노드(Bridgechain node) 구성
- Bridgechain Explorer 설정
- ARK Desktop Wallet 설치
- 데스크탑 Wallet에 Bridgechain 추가
- Forging 위임자(Delegate)를 네트워크에 추가
- 새 위임자(Delegate)에게 Voting하기

## 브릿지체인 노드(Bridgechain node) 구성

노드는 네트워크의 핵심 부분입니다. 블록을 단조(forge)하고 트랜잭션을 확인하며 네트워크에 포함 된 데이터에 대한 API 액세스를 제공하고 궁극적으로 모든 것을 실행 및 보안 상태로 유지합니다.

### ssh를 이용해 원격 접속을 위한 설정
```.bash
$ ssh -o PubkeyAuthentication=no ubuntu@192.168.56.101
$ ssh ubuntu@192.168.56.101
```
원격으로 접속되면 Git, Curl 그리고 필요한 업데이트를 수행합니다.

1. git 설치

    ```.bash
    ubuntu@ubuntu-pc:~$ sudo add-apt-repository ppa:git-core/ppa
    ubuntu@ubuntu-pc:~$ sudo apt-get update
    ubuntu@ubuntu-pc:~$ sudo apt-get install git-core
    ubuntu@ubuntu-pc:~$ git version
    git version 2.17.1
    ubuntu@ubuntu-pc:~$
    ```

1. Install Curl on Ubuntu

    ```.bash
    ubuntu@ubuntu-pc:~$ sudo apt-get update
    ubuntu@ubuntu-pc:~$ sudo apt-get install curl
    ubuntu@ubuntu-pc:~$ curl --version
    curl 7.47.0 (x86_64-pc-linux-gnu) libcurl/7.47.0 GnuTLS/3.4.10 zlib/1.2.8 libidn/1.32 librtmp/2.3
    Protocols: dict file ftp ftps gopher http https imap imaps ldap ldaps pop3 pop3s rtmp rtsp smb smbs smtp smtps telnet tftp
    Features: AsynchDNS IDN IPv6 Largefile GSS-API Kerberos SPNEGO NTLM NTLM_WB SSL libz TLS-SRP UnixSockets
    ubuntu@ubuntu-pc:~$
    ```

### ARK Deployer 다운로드

먼저 로컬에 ARK Deployer를 다운로드 합니다.

```.bash
ubuntu@ubuntu-pc:~$ cd ~ && git clone https://github.com/ArkEcosystem/ark-deployer.git && cd ark-deployer
'ark-deployer'에 복제합니다...
remote: Counting objects: 548, done.
remote: Compressing objects: 100% (25/25), done.
remote: Total 548 (delta 12), reused 13 (delta 5), pack-reused 518
오브젝트를 받는 중: 100% (548/548), 97.21 KiB | 622.00 KiB/s, 완료.
델타를 알아내는 중: 100% (344/344), 완료.
ubuntu@ubuntu-pc:~/ark-deployer$
```

### NodeJS 및 NPM 설치

해당 curl 명령은 bash 명령어로 끝나기 때문에 아래 전체라인을 Copy & Paste 합니다.

실행 순서:
```.bash
$ curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.8/install.sh | bash
$ source ~/.profile
$ nvm install 8.9.1
$ sudo apt-get update && sudo apt-get install -y jq
```
실행 로그:
```.bash
ubuntu@ubuntu-pc:~/ark-deployer$ curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.8/install.sh | bash
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100 12540  100 12540    0     0  31074      0 --:--:-- --:--:-- --:--:-- 31116
=> Downloading nvm from git to '/home/ubuntu/.nvm'
=> '/home/ubuntu/.nvm'에 복제합니다...
remote: Counting objects: 264, done.
remote: Compressing objects: 100% (229/229), done.
생략...
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
ubuntu@ubuntu-pc:~/ark-deployer$ ls
LICENSE.md   app             config              manifest.json  vagrant
README.md    bootstrap       config.sample.json  prefixes.json
Vagrantfile  bridgechain.sh  lib                 sidechain.sh
ubuntu@ubuntu-pc:~/ark-deployer$
ubuntu@ubuntu-pc:~/ark-deployer$ source ~/.profile
ubuntu@ubuntu-pc:~/ark-deployer$ nvm install 8.9.1
Downloading and installing node v8.9.1...
Downloading https://nodejs.org/dist/v8.9.1/node-v8.9.1-linux-x64.tar.xz...
######################################################################## 100.0%
Computing checksum with sha256sum
Checksums matched!
Now using node v8.9.1 (npm v5.5.1)
Creating default alias: default -> 8.9.1 (-> v8.9.1)
ubuntu@ubuntu-pc:~/ark-deployer$
ubuntu@ubuntu-pc:~/ark-deployer$ sudo apt-get update && sudo apt-get install -y jq
[sudo] password for ubuntu:
기존:1 http://kr.archive.ubuntu.com/ubuntu xenial InRelease
기존:2 http://kr.archive.ubuntu.com/ubuntu xenial-updates InRelease
기존:3 http://kr.archive.ubuntu.com/ubuntu xenial-backports InRelease
기존:4 http://security.ubuntu.com/ubuntu xenial-security InRelease
기존:5 http://ppa.launchpad.net/git-core/ppa/ubuntu xenial InRelease
패키지 목록을 읽는 중입니다... 완료
패키지 목록을 읽는 중입니다... 완료
```

### 로컬 Bridgechain 설치 및 설정

```.bash
$./bridgechain.sh install-node --name MyTest --database ark_mytest --token MYTEST --symbol MT --node-ip 192.168.56.101 --explorer-ip 192.168.56.101 --autoinstall-deps
```
192.168.56.101 : Virtualbox Ubuntu 16.04 서버 IP 여기에있는 노드를 설치할 때 사용할 수있는 옵션이 더 많습니다. 또한 JSON 구성 파일을 사용할 수도 있으며, 여기에서 배울 수있습니다. 현재 네트워크의 요금이나 시간 변경으로 인해 Desktop Wallet이 체인과 작동하지 않습니다.

```.bash
ubuntu@ubuntu-pc:~/ark-deployer$ ./bridgechain.sh install-node --name MyTest --database ark_mytest --token MYTEST --symbol MT --node-ip  192.168.56.101 --explorer-ip  192.168.56.101 --autoinstall-deps
==> Checking Dependencies...
dpkg-query: no packages found matching postgresql
dpkg-query: no packages found matching postgresql-contrib
dpkg-query: no packages found matching libpq-dev
dpkg-query: no packages found matching htop
dpkg-query: no packages found matching nmon
dpkg-query: no packages found matching iftop
dpkg-query: no packages found matching libcairo2-dev
dpkg-query: no packages found matching libgif-dev
==> Installing Program Dependencies...
패키지 목록을 읽는 중입니다... 완료
의존성 트리를 만드는 중입니다
상태 정보를 읽는 중입니다... 완료
The following additional packages will be installed:
  autotools-dev comerr-dev krb5-multidev libcairo-script-interpreter2 libexpat1-dev
생략....
(node:13932) [DEP0013] DeprecationWarning: Calling an asynchronous function without callback is deprecated.
Your Genesis Details are:
  Passphrase: "file stadium mention unhappy barrel practice flower decide neither lemon cousin icon"
  Address: "MHGMAGaq8p5W7LeHRdC9S1oqJVpt1ckYQT"
==> Bridgechain Installed!
ubuntu@ubuntu-pc:~/ark-deployer$
```
설치가 완료되면 로그 내용중 아래 Passphrass와 Address를 기록해 둡니다.

```.bash
Passphrase: "file stadium mention unhappy barrel practice flower decide neither lemon cousin icon"
Address: "MHGMAGaq8p5W7LeHRdC9S1oqJVpt1ckYQT"
```

### Bridgechain 시작

```.bash
$ ./bridgechain.sh start-node --name MyTest
```
위 명령행 실행으로 Bridgechain이 Start되며 Auto-forging이 시작(begin)됩니다.

실행 로그:
```.bash
ubuntu@ubuntu-pc:~/ark-deployer$ ./bridgechain.sh start-node --name MyTest
==> Starting...
warn:    --minUptime not set. Defaulting to: 1000ms
warn:    --spinSleepTime not set. Your script will exit if it does not stay up for at least 1000ms
info:    Forever processing file: app.js
==> Start OK!
Watch Logs? [y/N]: y
[inf] 2018-06-21 04:07:52 |
############################################
[inf] 2018-06-21 04:07:52 | # Ark node server started on: 0.0.0.0:4100 #
[inf] 2018-06-21 04:07:52 |
############################################
[inf] 2018-06-21 04:07:52 | Modules ready and launched
[inf] 2018-06-21 04:07:52 | Starting Node Manager
[inf] 2018-06-21 04:07:54 | Transaction pool started
[inf] 2018-06-21 04:07:54 | Mounting Network API
[inf] 2018-06-21 04:07:54 | Mounting Public API
[inf] 2018-06-21 04:07:54 | ###########################
[inf] 2018-06-21 04:07:54 | # Started as a relay node #
[inf] 2018-06-21 04:07:54 | ###########################
[inf] 2018-06-21 04:07:55 | Mempool cleaned: 0 transaction(s) removed, 0 transaction(s) kept
[inf] 2018-06-21 04:07:55 | Forging enabled on account: MAcQsn5gS6yQg9Zw6fQRy5Git5rEXnw9Si
[inf] 2018-06-21 04:07:55 | loaded 1 forgers of round 1
[inf] 2018-06-21 04:07:55 | Forging enabled on account: MN7oTh7jc7FU6Z5eCXXDefqFoDmvqUaVSd
[inf] 2018-06-21 04:07:55 |
########################################################
[inf] 2018-06-21 04:07:55 | # Congratulations! This node is now an active delegate #
[inf] 2018-06-21 04:07:55 |
########################################################
[inf] 2018-06-21 04:07:55 | loaded 51 active delegates of round 1
[inf] 2018-06-21 04:07:55 | Forging enabled on account: MD9siFjbGryD7jt7GJMQpH6ikSyRDQR4MT
[inf] 2018-06-21 04:07:55 | Forging enabled on account: MQJt3hv7RDTSXsWMCtgDzwPokQUY9xxsaA
[inf] 2018-06-21 04:07:55 | Forging enabled on account: MFnjwSqUh8kyqQXDCYwWmHytYi3N2mycvf
[inf] 2018-06-21 04:07:55 | Loading blocks from: http://127.0.0.4:4100
[inf] 2018-06-21 04:07:55 | Forging enabled on account: MUA7ARnAB3uiR8pXiH5TV5nosyiikqXTTR
[inf] 2018-06-21 04:07:55 | Forging enabled on account: MNGoiu9BAJcfqJ9nSrYG5AFPZmvQ9P7jga
생략...
[inf] 2018-06-21 04:07:56 | Forging enabled on account: MTFyTsVkngxTKTyQpZjgQT57xqFXA9B4iP
[inf] 2018-06-21 04:07:56 | Forging enabled on account: MAQJ9RQZtYZthZJWuvarvBMe9b7tmRv6rf
[inf] 2018-06-21 04:07:57 | Forging enabled on account: MUDB4zqjshhZtySmQfTKcgVycWJ6Xrc9Rh
[inf] 2018-06-21 04:07:57 | Forging enabled on account: MFFUx4nTk3jrXTsTdtfv7Q9GQmoZ55SobZ
[inf] 2018-06-21 04:07:57 | Forging enabled on account: MVW66m3cw2oUCydFManYihKBgh2WhgqSWZ
[inf] 2018-06-21 04:07:57 |
####################################################
[inf] 2018-06-21 04:07:57 | # Loaded 51 delegate(s). Started as a forging node #
[inf] 2018-06-21 04:07:57 |
####################################################
[inf] 2018-06-21 04:07:58 | Forked from network - network: 0 quorum: 0 last block id: 2529026575367914261
생략...
[inf] 2018-06-21 04:08:01 | Enough quorum from network - quorum: 1 last block id: 2529026575367914261
[inf] 2018-06-21 04:08:01 | Forged new block id: 15524743126924398639 height: 2 round: 1 slot: 4931610 reward:0 transactions:0
[inf] 2018-06-21 04:08:01 | Adding forged to blockchain - 15524743126924398639
[inf] 2018-06-21 04:08:01 | Processing forged block - 15524743126924398639
[inf] 2018-06-21 04:08:08 | Enough quorum from network - quorum: 1 last block id: 15524743126924398639
[inf] 2018-06-21 04:08:08 | Forged new block id: 6042834484006051938 height: 3 round: 1 slot: 4931611 reward:0 transactions:0
[inf] 2018-06-21 04:08:08 | Adding forged to blockchain - 6042834484006051938
[inf] 2018-06-21 04:08:08 | Processing forged block - 6042834484006051938
```

## Bridgechain Explorer 설정

### Explorer 설치 (Azure가 아닌경우)

192.168.56.101 : 자신의 Virtualbox Ubuntu 16.04 서버 IP
```.bash
$ ./bridgechain.sh install-explorer --name MyTest --token MYTEST --node-ip 192.168.56.101 --explorer-ip 192.168.56.101 --skip-deps
```

실행 로그:

```.bash
ubuntu@ubuntu-pc:~/ark-deployer$ ./bridgechain.sh install-explorer --name MyTest --token MYTEST --node-ip 192.168.56.101 --explorer-ip 192.168.56.101 --skip-deps
==> Uninstalling Explorer...
==> Stopping...
/home/ubuntu/ark-deployer/app/process-explorer.sh: 줄 17: forever: 명령어를 찾을 수 없음
==> Stop OK!
==> Uninstall OK!
==> Installing Explorer to '/home/ubuntu/ark-explorer'...
'/home/ubuntu/ark-explorer'에 복제합니다...
remote: Counting objects: 10715, done.
remote: Compressing objects: 100% (57/57), done.
remote: Total 10715 (delta 21), reused 66 (delta 21), pack-reused 10631
오브젝트를 받는 중: 100% (10715/10715), 8.40 MiB | 1.54 MiB/s, 완료.
델타를 알아내는 중: 100% (6919/6919), 완료.
/home/ubuntu/ark-deployer/app/app-explorer.sh: 줄 20: npm: 명령어를 찾을 수 없음
ubuntu@ubuntu-pc:~/ark-deployer$
```

> 주) 실행하다가 nodejs관련 에러가 나는경우 아래 내용처리 필요

```.bash
ubuntu@ubuntu-pc:~$ vi /etc/hosts
ubuntu@ubuntu-pc:~$ forever list
/usr/bin/env: `node': 그런 파일이나 디렉터리가 없습니다
ubuntu@ubuntu-pc:~$ ls -al /usr/bin/nodejs
-rwxr-xr-x 1 root root 11187096  5월 21  2016 /usr/bin/nodejs
ubuntu@ubuntu-pc:~$ ls -al /usr/local/bin/nodejs
ls: '/usr/local/bin/nodejs'에 접근할 수 없습니다: 그런 파일이나 디렉터리가 없습니다
ubuntu@ubuntu-pc:~$ sudo apt-get install nodejs-legacy
[sudo] password for ubuntu:
패키지 목록을 읽는 중입니다... 완료
의존성 트리를 만드는 중입니다       
상태 정보를 읽는 중입니다... 완료
다음 새 패키지를 설치할 것입니다:
  nodejs-legacy
0개 업그레이드, 1개 새로 설치, 0개 제거 및 0개 업그레이드 안 함.
27.7 k바이트 아카이브를 받아야 합니다.
이 작업 후 81.9 k바이트의 디스크 공간을 더 사용하게 됩니다.
받기:1 http://kr.archive.ubuntu.com/ubuntu xenial-updates/universe amd64 nodejs-legacy all 4.2.6~dfsg-1ubuntu4.1 [27.7 kB]
내려받기 27.7 k바이트, 소요시간 0초 (380 k바이트/초)
Selecting previously unselected package nodejs-legacy.
(데이터베이스 읽는중 ...현재 229319개의 파일과 디렉터리가 설치되어 있습니다.)
Preparing to unpack .../nodejs-legacy_4.2.6~dfsg-1ubuntu4.1_all.deb ...
Unpacking nodejs-legacy (4.2.6~dfsg-1ubuntu4.1) ...
Processing triggers for man-db (2.7.5-1) ...
nodejs-legacy (4.2.6~dfsg-1ubuntu4.1) 설정하는 중입니다 ...
ubuntu@ubuntu-pc:~$ ls -al /usr/bin/nodejs
```

### 백그라운드로 Explorer 시작 (in the background)

```.bash
$ ./bridgechain.sh start-explorer
```

### 전면모드로 Explorere 시작(in the foreground)

```.bash
$ cd ~/ark-explorer && npm run bridgechain
```
여기서는 전면모드로 Explorer를 시작합니다.

실행 로그:

```
ubuntu@ubuntu-pc:~$ cd ark-deployer/
ubuntu@ubuntu-pc:~/ark-deployer$ ls
Appending    LICENSE.md   Vagrantfile     config              prefixes.json
Close        README.md    app             config.sample.json  sidechain.sh
Compressing  Start        bootstrap       lib                 vagrant
Downloading  Starting...  bridgechain.sh  manifest.json
ubuntu@ubuntu-pc:~/ark-deployer$
ubuntu@ubuntu-pc:~/ark-deployer$
ubuntu@ubuntu-pc:~/ark-deployer$
ubuntu@ubuntu-pc:~/ark-deployer$
ubuntu@ubuntu-pc:~/ark-deployer$
ubuntu@ubuntu-pc:~/ark-deployer$
ubuntu@ubuntu-pc:~/ark-deployer$ cd ~/ark-explorer && npm run bridgechain

> ark-explorer@3.0.0 bridgechain /home/ubuntu/ark-explorer
> npm run dev -- --env.network=bridgechain --env.host=192.168.56.101 --env.port=4200

> ark-explorer@3.0.0 dev /home/ubuntu/ark-explorer
> webpack-dev-server --inline --progress --config build/webpack.dev.conf.js "--env.network=bridgechain" "--env.host=192.168.56.101" "--env.port=4200"

Will use the arguments: host: '192.168.56.101', port: '4200', baseUrl: '/', network: 'bridgechain', routerMode: 'hash'
98% after emitting CopyPlugin

DONE  Compiled successfully in 16056ms                 15:12:34
|  Your application is running here: http://192.168.56.101:4200
```

탐색기가 실행되면 브라우저를 통해 탐색기로 이동하여 테스트 할 수 있습니다. (Explorer가 시작되면 자동으로 브라우저가 뜸)

![ARK explorer1]({{site.url}}/assets/posts/ark-deployer-setup/2.png)
![ARK explorer2]({{site.url}}/assets/posts/ark-deployer-setup/3.png)


## ARK Desktop Wallet 설치

[https://blog.ark.io/how-to-install-reinstall-ark-desktop-wallet-testnet-89c905ff6db8](https://blog.ark.io/how-to-install-reinstall-ark-desktop-wallet-testnet-89c905ff6db8)

![ARK wallet]({{site.url}}/assets/posts/ark-deployer-setup/4.png)

첫번째, Github에서 자신의 환경(Windows 32/64, Mac or Linux)에 맞는 최신
버젼을 다운로드 합니다. 

[https://github.com/ArkEcosystem/ark-desktop/releases](https://github.com/ArkEcosystem/ark-desktop/releases)

두번째, 자신의 컴퓨터에 적합한 Installer를 열고 새로운 client를 설치합니다.

세번째, 새 ArkClient를 시작합니다.

[https://github.com/ArkEcosystem/desktop-wallet/releases](https://github.com/ArkEcosystem/desktop-wallet/releases)


![ARK wallet github release]({{site.url}}/assets/posts/ark-deployer-setup/5.png)

![ARK wallet downloaded result]({{site.url}}/assets/posts/ark-deployer-setup/6.png)

설치되면 ARKClient를 더블클릭해서 실행합니다.

![ARK client]({{site.url}}/assets/posts/ark-deployer-setup/7.png)

## Desktop Wallet에 Bridgechain 추가

![ARK client 1]({{site.url}}/assets/posts/ark-deployer-setup/8.png)

바탕 화면 지갑에서 설정 (오른쪽 상단의 톱니 바퀴 아이콘)으로 이동하여 'MANAGE NETWORKS'를 선택
![ARK client setting 1]({{site.url}}/assets/posts/ark-deployer-setup/9.png)

“NEW"탭으로 이동하여 네트워크 이름을 지정하고 브리지 체인 노드의 URL ("http : //"를 포함하여 "/"을 끝까지)을 입력 한 다음 “Force"를 활성화하십시오. 강제 옵션은 네트워크를 다룰 때 데스크탑 지갑이 항상 이 피어에 연결된다는 것을 의미하며 피어를 처리하지 않습니다. 완료되면 “CREATE"버튼을 클릭하십시오.

![ARK client setting 2]({{site.url}}/assets/posts/ark-deployer-setup/10.png)

그런 다음 네트워크에 대한 모든 세부 정보가 표시됩니다. 여기에서 화면 하단의 “SAVE"버튼을 클릭하십시오.


![ARK client 2]({{site.url}}/assets/posts/ark-deployer-setup/11.png)

네트워크 (오른쪽 상단의 Wi-Fi 아이콘)에서 새로 생성 된 네트워크(TESTNETWORK)로 변경하십시오.

![ARK client 3]({{site.url}}/assets/posts/ark-deployer-setup/12.png)

"IMPORT ACCOUNT"를 클릭합니다.

![ARK client 4]({{site.url}}/assets/posts/ark-deployer-setup/13.png)

이제 노드를 설치할 때 부여한 genesis passhprase를 가져 와서 "Import"를 클릭하십시오.

![ARK client 5]({{site.url}}/assets/posts/ark-deployer-setup/14.png)

지갑에 이미 미리 채워진 토큰이 이미 있으며 사용 가능하다는 것을 알 수 있습니다. 그 토큰을 곧바로 새 지갑에 보낼 수 있습니다.

[http://192.168.56.101:4200/#/wallets/M9z6X9VuRUtWr8DtzLar9r4AtRJ6zNYAS3](http://192.168.56.101:4200/#/wallets/M9z6X9VuRUtWr8DtzLar9r4AtRJ6zNYAS3)

![ARK client 6]({{site.url}}/assets/posts/ark-deployer-setup/15.png)

토큰을 전달할 신규 어카운트를 생성합니다.

> Create Account
>
> “asthma fine scare noble only sleep cactus sail enroll despair toast small”
> “MSuEWVSSvH2H9pn1zbeUAqANGFsGZJRWCm”

![ARK client 7]({{site.url}}/assets/posts/ark-deployer-setup/16.png)

상단 보내기버튼을 클릭하여 보내고자하는 지갑의 주소를 적고 금액을 입력한 후 비밀번호를 입력합니다.

![ARK client 8]({{site.url}}/assets/posts/ark-deployer-setup/17.png)

보낼 주소를 입력하고 genesis 지갑에서 토큰을 보냅니다.

![ARK client 9]({{site.url}}/assets/posts/ark-deployer-setup/18.png)

보내고자 하는 토큰과 ARK 트랜잭션 비용 0.1이 소요됩니다.

![ARK client 10]({{site.url}}/assets/posts/ark-deployer-setup/19.png)

![ARK client 11]({{site.url}}/assets/posts/ark-deployer-setup/20.png)

Genesis 지갑(Wallet)의 트랜잭션 정보를 확인할 수 있습니다.

![ARK client 12]({{site.url}}/assets/posts/ark-deployer-setup/21.png)

![ARK client 13]({{site.url}}/assets/posts/ark-deployer-setup/22.png)

앞서 토큰을 보낸 지갑을 열어 보면 받은 내용(5000 MT)을 확인 할 수 있습니다.

## Forging 위임자(Delegate)를 네트워크에 추가

> Delegate 란?
>
> 대리인은 ARK 생태계 내의 사용자 또는 사용자 이름으로 생각할 수 있습니다. (추가 필요)
> https://ark-guide.readme.io/docs/what-are-delegates

방금 설정 한 데스크탑 지갑과 새 주소를 사용하여 대표 노드로 등록하고 새 노드를 설정하여 시드 노드 외부에서 Forging 할 수 있습니다. 이 섹션에서는 몇 가지 Command-line 경험이 필요합니다.

Delegate로 등록하기

![ARK client 14]({{site.url}}/assets/posts/ark-deployer-setup/23.png)

위임자로 등록하려는 지갑에서 메뉴 아이콘 (오른쪽 상단에 세로로 3 개의 점)을 클
릭합니다.

![ARK client 15]({{site.url}}/assets/posts/ark-deployer-setup/24.png)

그런 다음 "REGISTER DELEGATE"옵션을 선택합니다.

![ARK client 16]({{site.url}}/assets/posts/ark-deployer-setup/25.png)

![ARK client 17]({{site.url}}/assets/posts/ark-deployer-setup/26.png)

원하는 대리인 이름을 입력하고 암호를 입력하십시오. 그런 다음 해당 트랜잭션을
네트워크에 제출할 수 있습니다.

![ARK client 18]({{site.url}}/assets/posts/ark-deployer-setup/27.png)

바탕 화면 지갑을 다시로드하면 지갑이 이제 대리인이라는 것을 알 수 있습니다.

## 새 위임자(Delegate)에게 Voting하기

현재 Auto-forging 상태이기 때문에 스스로 투표 할 필요가 없습니다.

![ARK client 19]({{site.url}}/assets/posts/ark-deployer-setup/28.png)

새 위임 월렛에서 투표 탭으로 이동하여 'VOTE'버튼을 클릭하십시오.

![ARK client 20]({{site.url}}/assets/posts/ark-deployer-setup/29.png)

위임 목록에서 자신을 찾아 암호("asthma fine scare noble only sleep cactus sail enroll despair toast small")를 입력하십시오. 그런 다음 "NEXT"를 눌러 거래를 보낼 수 있습니다


![ARK client 21]({{site.url}}/assets/posts/ark-deployer-setup/30.png)

![ARK client 22]({{site.url}}/assets/posts/ark-deployer-setup/31.png)

그러면 투표 탭에 자신에 대한 정보가 표시됩니다.
또한 Explorer Delegate Monitor에 대리인이 표시됩니다.
