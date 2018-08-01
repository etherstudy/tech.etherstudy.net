---
layout: post
title:  "Tendermint 개발 가이드 How to develop with Virtualbox (Ubuntu 16.04)"
date:   2018-07-30 00:00:00 +0900
categories: tendermint development ubuntu virtualbox
author:  이동식
---

![img]({{site.url}}/assets/posts/tendermint-development-guide/0.png)

# Tendermint 개발 가이드 How to develop with Virtualbox (Ubuntu 16.04)

## 개요

이미 노트북(mac book)에 다양한 개발환경들이 설정되어 있어서 복잡함을 덜고자 Tendermint 개발 환경을 Virtualbox로 Ubuntu 16.04 환경으로 구성했습니다. Tendermint의 readthedocs.io 가이드를 기반으로 설치 Tendermint Core, abci-cli 설치를 통 해 기본 샘플들을 돌려보도록 하겠습니다.

Ubuntu 16.04 Virtualbox VMWare Image 생성
(ubuntu-16.04.4-desktop-amd64.iso 이용 - 설치과정은 생략)

기본 설정

![img]({{site.url}}/assets/posts/tendermint-development-guide/1.png)

시스템설정-메모리를충분히4G로설정

![img]({{site.url}}/assets/posts/tendermint-development-guide/2.png)

메인 노트북과 VM간 리모트작업을 위해서 두개의 네트워크 어댑터를 설정했습니다.

![img]({{site.url}}/assets/posts/tendermint-development-guide/3.png)

![img]({{site.url}}/assets/posts/tendermint-development-guide/4.png)

기본 설정을 마친 후 Ubuntu VM 시작하기

![img]({{site.url}}/assets/posts/tendermint-development-guide/5.png) 

필요한 프로그램들을 설치합니다
만일 메인 노트북 또는개발 환경이 준비 되었다면 아래 필요한 프로그램들 설치단계는 건너띄기 바랍니다.

#### Git 설치

```shell
ubuntu@ubuntu-pc:~$ sudo add-apt-repository ppa:git-core/ppa ubuntu@ubuntu-pc:~$ sudo apt-get update
ubuntu@ubuntu-pc:~$ sudo apt-get install git-core
ubuntu@ubuntu-pc:~$ git version
git version 2.17.1
ubuntu@ubuntu-pc:~$
```

#### Curl 설치

```shell
Install Curl on Ubuntu
 The most recent stable version is 7.50.2, released on 7th of September 2016. Use the following commands to install curl by using the apt-get install command:
ubuntu@ubuntu-pc:~$ sudo apt-get update
ubuntu@ubuntu-pc:~$ sudo apt-get install curl
ubuntu@ubuntu-pc:~$ curl --version
 curl 7.47.0 (x86_64-pc-linux-gnu) libcurl/7.47.0 GnuTLS/3.4.10 zlib/1.2.8 libidn/1.32 librtmp/2.3
 Protocols: dict file ftp ftps gopher http https imap imaps ldap ldaps pop3 pop3s rtmp rtsp smb smbs smtp smtps telnet tftp
 Features: AsynchDNS IDN IPv6 Largefile GSS-API Kerberos SPNEGO NTLM NTLM_WB SSL libz TLS-SRP UnixSockets
ubuntu@ubuntu-pc:~$
```

기본 편집기로 Atom 또는 Visual studio Code를 설치합니다.( 옵션 )

#### Atom 설치

```shell
# wget으로 설치 파일 다운로드
# 최신 버전은 https://atom.io/releases 에서 확인 가능합니다.
ubuntu@ubuntu-pc:~$ wget https://github.com/atom/atom/releases/download/v1.28.2/ atom-amd64.deb
# 다운로드가 안될 경우 직접 사이트로 가서 받습니다. (다운로드 폴더에 저장) #다운받은파일이있는폴더로이동해서아래명령어실행 ubuntu@ubuntu-pc:~/다운로드$ sudo dpkg -i atom-amd64.deb
Selecting previously unselected package atom.
(데이터베이스 읽는중 ...현재 216631개의 파일과 디렉터리가 설치되어 있습니다.) Preparing to unpack atom-amd64.deb ...
Unpacking atom (1.28.2) ...
atom (1.28.2) 설정하는 중입니다 ...
Processing triggers for gnome-menus (3.13.3-6ubuntu3.1) ...
Processing triggers for desktop-file-utils (0.22-1ubuntu5.1) ...
Processing triggers for bamfdaemon (0.5.3~bzr0+16.04.20160824-0ubuntu1) ... Rebuilding /usr/share/applications/bamf-2.index...
Processing triggers for mime-support (3.59ubuntu1) ...
ubuntu@ubuntu-pc:~/다운로드$
```

