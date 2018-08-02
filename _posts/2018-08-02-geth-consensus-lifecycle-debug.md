---
layout: post
title:  "Geth와 Delve를 사용한 이더리움 컨센서스 라이프사이클 디버깅"
date:   2018-08-02 17:51:00 +0900
categories: ethereum geth delve debug consensus lifecycle
author:  Wasneob Lim
---

2018년은 "확장성의 해"라고 불려도 무방할만큼 블록체인생태계는 활발한 확장성 연구와 구현을 진행하고 있습니다. 이더리움에서도 확장성을 늘리기 위해 샤딩/플라즈마 등의 구현이 비콘 체인등을 통해 활발하게 이루어지고 있는데, 이 과정에서 합의 알고리즘은 중요한 부분을 담당하고 있습니다. 샤드 체인을 쪼개고, 사이드체인을 루트체인과 연동하여 신뢰할 수 있게 만드는 작업들은 비잔틴장군 문제와 완결 속도에 대한 문제를 풀기 위한 합의알고리즘을 만들고 이를 구현하는 과정들을 거쳐야 합니다.

## Consensus Lifecycle

블록체인에서 일반적으로 합의가 이루어지는 과정은 다음처럼 설명할 수 있을 것 같습니다.

1. 블록의 생성
2. 전파된 블록의 검증
3. 포크 선택과 완결
4. 올바른 행위에 대한 인센티브의 지급과 그렇지 않은 행위에 대한 페널티 부과

로 생각해볼 수 있겠습니다. 그렇다면,

누가 생성할 것인가?

- Proof of Work을 통해 모두가 생성가능하게 할 것인가
- Delegated Proof of Stake를 통해 선출된 Block producer들이 블록을 생성하게 할 것인가
- Proof of Stake를 사용해 일정 지분을 위탁한 사람이 생성할 수 있도록 할 것인가

검증은 어떻게 할 것인가?

- 검증인을 따로 둘 것인가?
- 검증 과정에서 잘못된 행위를 발견했을 경우에는 어떻게 할 것인가?

포크 발생 가능성은 어떻게 되고, 완결은 언제 할 수 있는가?

- Long range attack이 불가능해지는 시점을 완결 시점으로 결정할 것인가
- 지분예탁을 한 뒤 PBFT를 진행하는 사이드체인을 두는 것을 통해 즉각적인 완결성을 만들어낼 것인가

인센티브와 페널티는 어떻게 지급, 부과할 것인가?

- 누구에게 인센티브를 주어야 하는가? 생성인, 검증인 등?
- 검증인에게 주는 인센티브의 비율은 어떻게 되어야 하는가?
- PoS의 경우 인센티브가 골고루 퍼질 수 있도록 생성인을 계속해서 변경할 것인가
- 잘못된 행위를 발견했을 때 페널티를 부과하는 방법은 어떻게 되고, 잘못된 행위를 증명하는 방법은 어떻게 되는가?

등에 대한 질문들을 만들 수 있고, 이를 해결해 나가는 과정을 통해 개선된 버전의 합의 알고리즘을 만들어낼 수 있을 것입니다.



우리는 위와 같은 방법으로 더 나은 확장성을 가질 수 있는 합의알고리즘을 생각해볼 수 있습니다. 그리고 이를 구현한다면, 아무래도 빠른 구현을 위해서는 현재의 이더리움은 어떤 방식으로 합의를 이루고 있는지 소스코드 레벨에서 자세하게 뜯어보는 것이 도움이 될 것입니다. 이 과정을 진행하고자 이더리움 Private net을 geth로 구동시키고, 디버거를 통해 블록의 생성/전파/검증/포크선택의 과정을 코드레벨에서 분석해보겠습니다.

우선 각각 다른 역할을 가진 다음 두 개의 노드를 사용하겠습니다.

- Miner node
- Validator node



이 노드들을 사용해서,

1. 첫 번째로는 Miner 노드에게 Mining을 시키면서 블록이 생성되는 과정을 살펴보겠습니다.
2. 그리고 Validator 노드를 Miner 노드에 연결하여, 블록이 전파되는 과정을 보겠습니다.
3. Validator 노드가 Miner 노드로부터 전달받은 블록을 검증하는 과정을 살펴보겠습니다.



## Pre requisites

1. go-ethereum 소스코드와 geth binary를 준비합니다.

   ```bash
   go get github.com/ethereum/go-ethereum
   go install github.com/ethereum/go-ethereum/cmd/geth
   ```

2. delve

   geth 디버그에는 [delve](https://github.com/derekparker/delve)를 사용할 것입니다. 설치는 다음 링크를 통해 확인해주세요.

   https://github.com/derekparker/delve/tree/master/Documentation/installation



## Private network 준비

먼저 Test를 위한 디렉토리를 준비합니다.

```shell
$ mkdir consensus-debug
```

private network를 구동시키기 위해  `consensus-debug/genesis.json` 파일을 다음 내용으로 준비합니다. 편의를 위해 채굴난이도를 낮춰서 시작합니다.

```json
{
  "config": {
        "chainId": 1234,
        "homesteadBlock": 0,
        "eip155Block": 0,
        "eip158Block": 0
    },
  "alloc"      : {},
  "coinbase"   : "0x0000000000000000000000000000000000000000",
  "difficulty" : "0x1",
  "extraData"  : "",
  "gasLimit"   : "0x2fefd8",
  "nonce"      : "0x0000000000000042",
  "mixhash"    : "0x0000000000000000000000000000000000000000000000000000000000000000",
  "parentHash" : "0x0000000000000000000000000000000000000000000000000000000000000000",
  "timestamp"  : "0x00"
}
```

그리고,  두 노드를 위한 데이터 디렉토리를 각각 초기화해줍니다.

```bash
$ cd consensus-debug
$ geth init genesis.json --datadir=miner-node
$ geth init genesis.json --datadir=validator-node
```

`consensus-debug` 디렉토리의 구조는 다음처럼 되어야 합니다.

```bash
.
├── genesis.json
├── miner-node
│   ├── geth
│   └── keystore
└── validator-node    
    ├── geth
    └── keystore
```



## 디버거를 통한 라이프사이클 동작구조 해부

### Miner 노드의 동작과 블록 생성 디버깅

우리가 Miner 노드에서 블록을 생성하는 과정에서는 어떤 일들이 일어나는지 확인하기 위해 디버그할 메소드 목록은 다음과 같습니다.

- worker.commitTransaction()
- worker.commitNewWork()
- ethash.mine()
- Blockchain.insert()

즉, 블록 채굴을 위한 새로운 작업을 할당하고 이에 따라 ethash를 통해 Nonce값을 찾고 블록에 추가하는 과정을 자세하게 살펴보겠습니다. 먼저 geth 소스코드가 있는 곳으로 이동한 뒤, delve로 geth를 실행합니다. 프라이빗 네트워크를 사용하기 위해 `networkid`를  `genesis.json`에 정의한 1234번을 사용하고 `datadir`을 `miner-node`로 지정합니다.

여기에서 `$PROJ_DIR`는 `consensus-debug` 디렉토리를 의미합니다.

```shell
$ cd $GOPATH/src/github.com/ethereum/go-ethereum/cmd/geth
$ dlv debug -- --networkid=1234 --datadir=$PROJ_DIR/miner-node
```
> dlv를 geth binary에 붙여서 사용하는 것도 가능한 방법입니다. 하지만, 자세한 바이너리를 사용할 때엔 디버그에 한계가 있어 소스코드를 준비한 뒤 디버그 모드로 실행하는 편이 낫습니다.

위에 나열한 메소드들을 breakpoint로 지정하고 추적해보겠습니다.

```shell
(dlv) break commitNewWork
Breakpoint 1 set at 0x for ...
(dlv) break commitTransaction
Breakpoint 2 set at 0x for ...
(dlv) break ethash.mine
Breakpoint 3 set at 0x for ...
(dlv) break BlockChain.insert
Breakpoint 4 set at 0x for ...
```
continue를 입력해 노드를 동작시키면 시작과동시에 바로 다음  브레이크포인트에서 멈추게 됩니다.

```bash
(dlv) continue
...
> github.com/ethereum/go-ethereum/miner.(*worker).commitNewWork() /path/to/go/src/github.com/ethereum/go-ethereum/miner/worker.go:389 (hits goroutine(1):1 total:1) (PC: 0x48d39ab)
   384:		work.tcount = 0
   385:		self.current = work
   386:		return nil
   387:	}
   388:
=> 389:	func (self *worker) commitNewWork() {
   390:		self.mu.Lock()
   391:		defer self.mu.Unlock()
   392:		self.uncleMu.Lock()
   393:		defer self.uncleMu.Unlock()
   394:		self.currentMu.Lock()
```
이 때의 Call stack을 한 번 살펴보겠습니다.

```shell
(dlv) stack
 0  0x00000000048d39ab in github.com/ethereum/go-ethereum/miner.(*worker).commitNewWork
    at /path/to/go/src/github.com/ethereum/go-ethereum/miner/worker.go:389
 1  0x00000000048d100b in github.com/ethereum/go-ethereum/miner.newWorker
    at /path/to/go/src/github.com/ethereum/go-ethereum/miner/worker.go:161
 2  0x00000000048cd27a in github.com/ethereum/go-ethereum/miner.New
    at /path/to/go/src/github.com/ethereum/go-ethereum/miner/miner.go:65
 3  0x000000000493ab92 in github.com/ethereum/go-ethereum/eth.New
    at /path/to/go/src/github.com/ethereum/go-ethereum/eth/backend.go:169
 4  0x0000000004a14c2a in github.com/ethereum/go-ethereum/cmd/utils.RegisterEthService.func2
    at /path/to/go/src/github.com/ethereum/go-ethereum/cmd/utils/flags.go:1171
 5  0x0000000004841cdb in github.com/ethereum/go-ethereum/node.(*Node).Start
    at /path/to/go/src/github.com/ethereum/go-ethereum/node/node.go:182
 6  0x0000000004a04e00 in github.com/ethereum/go-ethereum/cmd/utils.StartNode
    at /path/to/go/src/github.com/ethereum/go-ethereum/cmd/utils/cmd.go:67
 7  0x0000000004bec0c1 in main.startNode
    at ./main.go:270
 8  0x0000000004bebfec in main.geth
    at ./main.go:258
```

즉, 콜스택에 따르면, 다음과 같은 일들이 벌어졌음을 알 수 있습니다.

`main.geth`: 커맨드라인으로 geth를 동작 시킴

`main.startNode`: geth가 노드를 시작하도록 만듦.

`(*Node).Start `: 노드 구현체는 Start함수를 실행.

`RegisterEthService` : 이더리움 서비스를 등록함

`eth.New`: 이더리움 객체를 생성

`miner.New`: 마이너 객체를 생성

`newWorker`: 마이너 객체가 생성될 때, 작업자 객체를 생성하도록 함.

`commitNewWork`: 작업자 객체가 생성될 때, 작업을 할당함.



다시 continue를 입력해서 노드를 동작시키겠습니다.

```shell
(dlv) continue
INFO [...

```

우리가 브레이크포인트로 찍어둔 commitNewWork 메소드는 처음 개체 생성시에 한 번 불리고 난 뒤 이제 더 이상 호출되지 않는 것을 볼 수 있습니다.

다른 터미널을 새로 열어서 miner node에 콘솔로 접속한다음 채굴을 시작합니다. 채굴을 위해 새로운 계정을 하나 만들어 이더베이스를 세팅하고 `miner.start()`를 명령하겠습니다.

```javascript
geth attach $PROJ_DIR/miner-node/geth.ipc
> personal.newAccount()
Passphrase: ****
Repeat Passphrase: ****
"0x6323fe76b78cfdb98f9112d1f177199c7f3f7338"
> miner.start()
```
이제 디버거창은 다음과 같이 `commitNewWork`에 새로운 호출이 발생했음을 알려줍니다.

```shell
> github.com/ethereum/go-ethereum/miner.(*worker).commitNewWork() /path/to/go/src/github.com/ethereum/go-ethereum/miner/worker.go:389 (hits goroutine(1470):1 total:2) (PC: 0x48d39ab)
   384:		work.tcount = 0
   385:		self.current = work
   386:		return nil
   387:	}
   388:
=> 389:	func (self *worker) commitNewWork() {
   390:		self.mu.Lock()
   391:		defer self.mu.Unlock()
   392:		self.uncleMu.Lock()
   393:		defer self.uncleMu.Unlock()
   394:		self.currentMu.Lock()
```
아까와 같이 콜스택을 다시 한 번 살펴보겠습니다.

```shell
(dlv) stack
0  0x00000000048d39ab in github.com/ethereum/go-ethereum/miner.(*worker).commitNewWork
   at /path/to/go/src/github.com/ethereum/go-ethereum/miner/worker.go:389
1  0x00000000048cda0f in github.com/ethereum/go-ethereum/miner.(*Miner).Start
   at /path/to/go/src/github.com/ethereum/go-ethereum/miner/miner.go:118
2  0x0000000004062ab1 in runtime.goexit
   at /usr/local/Cellar/go/1.10.1/libexec/src/runtime/asm_amd64.s:2361
```

이번에는 Miner의 Start에 의해  commitNewWork가 이루어진 것을 볼 수 있습니다. 이번에도 현재 실행되고 있는 goroutine을 한번 보겠습니다.

```shell
(dlv) goroutine
Thread 1094866 at /path/to/go/src/github.com/ethereum/go-ethereum/miner/worker.go:389
Goroutine 1470:
	Runtime: /path/to/go/src/github.com/ethereum/go-ethereum/miner/worker.go:389 github.com/ethereum/go-ethereum/miner.(*worker).commitNewWork (0x48d39ab)
	User: /path/to/go/src/github.com/ethereum/go-ethereum/miner/worker.go:389 github.com/ethereum/go-ethereum/miner.(*worker).commitNewWork (0x48d39ab)
	Go: /path/to/go/src/github.com/ethereum/go-ethereum/eth/backend.go:356 github.com/ethereum/go-ethereum/eth.(*Ethereum).StartMining (0x493d4a8)
	Start: /path/to/go/src/github.com/ethereum/go-ethereum/miner/miner.go:106 github.com/ethereum/go-ethereum/miner.(*Miner).Start (0x48cd910)
```

이 디버그 정보에 따르면 이번 브레이크포인트에 걸린 쓰레드는 Ethereum객체의 StartMining메소드에 의해 실행된 goroutine입니다.  즉, `Ethereum.StartMining` 메소드가 콘솔에서의 api호출을 통해 실행되었고, 이 것은 Miner 객체의 Start 메소드를 goroutine으로 실행하였습니다.

다시 continue를 입력해 다음 단계로 넘어가봅니다. 이번에는 ethash의 mine 함수가 호출된 것을 볼 수 있습니다.

```shell
> github.com/ethereum/go-ethereum/consensus/ethash.(*Ethash).mine() /path/to/go/src/github.com/ethereum/go-ethereum/consensus/ethash/sealer.go:97 (hits goroutine(452):1 total:1) (PC: 0x4867f7b)
    92:         return result, nil
    93: }
    94:
    95: // mine is the actual proof-of-work miner that searches for a nonce starting from
    96: // seed that results in correct final block difficulty.
=>  97: func (ethash *Ethash) mine(block *types.Block, id int, seed uint64, abort chan struct{}, found chan *types.Block) {
    98:         // Extract some data from the header
    99:         var (
   100:                 header  = block.Header()
   101:                 hash    = header.HashNoNonce().Bytes()
   102:                 target  = new(big.Int).Div(maxUint256, header.Difficulty)

```
또다시 콜스택과 goroutine을 출력해보겠습니다.

```shell
(dlv) stack
0  0x0000000004867f7b in github.com/ethereum/go-ethereum/consensus/ethash.(*Ethash).mine
   at /path/to/go/src/github.com/ethereum/go-ethereum/consensus/ethash/sealer.go:97
1  0x000000000486d3f9 in github.com/ethereum/go-ethereum/consensus/ethash.(*Ethash).Seal.func1
   at /path/to/go/src/github.com/ethereum/go-ethereum/consensus/ethash/sealer.go:72
2  0x0000000004062ab1 in runtime.goexit
   at /usr/local/Cellar/go/1.10.1/libexec/src/runtime/asm_amd64.s:2361

(dlv) goroutine
Thread 993192 at /path/to/go/src/github.com/ethereum/go-ethereum/consensus/ethash/sealer.go:97
Goroutine 452:
        Runtime: /path/to/go/src/github.com/ethereum/go-ethereum/consensus/ethash/sealer.go:97 github.com/ethereum/go-ethereum/consensus/ethash.(*Ethash).mine (0x4867f7b)
        User: /path/to/go/src/github.com/ethereum/go-ethereum/consensus/ethash/sealer.go:97 github.com/ethereum/go-ethereum/consensus/ethash.(*Ethash).mine (0x4867f7b)
        Go: /path/to/go/src/github.com/ethereum/go-ethereum/consensus/ethash/sealer.go:70 github.com/ethereum/go-ethereum/consensus/ethash.(*Ethash).Seal (0x4867ac0)
        Start: /path/to/go/src/github.com/ethereum/go-ethereum/consensus/ethash/sealer.go:70 github.com/ethereum/go-ethereum/consensus/ethash.(*Ethash).Seal.func1 (0x486d370)

```

이 콜스택이 시작된 시점은 Ethash의 Seal 메소드가 호출되었을 때, goroutine을 시작하면서 ethash.mine() 메소드를 호출하였습니다. Seal 메소드를 시작한 goroutine은 언제 실행되었는지 알아보기 위해 Seal메소드에 브레이크포인트를 걸어보겠습니다.   Seal 브레이크 포인트에 도달할 때까지 continue를 지속적으로 입력해서 넘어간 뒤, stack과 goroutine을 확인하겠습니다.

```shell
(dlv) break ethash.Seal
(dlv) continue
(dlv) continue
...
(dlv) stack
0  0x0000000004867ad9 in github.com/ethereum/go-ethereum/consensus/ethash.(*Ethash).Seal
   at /path/to/go/src/github.com/ethereum/go-ethereum/consensus/ethash/sealer.go:76
1  0x00000000048ccc40 in github.com/ethereum/go-ethereum/miner.(*CpuAgent).mine
   at /path/to/go/src/github.com/ethereum/go-ethereum/miner/agent.go:103
2  0x0000000004062ab1 in runtime.goexit
   at /usr/local/Cellar/go/1.10.1/libexec/src/runtime/asm_amd64.s:2361

(dlv) goroutine
Thread 1033082 at /path/to/go/src/github.com/ethereum/go-ethereum/consensus/ethash/sealer.go:76
Goroutine 980:
        Runtime: /path/to/go/src/github.com/ethereum/go-ethereum/consensus/ethash/sealer.go:76 github.com/ethereum/go-ethereum/consensus/ethash.(*Ethash).Seal (0x4867ad9)
        User: /path/to/go/src/github.com/ethereum/go-ethereum/consensus/ethash/sealer.go:76 github.com/ethereum/go-ethereum/consensus/ethash.(*Ethash).Seal (0x4867ad9)
        Go: /path/to/go/src/github.com/ethereum/go-ethereum/miner/agent.go:88 github.com/ethereum/go-ethereum/miner.(*CpuAgent).update (0x48ccaa3)
        Start: /path/to/go/src/github.com/ethereum/go-ethereum/miner/agent.go:102 github.com/ethereum/go-ethereum/miner.(*CpuAgent).mine (0x48ccb80)

```

출력결과를 보면 ethash.Seal 함수를 호출한 주체는 miner의 CpuAgent입니다. 즉, Miner를 시작할 때 Agent를 등록할 수 있고, commitNewWork을 통해 할당된 작업을 Agent가 받아간 뒤, ethash 알고리즘을 통해 nonce를 찾아내고 해당 결과를 알려주는 로직으로 설계되어 있는 것을 확인할 수 있습니다.

다시한 번 mine 메소드로 돌아가서, mine메소드가 실행될 때 어떻게 되는지 자세하게 살펴보기 위해 지속적으로 next(n) 명령을 입력해보겠습니다.

```shell
(dlv) n
> github.com/ethereum/go-ethereum/consensus/ethash.(*Ethash).mine() /path/to/go/src/github.com/ethereum/go-ethereum/consensus/ethash/sealer.go:130 (PC: 0x48685b0)
   125:                         if (attempts % (1 << 15)) == 0 {
   126:                                 ethash.hashrate.Mark(attempts)
   127:                                 attempts = 0
   128:                         }
   129:                         // Compute the PoW value of this nonce
=> 130:                         digest, result := hashimotoFull(dataset.dataset, hash, nonce)
   131:                         if new(big.Int).SetBytes(result).Cmp(target) <= 0 {
   132:                                 // Correct nonce found, create a new header with it
   133:                                 header = types.CopyHeader(header)
   134:                                 header.Nonce = types.EncodeNonce(nonce)
   135:                                 header.MixDigest = common.BytesToHash(digest)

```

작업에 필요한 헤더 값등을 설정한 뒤, abort 신호를 수신하기전까지는 attemps를 늘려가며 nonce를 찾는 것을 볼 수 있습니다. 여기에 131번 줄에서 결국 넌스를 찾아낸 상태가 되었습니다. 성공했을 때를 확인하기 위해서 133번 줄에 브레이크포인트를 걸고, local variable를 출력해봅니다.

```shell
(dlv) break 133
Breakpoint 10 set at 0x486877f for github.com/ethereum/go-ethereum/consensus/ethash.(*Ethash).mine() /path/to/go/src/github.com/ethereum/go-ethereum/consensus/ethash/sealer.go:133
(dlv) continue
> github.com/ethereum/go-ethereum/consensus/ethash.(*Ethash).mine() /path/to/go/src/github.com/ethereum/go-ethereum/consensus/ethash/sealer.go:133 (hits goroutine(1373):1 total:1) (PC: 0x486877f)
   128:                         }
   129:                         // Compute the PoW value of this nonce
   130:                         digest, result := hashimotoFull(dataset.dataset, hash, nonce)
   131:                         if new(big.Int).SetBytes(result).Cmp(target) <= 0 {
   132:                                 // Correct nonce found, create a new header with it
=> 133:                                 header = types.CopyHeader(header)
   134:                                 header.Nonce = types.EncodeNonce(nonce)
   135:                                 header.MixDigest = common.BytesToHash(digest)
   136:
   137:                                 // Seal and return a block (if still needed)
   138:                                 select {
(dlv) locals
attempts = 2319
dataset = (*github.com/ethereum/go-ethereum/consensus/ethash.dataset)(0xc4201cb400)
hash = []uint8 len: 32, cap: 32, [...]
header = (*github.com/ethereum/go-ethereum/core/types.Header)(0xc4279f0000)
logger = github.com/ethereum/go-ethereum/log.Logger(*github.com/ethereum/go-ethereum/log.logger) 0xc420dc1d10
nonce = 6458286174646869996
number = 24
target = (*math/big.Int)(0xc420dc1e98)
digest = []uint8 len: 32, cap: 32, [...]
result = []uint8 len: 32, cap: 32, [...]

```

출력 결과물을 보니 2319번의 시도 끝에 nonce를 찾아냈군요.



이번에는 insert 메소드에 걸린 브레이크포인트를 분석해보겠습니다. 해당 브레이크 포인트에서  stack과 goroutine을 출력하겠습니다.

> 이에 앞서서 args로 넘어온 bc와 block을 출력해보세요
>
> (dlv) args
>
> bc = ...
>
> block = ...
>
> (dlv) print bc
>
> (dlv) print block

```shell
> github.com/ethereum/go-ethereum/core.(*BlockChain).insert() /path/to/go/src/github.com/ethereum/go-ethereum/core/blockchain.go:477 (hits goroutine(64):23 total:23) (PC: 0x462891b)
   472: // assumes that the block is indeed a true head. It will also reset the head
   473: // header and the head fast sync block to this very same block if they are older
   474: // or if they are on a different side chain.
   475: //
   476: // Note, this function assumes that the `mu` mutex is held!
=> 477: func (bc *BlockChain) insert(block *types.Block) {
   478:         // If the block is on a side chain or an unknown one, force other heads onto it too
   479:         updateHeads := rawdb.ReadCanonicalHash(bc.db, block.NumberU64()) != block.Hash()
   480:
   481:         // Add the block to the canonical chain number scheme and mark as the head
   482:         rawdb.WriteCanonicalHash(bc.db, block.Hash(), block.NumberU64())

(dlv) stack
0  0x000000000462891b in github.com/ethereum/go-ethereum/core.(*BlockChain).insert
   at /path/to/go/src/github.com/ethereum/go-ethereum/core/blockchain.go:477
1  0x000000000462f3eb in github.com/ethereum/go-ethereum/core.(*BlockChain).WriteBlockWithState
   at /path/to/go/src/github.com/ethereum/go-ethereum/core/blockchain.go:990
2  0x00000000048d28b3 in github.com/ethereum/go-ethereum/miner.(*worker).wait
   at /path/to/go/src/github.com/ethereum/go-ethereum/miner/worker.go:320
3  0x0000000004062ab1 in runtime.goexit
   at /usr/local/Cellar/go/1.10.1/libexec/src/runtime/asm_amd64.s:2361
(dlv) goroutine
Thread 1033082 at /path/to/go/src/github.com/ethereum/go-ethereum/core/blockchain.go:477
Goroutine 64:
        Runtime: /path/to/go/src/github.com/ethereum/go-ethereum/core/blockchain.go:477 github.com/ethereum/go-ethereum/core.(*BlockChain).insert (0x462891b)
        User: /path/to/go/src/github.com/ethereum/go-ethereum/core/blockchain.go:477 github.com/ethereum/go-ethereum/core.(*BlockChain).insert (0x462891b)
        Go: /path/to/go/src/github.com/ethereum/go-ethereum/miner/worker.go:160 github.com/ethereum/go-ethereum/miner.newWorker (0x48d0ffd)
        Start: /path/to/go/src/github.com/ethereum/go-ethereum/miner/worker.go:298 github.com/ethereum/go-ethereum/miner.(*worker).wait (0x48d2430)
```

출력결과를 보면, insert는 miner.worker의 wait()에서 시작되었습니다. 이 함수는 miner가 작업 결과물을 들고올 때까지 기다리고 작업결과물이 나오면 블록에 추가하는 일을 하고 있는 것을 알 수 있습니다. 이 것이 실행되고 있는 goroutine은 miner.newWorker메소드로, worker 객체를 초기화할 때, wait()메소드를 goroutine으로 호출하는 것을 알 수 있습니다. insert 시에는 어떤 상황이 발생하는지 자세히 알아보기 위해 next 명령을 지속적으로 입력해보세요.



블록이 생성되는 과정을 디버거를 통해 자세하게 확인해보았습니다. 즉, PoW를 대체하는 알고리즘을 추가하고자 한다면, 블록을 생성하는 부분에 대해서는 이 함수들이 호출되는 영역들을 우리가 생각하는 규칙에 의해 행동이 결정될 수 있도록 수정하면 됩니다. PoS의 경우 Nonce를 찾는 것 대신 현재 내 이더베이스가 적절한 block proposal 권한이 있는지 확인한 뒤 내 서명과 함께 블록을 생성하여 worker의 wait()에 보내주는 방법 등을 사용할 수 있을 것입니다.



## 블록의 전파

블록이 전파되는 과정 또한 확인해보겠습니다. 이에 앞서 마이너 노드의 브레이크포인트를 모두 해제하고 노드를 정상적으로 동작시켜줍니다. 그리고 마이닝도 잠깐 멈춰보겠습니다.

```shell
# MINER Debugger

(dlv) clearall
(dlv) continue

# MINER Console

> miner.stop()
```

그리고 새로운 쉘을 띄워서 Validator node를 시작합니다.

이 노드에서는 `BlockChain.insert()` 메소드에 대해서 추적해보겠습니다.

```shell
# Validator node

$ cd $GOPATH/src/github.com/ethereum/go-ethereum/cmd/geth
$ dlv debug -- --networkid=1234 --datadir=$PROJ_DIR/validator-node --port 30304
(dlv) break BlockChain.insert
(dlv) continue
```

> miner node가 30303 포트를 사용하기 때문에 validator-node는 30304 포트를 사용합니다.

이제 Validator 노드에 콘솔로 접속하여 validator node의 enode url을 확인한 다음 miner node가 Peer로 등록하도록 합니다.

```shell
# Validator console
$ geth attach $PROJ_DIR/miner-node/geth.ipc
> admin.nodeInfo
> admin.nodeInfo
{
  enode: "enode://validatornodesenodeurl@*.*.*.*:30304",
  ...
}

# Miner console
admin.addPeer("enode://validatornodesenodeurl@*.*.*.*:30304")
```

잠시 후 두 노드가 서로 연결되면 insert에 걸어둔 브레이크포인트에 validator노드가 멈춥니다. 이 때 stack과 goroutine을 살펴보겠습니다.

```shell
(dlv) stack
0  0x000000000462891b in github.com/ethereum/go-ethereum/core.(*BlockChain).insert
   at /path/to/go/src/github.com/ethereum/go-ethereum/core/blockchain.go:477
1  0x000000000462f3eb in github.com/ethereum/go-ethereum/core.(*BlockChain).WriteBlockWithState
   at /path/to/go/src/github.com/ethereum/go-ethereum/core/blockchain.go:990
2  0x0000000004632435 in github.com/ethereum/go-ethereum/core.(*BlockChain).insertChain
   at /path/to/go/src/github.com/ethereum/go-ethereum/core/blockchain.go:1165
3  0x000000000462ffd7 in github.com/ethereum/go-ethereum/core.(*BlockChain).InsertChain
   at /path/to/go/src/github.com/ethereum/go-ethereum/core/blockchain.go:1003
4  0x0000000004898935 in github.com/ethereum/go-ethereum/eth/downloader.(*Downloader).importBlockResults
   at /path/to/go/src/github.com/ethereum/go-ethereum/eth/downloader/downloader.go:1361
5  0x0000000004899c10 in github.com/ethereum/go-ethereum/eth/downloader.(*Downloader).processFastSyncContent
   at /path/to/go/src/github.com/ethereum/go-ethereum/eth/downloader/downloader.go:1457
6  0x00000000048b229f in github.com/ethereum/go-ethereum/eth/downloader.(*Downloader).syncWithPeer.func7
   at /path/to/go/src/github.com/ethereum/go-ethereum/eth/downloader/downloader.go:470
7  0x00000000048b232b in github.com/ethereum/go-ethereum/eth/downloader.(*Downloader).spawnSync.func1
   at /path/to/go/src/github.com/ethereum/go-ethereum/eth/downloader/downloader.go:484
8  0x0000000004062ab1 in runtime.goexit
   at /usr/local/Cellar/go/1.10.1/libexec/src/runtime/asm_amd64.s:2361
```

```shell
(dlv) goroutine
Thread 1268009 at /path/to/go/src/github.com/ethereum/go-ethereum/core/blockchain.go:477
Goroutine 385:
        Runtime: /path/to/go/src/github.com/ethereum/go-ethereum/core/blockchain.go:477 github.com/ethereum/go-ethereum/core.(*BlockChain).insert (0x462891b)
        User: /path/to/go/src/github.com/ethereum/go-ethereum/core/blockchain.go:477 github.com/ethereum/go-ethereum/core.(*BlockChain).insert (0x462891b)
        Go: /path/to/go/src/github.com/ethereum/go-ethereum/eth/downloader/downloader.go:484 github.com/ethereum/go-ethereum/eth/downloader.(*Downloader).spawnSync (0x488ce70)
        Start: /path/to/go/src/github.com/ethereum/go-ethereum/eth/downloader/downloader.go:484 github.com/ethereum/go-ethereum/eth/downloader.(*Downloader).spawnSync.func1 (0x48b22d0)
```

stack과 goroutine을 살펴보면, downloade의 SpawnSync 메소드를 통해 루틴이 시작되었고,

spawnSync => syncWithPeer => processFastSyncContent => importBlockResults => InsertChain => writeBlockWithState => insert

의 순서로 블록을 블록체인에 추가하는 메소드가 호출된 것을 볼 수 있습니다. up 명령어를 통해 어떤식으로 함수호출이 상위 프레임으로 이동해가면서 코드를 살펴보면 좋습니다. 이제 spawnSync는 어떤 것에 의해 시작된 goroutine인지 확인하기 위해 `spawnSync` 메소드에 브레이크포인트를 걸고 다시 디버그를 restart 해서 sync를 시작해보겠습니다.

```shell
# Validtor node

(dlv) break spawnSync
(dlv) restart
(dlv) continue

# Miner console

> admin.addPeer("enode://..")
```

```shell
(dlv) stack
0  0x000000000488cd38 in github.com/ethereum/go-ethereum/eth/downloader.(*Downloader).spawnSync
   at /path/to/go/src/github.com/ethereum/go-ethereum/eth/downloader/downloader.go:479
1  0x000000000488c9af in github.com/ethereum/go-ethereum/eth/downloader.(*Downloader).syncWithPeer
   at /path/to/go/src/github.com/ethereum/go-ethereum/eth/downloader/downloader.go:474
2  0x000000000488bc35 in github.com/ethereum/go-ethereum/eth/downloader.(*Downloader).synchronise
   at /path/to/go/src/github.com/ethereum/go-ethereum/eth/downloader/downloader.go:399
3  0x000000000488ad82 in github.com/ethereum/go-ethereum/eth/downloader.(*Downloader).Synchronise
   at /path/to/go/src/github.com/ethereum/go-ethereum/eth/downloader/downloader.go:317
4  0x0000000004952b01 in github.com/ethereum/go-ethereum/eth.(*ProtocolManager).synchronise
   at /path/to/go/src/github.com/ethereum/go-ethereum/eth/sync.go:200
5  0x0000000004062ab1 in runtime.goexit
   at /usr/local/Cellar/go/1.10.1/libexec/src/runtime/asm_amd64.s:2361
```

```shell
(dlv) goroutine
Thread 1315386 at /path/to/go/src/github.com/ethereum/go-ethereum/eth/downloader/downloader.go:479
Goroutine 935:
        Runtime: /path/to/go/src/github.com/ethereum/go-ethereum/eth/downloader/downloader.go:479 github.com/ethereum/go-ethereum/eth/downloader.(*Downloader).spawnSync (0x488cd38)
        User: /path/to/go/src/github.com/ethereum/go-ethereum/eth/downloader/downloader.go:479 github.com/ethereum/go-ethereum/eth/downloader.(*Downloader).spawnSync (0x488cd38)
        Go: /path/to/go/src/github.com/ethereum/go-ethereum/eth/sync.go:155 github.com/ethereum/go-ethereum/eth.(*ProtocolManager).syncer (0x4952717)
        Start: /path/to/go/src/github.com/ethereum/go-ethereum/eth/sync.go:164 github.com/ethereum/go-ethereum/eth.(*ProtocolManager).synchronise (0x4952790)
```

동기화가 시작되는 부분의 코드에 점점 다가가고 있습니다. downloader는 Protocol Manager가 실행시킨 것이었군요. 이런 방식으로 syncer를 실행시킨 goroutine을 계속 찾아나가겠습니다.

최종적으로 우리가 디버그 포인트로 삼게 된 메소드들은 다음과 같습니다. 아래처럼 적절한 브레이크포인트를 모두 찾아냈으면 restart 명령을 통해 노드를 다시 시작하고 next / step, stepout을 적절하게 사용해서 어떤 절차로 싱크가 이루어지는지 확인합니다.

```shell
(dlv) break github.com/ethereum/go-ethereum/core.(*BlockChain).insert()
(dlv) break github.com/ethereum/go-ethereum/eth/downloader.(*Downloader).spawnSync()
(dlv) break github.com/ethereum/go-ethereum/eth.(*ProtocolManager).syncer()
(dlv) break github.com/ethereum/go-ethereum/eth.(*ProtocolManager).Start()
```

최종적으로 우리는 노드를 시작할 때, 프로토콜 매니저를 시작하고 여기에서 synchronisation을 명령하는 것을 차례차례 볼 수 있습니다.

이와 같은 방식으로

```shell
(dlv) break github.com/ethereum/go-ethereum/consensus/ethash.(*Ethash).VerifyHeaders()
```

가 어떻게 동작하는지 자세하게 파고들어보세요.



## Conclusion

디버거를 사용해서 블록이 생성되고 전파되고 검증되는 과정을 자세하게 살펴보았습니다. 이 부분들을 수정하는 것으로 새로운 합의알고리즘을 빠르게 구현할 수 있습니다.

특히, 디버거를 잘 사용하면 Line by Line 으로 Geth 전체가 어떻게 동작하는지 차분하게 살펴볼 수 있습니다. 소스코드만 있을 때, 코드의 시작점은 어디인지 등에 대해 파악하기가 쉽지 않은데, 디버거를 사용하면 호출 스택과 쓰레드 현황 및 변수 추적을 통해 전체 구조를 이해할 수 있습니다.

합의 알고리즘 뿐 아니라 다른 부분에 대한 것들도 이런 방법으로 추적할 수 있습니다. 특히 Geth 노드에서 출력해주는 Log는 전체 구조를 파악하는 것에 큰 도움을 줍니다. 원하는 로그를 출력하는 메소드르 검색한 뒤, 해당 메소드가 어떻게 동작하게 되는지 디버그해볼 수 있습니다.

Geth에는 좋은 테스트코드가 많이 작성되어있습니다. `dlv debug` 커맨드가 아니라 `dlv test` 커맨드를 사용하면 이미 작성된 테스트 코드들을 line by line으로 진행할 수 있고 이 것은 각각의 모듈에 대한 이해를 높이는데 큰 도움이 됩니다.

깃허브 저장소에 이 디버깅 튜토리얼을 위한 스크립트들이 준비되어 있습니다.

```shell
$ git clone https://github.com/etherstudy/geth-consensus-debug
```

이 레포지토리는 다음 파일들로 구성되어 있습니다.

- `genesis.json` : 프라이빗 네트워크를 구동하기 위한 genesis.json 파일. 편의를 위해 채굴난이도를 낮춰두었으며 network id는 1234로 설정되어 있습니다.
- `init-nodes.sh` : 우리가 사용하려는 3개의 노드를 `genesis.json`으로 초기화시킵니다.
- `debug-*-node.sh` : delve를 사용해 각각의 노드를 디버그모드로 실행시킵니다. miner노드는 30303 포트에서 동작하고, validator 노드는 30304로 동작하도록 되어있습니다.
- `attach-*-node.sh` : geth console을 사용해 각가의 노드에 콘솔로 접속합니다.
- `*-breakpoints.dlv` : 브레이크 포인트를 모아둔 파일입니다.