#### Visual Studio Code 설치

```shell
# wget으로 설치 파일 다운로드
# 최신 버전은 https://atom.io/releases 에서 확인 가능합니다.
ubuntu@ubuntu-pc:~$ wget https://github.com/atom/atom/releases/download/v1.28.2/ atom-amd64.deb
# 다운로드가 안될 경우 직접 사이트로 가서 받습니다. (다운로드 폴더에 저장) #다운받은파일이있는폴더로이동해서아래명령어실행 ubuntu@ubuntu-pc:~/다운로드$ sudo dpkg -i atom-amd64.deb
Selecting previously unselected package atom.
(데이터베이스 읽는중 ...현재 216631개의 파일과 디렉터리가 설치되어 있습니다.) Preparing to unpack atom-amd64.deb ...
Unpacking atom (1.28.2) ...
atom (1.28.2) 설정하는 중입니다 ...
Processing triggers for gnome-menus (3.13.3-6ubuntu3.1) ...
Processing triggers for desktop-file-utils (0.22-1ubuntu5.1) ...
Processing triggers for bamfdaemon (0.5.3~bzr0+16.04.20160824-0ubuntu1) ... Rebuilding /usr/share/applications/bamf-2.index...
Processing triggers for mime-support (3.59ubuntu1) ...
ubuntu@ubuntu-pc:~/다운로드$
```

필요한 프로그램들을 설치합니다

#### Go 설치

바이너리를 받아서 설치하도록 하겠습니다. https://golang.org/doc/install?download=go1.10.3.linux-amd64.tar.gz

```shell
ubuntu@ubuntu-pc:~/다운로드$ sudo tar -C /usr/local -xvf go1.10.3.linux-amd64.tar.gz ...생략
go/test/writebarrier.go
go/test/zerodivide.go
ubuntu@ubuntu-pc:~/다운로드$ cd $HOME
ubuntu@ubuntu-pc:~$ pwd
/home/ubuntu
ubuntu@ubuntu-pc:~$ echo $PATH /home/ubuntu/.nvm/versions/node/v10.6.0/bin:/home/ubuntu/bin: /home/ubuntu/.local/bin:/usr/local/sbin:/usr/local/bin: /usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin ubuntu@ubuntu-pc:~$ mkdir -vp go/{src,pkg,bin}
mkdir: 'go' 디렉터리를 생성함
mkdir: 'go/src' 디렉터리를 생성함
mkdir: 'go/pkg' 디렉터리를 생성함
mkdir: 'go/bin' 디렉터리를 생성함 ubuntu@ubuntu-pc:~$ atom $HOME/.profile
편집기로 .profile 을 열고 GOPATH를 설정합니다.
# GOPATH
export PATH=$PATH:/usr/local/go/bin export GOPATH=$HOME/go
export PATH=$PATH:$GOPATH/bin
ubuntu@ubuntu-pc:~$ source $HOME/.profile
ubuntu@ubuntu-pc:~$ echo $PATH /home/ubuntu/bin:/home/ubuntu/.local/bin: /home/ubuntu/.nvm/versions/node/v10.6.0/bin:/home/ubuntu/bin: /home/ubuntu/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin: /usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin:/usr/local/go/bin
ubuntu@ubuntu-pc:~$ go version
go version go1.10.3 linux/amd64 ubuntu@ubuntu-pc:~$ ubuntu@ubuntu-pc:~$ go env GOPATH /home/ubuntu/go ubuntu@ubuntu-pc:~$ which go /usr/local/go/bin/go ubuntu@ubuntu-pc:~$ ubuntu@ubuntu-pc:~$ go env GOARCH="amd64"
GOBIN="" GOCACHE="/home/ubuntu/.cache/go-build" GOEXE=""
GOHOSTARCH="amd64"
GOHOSTOS="linux"
GOOS="linux"
GOPATH="/home/ubuntu/go"
GORACE=""
GOROOT="/usr/local/go"
GOTMPDIR="" GOTOOLDIR="/usr/local/go/pkg/tool/linux_amd64" GCCGO="gccgo"
CC="gcc"
CXX="g++"
CGO_ENABLED="1"
CGO_CFLAGS="-g -O2"
CGO_CPPFLAGS=""
CGO_CXXFLAGS="-g -O2"
CGO_FFLAGS="-g -O2"
CGO_LDFLAGS="-g -O2"
PKG_CONFIG="pkg-config"
GOGCCFLAGS="-fPIC -m64 -pthread -fmessage-length=0 -fdebug-prefix-map=/tmp/ go-build659009367=/tmp/go-build -gno-record-gcc-switches"
ubuntu@ubuntu-pc:~$
```

#### Go설치확인

```shell
#프로젝트 폴더에 들어가서 hello라는 디렉토리를 만듬 ubuntu@ubuntu-pc:~$ cd $GOPATH/src && mkdir hello ubuntu@ubuntu-pc:~/go/src$ pwd /home/ubuntu/go/src
ubuntu@ubuntu-pc:~/go/src$ ls
hello
ubuntu@ubuntu-pc:~/go/src$ cd hello ubuntu@ubuntu-pc:~/go/src/hello$ ls ubuntu@ubuntu-pc:~/go/src/hello$ atom hello.go ubuntu@ubuntu-pc:~/go/src/hello$ ls
hello.go
Atom 에디터가 열리면 아래 코드를 입력하고 저장합니다. package main
import "fmt"
func main() {
fmt.Printf("hello, world\n") }
ubuntu@ubuntu-pc:~/go/src/hello$ go build ubuntu@ubuntu-pc:~/go/src/hello$ ls
hello hello.go ubuntu@ubuntu-pc:~/go/src/hello$ ./hello hello, world ubuntu@ubuntu-pc:~/go/src/hello$
```

이제부터 본격적으로 Tendermint 를 설치하고 테스트 해보겠습니다.

#### Tendermint 소스 코드 받기

```shell
ubuntu@ubuntu-pc:~/go/src$ cd $GOPATH
ubuntu@ubuntu-pc:~/go$ ls
bin pkg src
ubuntu@ubuntu-pc:~/go$ pwd
/home/ubuntu/go
ubuntu@ubuntu-pc:~/go$ mkdir -p $GOPATH/src/github.com/tendermint ubuntu@ubuntu-pc:~/go$ cd $GOPATH/src/github.com/tendermint ubuntu@ubuntu-pc:~/go/src/github.com/tendermint$ git clone https://github.com/ tendermint/tendermint.git https://github.com/tendermint/tendermint.git'tendermint'에 복제합니다...
remote: Counting objects: 47607, done.
remote: Compressing objects: 100% (22/22), done.
remote: Total 47607 (delta 4), reused 6 (delta 0), pack-reused 47584 오브젝트를 받는 중: 100% (47607/47607), 48.87 MiB | 221.00 KiB/s, 완료. 델타를 알아내는 중: 100% (31276/31276), 완료. ubuntu@ubuntu-pc:~/go/src/github.com/tendermint$
```

#### Tools 받기

```shell
ubuntu@ubuntu-pc:~/go/src/github.com/tendermint$ cd tendermint
주) make get_tools 수행시 에러날경우 다시한변 명령을 실행하기 바랍니다 ubuntu@ubuntu-pc:~/go/src/github.com/tendermint/tendermint$ make get_tools --> Installing tools
go get -u -v github.com/mitchellh/goxgithub.com/golang/dep/cmd/dep gopkg.in/ alecthomas/gometalinter.v2 github.com/gogo/protobuf/protoc-gen-gogogithub.com/ gogo/protobuf/gogoprotogithub.com/square/certstrap
github.com/mitchellh/gox (download)
github.com/golang/dep (download)
...생략
```

#### Dependency 받기

```shell
github.com/square/certstrap/cmd
github.com/square/certstrap Installing:
deadcode dupl errcheck ...생략 unconvert unparam unused varcheck
위와 같이 get_tools가 성공하면 dependency를 받습니다. ubuntu@ubuntu-pc:~/go/src/github.com/tendermint/tendermint$ make get_vendor_deps
--> Running dep ubuntu@ubuntu-pc:~/go/src/github.com/tendermint/tendermint$
```

#### Tendermint 컴파일 및 설치확인

```shell
ubuntu@ubuntu-pc:~/go/src/github.com/tendermint/tendermint$ make install CGO_ENABLED=0 go install -ldflags "-X github.com/tendermint/tendermint/ version.GitCommit=`git rev-parse --short=8 HEAD`" -tags 'tendermint' ./cmd/ tendermint
ubuntu@ubuntu-pc:~/go/src/github.com/tendermint/tendermint$ make build
CGO_ENABLED=0 go build -ldflags "-X github.com/tendermint/tendermint/
version.GitCommit=`git rev-parse --short=8 HEAD`" -tags 'tendermint' -o build/
tendermint ./cmd/tendermint/
ubuntu@ubuntu-pc:~/go/src/github.com/tendermint/tendermint$
ubuntu@ubuntu-pc:~/go/src/github.com/tendermint/tendermint$ cd build # 빌드 확 인
ubuntu@ubuntu-pc:~/go/src/github.com/tendermint/tendermint/build$ ls -l 합계 26340
-rwxrwxr-x 1 ubuntu ubuntu 26969071 7월 22 12:46 tendermint ubuntu@ubuntu-pc:~/go/src/github.com/tendermint/tendermint/build$ cd .. ubuntu@ubuntu-pc:~/go/src/github.com/tendermint/tendermint$ tendermint version
0.22.4-c64a3c74
ubuntu@ubuntu-pc:~/go/src/github.com/tendermint/tendermint$ ubuntu@ubuntu-pc:~/go/src/github.com/tendermint/tendermint$ pwd /home/ubuntu/go/src/github.com/tendermint/tendermint
```

Tendermint Core가 정상적으로 설치되면 abci-cli를 설치합니다.

#### abcs-cli 설치

```shell
ubuntu@ubuntu-pc:~/go/src/github.com/tendermint$ go get github.com/tendermint/ abci
package github.com/tendermint/abci: no Go files in /home/ubuntu/go/src/ github.com/tendermint/abci
ubuntu@ubuntu-pc:~/go/src/github.com/tendermint$ ls
abci tendermint
ubuntu@ubuntu-pc:~/go/src/github.com/tendermint$ cd $GOPATH/src/github.com/ tendermint/abci
```

```shell
ubuntu@ubuntu-pc:~/go/src/github.com/tendermint/abci$ make get_tools
--> Installing tools
...생략
ubuntu@ubuntu-pc:~/go/src/github.com/tendermint/abci$ make get_vendor_deps --> Running dep ensure
ubuntu@ubuntu-pc:~/go/src/github.com/tendermint/abci$ make install ubuntu@ubuntu-pc:~/go/src/github.com/tendermint/abci$ abci-cli version 0.12.0
ubuntu@ubuntu-pc:~/go/src/github.com/tendermint/abci$ abci-cli
the ABCI CLI tool wraps an ABCI client and is used for testing ABCI servers
Usage:
	abci-cli [command]

Available Commands:
	batch		run a batch of abci commands against an application
	check_tx	validate a transaction
	commit		commit the application state and return the Merkle root hash
	console		start an interactive ABCI console for multiple commands
	counter		ABCI demo example
	deliver_tx	deliver a new transaction to the application
	echo		have the application echo a message
	help		Help about any command
	info		get some info about the application
	kvstore		ABCI demo example
	query		query the application state
	set_option	set an option on the application
	test 		run integration tests
	version 	print ABCI console version
Flags:
	--abci string either socket or grpc (default "socket")
	--address string address of application socket (default "tcp://0.0.0.0:26658")
	-h, --help help for abci-cli
	--log_level string set the logger level (default "debug")
	-v, --verbose print the command and results as if it were a console session

Use "abci-cli [command] --help" for more information about a command. ubuntu@ubuntu-pc:~/go/src/github.com/tendermint/abci$
```

지금까지 Tendermint Core 및 abci-cli를 설치했습니다.
이제 샘플 어플리케이션을 테스트해 보겠습니다.

TENDERMINT DEVELOPMENT - DONGSIK LEE 14

### 첫번째, KVStore 샘플

첫번째 샘플인 KVStore는 key=value의 모든 값을 Merkle tree로 저장하는 샘플입니다.
먼저 abci-cli로 kvstore 어플리케이션을 구동합니다.

![img]({{site.url}}/assets/posts/tendermint-development-guide/6.png)

이어서 다른 명령창을 띄우고 tendermint를 시작하게되면 앞서띄운 어플리케이션에 연결하 게 됩니다.

먼저 tendermint를 초기화(init)합니다. 이때 $HOME/.tendermint에 필요한 파일들이 생성 되게 됩니다.
만일, 해당 데이터를 최기화 하고자 할경우 “tendermint unsafe_reset_all”을 실행해서 데이 터를 리셋합니다.

![img]({{site.url}}/assets/posts/tendermint-development-guide/7.png)

Tendermint node 명령으로 tendermint core를 실행하면 블록이 생성되는 것을 볼수 있습니 다.

![img]({{site.url}}/assets/posts/tendermint-development-guide/8.png)

첫번째 블록
(Height: 1, TotalTxs: 0, blockId: #FA89223F47BDA7289634F32E227A312F6C78AA7C)

![img]({{site.url}}/assets/posts/tendermint-development-guide/9.png)

두번째 블록
(Height: 2, TotalTxs: 0, blockId:#8F2861F0549DBF8715E1BC96C102DA4FA6ACEDB3)

![img]({{site.url}}/assets/posts/tendermint-development-guide/10.png)

세번째 블록
(Height: 3, TotalTxs: 0, blockId:#FACF02D03A02BB15104BEA944B34148F28135818)

![img]({{site.url}}/assets/posts/tendermint-development-guide/11.png)

계속적으로 블록의 Height는 증가하면서 새로 생성된 블록은 이전 블록의 ID를 포함하게 됩 니다.

```shell
abci-cli kvstore
```
![img]({{site.url}}/assets/posts/tendermint-development-guide/12.png)

Tendermint 노드의 상태 확인

![img]({{site.url}}/assets/posts/tendermint-development-guide/13.png)

```shell
curl -s localhost:26657/status
```
첫번째 트랜젝션을 전송합니다. 해당 명령으로 “abcd”를 전송하면 Merkle tree에 “abcd”를 key와 value로 저장합니다.

```shell
curl -s 'localhost:26657/broadcast_tx_commit?tx="abcd"'
```
![img]({{site.url}}/assets/posts/tendermint-development-guide/14.png)

저장된 값을 쿼리를 통해 조회합니다.

```shell
curl -s 'localhost:26657/abci_query?data="abcd"'
```
![img]({{site.url}}/assets/posts/tendermint-development-guide/15.png)

조회되는 “YWJjZA==“는 abcd에 대한 ASCII의 base64-encoding 값 입니다. 아래 사이트에서 base64 변환을 확인가능합니다.

[https://www.url-encode-decode.com/base64-encode-decode/ ](https://www.url-encode-decode.com/base64-encode-decode/ )

![img]({{site.url}}/assets/posts/tendermint-development-guide/16.png)
![img]({{site.url}}/assets/posts/tendermint-development-guide/17.png)

다른 키/값으로 데이터를 전송합니다.

```shell
curl -s 'localhost:26657/broadcast_tx_commit?tx="name=satoshi"'
```
![img]({{site.url}}/assets/posts/tendermint-development-guide/18.png)

“name” 키로 쿼리를 하면 “satoshi”에 대한 base64 값을 리턴합니다.

```shell
curl -s ‘localhost:26657/abci_query?data=“name"'
```
![img]({{site.url}}/assets/posts/tendermint-development-guide/19.png)

두번째트랜잭션후블록확인
트랜잭션을 두번 (“abcd”, “name=satoshi”) 전송했기 때문에 totalTxs 가 2가 되었습니다.

![img]({{site.url}}/assets/posts/tendermint-development-guide/20.png)

### 두번째, Counter 샘플

카운터 응용 프로그램은 Merkle tree를 사용하지 않고 트랜잭션을 보낸 횟수를 계산하거나 상태를 커밋합니다.
이 응용 프로그램에는 serial = off 및 serial = on의 두 가지 모드가 있습니다.

serial = on 일 때, 트랜잭션은 0부터 시작하는 big-endian으로 인코딩 된 증가 정수 여야합니 다.

serial = off이면 트랜잭션에 대한 제한이 없습니다.

라이브 블록 체인에서 트랜잭션은 블록으로 커밋되기 전에 메모리에 수집됩니다. 유효하지 않은 트랜잭션에 자원을 낭비하지 않기 위해 ABCI는 CheckTx 메시지를 제공합니다.이 메 시지는 응용 프로그램 개발자가 메모리에 저장되거나 다른 피어에게 수집되기 전에 트랜잭 션을 수락하거나 거부하는 데 사용할 수 있습니다.

Counter 응용 프로그램의 인스턴스에서 serial = on을 사용하면 CheckTx는 가장 마지막에 커밋 된 것보다 큰 정수만 트랜잭션을 허용합니다.

tendermint와 kvstore 응용 프로그램의 이전 인스턴스를 종료하고 카운터 응용 프로그램을 시작합니다. 플래그로 serial = on을 활성화 할 수 있습니다 :

```shell
abci-cli counter --serial
```
![img]({{site.url}}/assets/posts/tendermint-development-guide/21.png)

다른 커맨드창을 띄우고 tendermint를 리셋하고 노드를 시작합니다.

```shell
tendermint unsafe_reset_all
tendermint node
```
![img]({{site.url}}/assets/posts/tendermint-development-guide/22.png)
![img]({{site.url}}/assets/posts/tendermint-development-guide/23.png)

다시 블록이 초기화되어 Height는 1, TotalTxs는 0으로 시작되었습니다.
첫번째 트랜잭션을 전송합니다.

![img]({{site.url}}/assets/posts/tendermint-development-guide/24.png)

두번째 트랜잭션을 전송하겠습니다. 처음에 Counter App이 구동될때 serial == on 으로 구 동했기 때문에 다음 트랜잭션의 예상번호는 1 이어야 합니다.

1 대신, 5을 전송하면 아래와 같이 에러가 발생합니다.

![img]({{site.url}}/assets/posts/tendermint-development-guide/25.png)

다시 1을 전송하면 정상적으로 처리되는것을 확인 할 수 있습니다,

![img]({{site.url}}/assets/posts/tendermint-development-guide/26.png)

### 세번째, Javascript Counter 샘플

다른 언어로 작성된 어플리케이션을 구동해보겠습니다. 이 경우 javascrip로 된 counter 예제이며, node가 설되되어 있어야 합니다. ([install node](https://nodejs.org/en/download/))

![img]({{site.url}}/assets/posts/tendermint-development-guide/27.png)

```shell
ubuntu@ubuntu-pc:~$ go get github.com/tendermint/js-abci &> /dev/null ubuntu@ubuntu-pc:~$ cd $GOPATH/src/github.com/tendermint/js-abci/example ubuntu@ubuntu-pc:~/go/src/github.com/tendermint/js-abci/example$ npm install ...생략
ubuntu@ubuntu-pc:~/go/src/github.com/tendermint/js-abci/example$ cd .. ubuntu@ubuntu-pc:~/go/src/github.com/tendermint/js-abci$ ls ./example counter.js
ubuntu@ubuntu-pc:~/go/src/github.com/tendermint/js-abci$
```

Counter.js 실행

![img]({{site.url}}/assets/posts/tendermint-development-guide/28.png)

Tendermint 데이터를 리셋하고 node를 구동합니다.

![img]({{site.url}}/assets/posts/tendermint-development-guide/29.png)

```shell
curl localhost:26657/broadcast_tx_commit?tx=0x00 # ok
```

![img]({{site.url}}/assets/posts/tendermint-development-guide/30.png)

```shell
curl localhost:26657/broadcast_tx_commit?tx=0x05 # invalid nonce
```

![img]({{site.url}}/assets/posts/tendermint-development-guide/31.png)

```shell
curl localhost:26657/broadcast_tx_commit?tx=0x01 # ok
```

![img]({{site.url}}/assets/posts/tendermint-development-guide/32.png)

지금까지 Tendermint core 설치, abci-cli 설치, kvstore, counter, node js counter 세가지 샘플 을 테스트 했습니다.
