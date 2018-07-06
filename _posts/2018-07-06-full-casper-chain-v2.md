---
layout: post
title:  "Full casper chain v2 spec: 이더리움 2.0, 캐스퍼+샤딩"
date:   2018-07-06 12:23:00 +0900
categories: ethereum casper shard
author:  Wanseob Lim <email@wanseob.com>
---

본 글은 2018년 6월 26일 현재 이더리움 연구팀이 제안하는 완전한 PoS에 대한 스펙을 소개하는 글입니다. 이를 통해 향후 캐스퍼 개발이 나아갈 방향을 짐작해볼 수 있습니다.

본문은 다음을 참고해주시면 감사하겠습니다.
https://ethresear.ch/t/convenience-link-to-full-casper-chain-v2-spec/2332

# TL;DR

- 샤딩은 PoS 형태의 샤드체인을 운영하는 방법으로 구현됩니다.
- 샤드체인에 대한 신뢰는 메인체인에 의존적입니다.
- 현재는 PoW체인이 샤드체인에 대한 메인체인입니다.
- 하지만 샤드체인에 대한 메인체인을 비콘체인으로 부르는 PoS체인으로 변경하는 것을 목표로 합니다.
- 아래에는 이를 구현하기 위한 스펙과 알고리즘 등이 설명되어 있습니다.

***


# Full casper chain v2

이 문서는 캐스퍼와 샤딩을 결합한 체인, 즉 이더리움 버전2의 상세 스펙을 기술하는 문서로 계속 작업중인 문서입니다. 이더리움의 PoW 체인을 중앙체인(Central chain)으로 삼아 PoW에 과도하게 의존적인 기존의 버전과는 다르게, 이 상세스펙은 RANDAO 비콘체인과 Casper FFG 메커니즘 그리고 증언과정을 기반으로하는 완전한 PoS 체인을 중앙체인으로 삼고, PoW체인과는 블록참조(block reference)와 일방성 예탁(deposit) 통해 상대적으로 단순하게 연결되어 있습니다.

## Broad description of structure

메인 PoS체인(Central PoS chain)은 현재의 활성화된 검증인(Validator)들의 집합을 관리하고 저장하는 일을 합니다. 현재까지는, 검증인이 는 방법으로 32이더를 담고 있는 트랜잭션을 기존의 PoW체인으로 전송하는 방법이 있습니다. 그 이후 PoS체인이 해당 트랜잭션이 포함된 블록을 다루게 되면 검증인으로 대기하게 되고 곧 이어 활성화된 검증인 명단에 들어가게 됩니다. 활성화된 검증인에서는 로그아웃 시 빠져나올 수 있고, 강제로 종료되었을 경우에는 페널티를 받게 됩니다.


PoS체인의 로드는 주로 샤드체인과 메인 PoS체인을 연결하기 위한 크로스링크(cross-link)로부터 발생합니다. 크로스링크란 "여기 Shard X에 새로운 블록들의 해쉬값이야"를 의미하는 특정한 타입의 트랜잭션입니다. 이 트랜잭션은 페이로드 중 하나로 이 트랜잭션이 올바름을 검증해주는 서명을 무작위로 선정된 M명의 검증인들로부터 3분의 2이상 획득하여 포함해야 합니다. 모든 샤드는 각각 PoS체인이고 또한 샤드체인은 트랜잭션과 계정이 저장되는 곳입니다. 크로스링크는 샤드 체인의 분할들을 메인 체인에 확정("confirm")하는 것에 사용됩니다. 또한 크로스링크는 샤드간 통신을 위한 주된 방법입니다.

> NOTE: 파이썬 코드는 현재 https://github.com/ethereum/beacon_chain 에서 구현중입니다. 아직(18.06.26 기준) 현 문서는 대부분 반영되지 않음.

# Terminology

- **검증인(Validator)** - 캐스퍼/샤딩 합의 시스템에서의 참가자. 32이더를 캐스퍼 메커니즘에 예탁하면 검증인이 될 수 있음.
- **활성 검증인 집합(Active validator set)** - 활성 검증인들은 현재 캐스퍼 메커니즘이 블록과 크로스링크 및 기타 합의 대상들에 대해 확인하고 블록을 생산하여 체인을 유지하도록 하는 참가자들입니다.
- **공증인(Notary)** - 크로스 링크에 서명을 제공하는 사람입니다.
- **위원회(Committee)** - 활성 검증인 집합에서 중 무작위로(pseudorandomly) 추출한 부분집합입니다. 특정 블록이 올바르다는 서명을 제공하는 집단입니다. 위원회가 "X에 대해 위원회가 증명함"과 같이 사용될 때는 위원회의 부분집합이 충분한 검증인을 포함해야 하며, 이는 캐스퍼v2 프로토콜이 해당 위원회를 대표한다고 인식할 수 있을 만큼이 되어야 합니다.
- **제안자(Proposer)** - 검증인 중 새로운 블록을 생성한 사람.
- **증인(Attester)** - 증언을 수행할 위원회에 소속된 검증인으로, 블록이 올바른지 확인하여 서명을 제공합니다.
- **비콘체인(Beacon chain)** - 중앙 PoS체인으로 샤딩시스템의 기반입니다.
- **샤드체인(Shard chain)** - 트랜잭션과 계정 데이터가 저장되는 체인들입니다.
- **메인체인(Main chain)** - 현재는 PoW체인을 의미하며 곧 비콘체인이 메인체인이 될 것입니다.
- **크로스링크(Cross-link)** - 샤드 체인의 블록에 대해서 위원회가 증언한 서명들의 집합으로 비콘체인에 포함되는 트랜잭션들입니다. 크로스링크는 주로 비콘 체인이 샤드체인에서 어떤일이 일어났는지 알게 해주는 것에 사용됩니다.
- **에폭(Epoch)** - 100개 블록의 집합.
- **완결(Finalized)** - [캐스퍼 FFG에서의 완결성]( https://arxiv.org/abs/1710.09437)에 대해서 확인하세요.
- **SHARD_COUNT** - 총 샤드 개수, 현재 값은 1024.
- **NOTARIES_PER_CROSSLINK** - 크로스 링크를 검증하기 위해 필요한 공증인의 숫자. 현재 값은 1024.

## Main chain changes

이 PoS/샤딩 제안은 메인체인과 별개로 구현될 수 있습니다. 메인체인에서 바꿔야 하는 것은 단 두 개입니다(두번째 것은 기술적으로 굳이 필요하지는 않음).

- 메인체인에 컨트랙트가 추가됨. 이 컨트랙트는 32 이더를 예탁할 수 있도록 함. 예탁함수는 (i)`pubkey` (bytes) (ii)`withdrawal_shard_id` (int), (iii) `withdrawal_addr` (address), (iv) `randao_commitment` (bytes32) 를 매개변수로 받음

- 메인 체인 클라이언트는 `prioritize(block_hash, value)` 메소드를 지녀야 함. 블록이 접근가능하고 검증되어있는 상태라면 이 메소드는 주어진 값에 대해 스코어를 산정하고 자손 블록들에 대해서 스코어를 조정한다. 이 것은 PoS 비콘체인의 Finality Gadget이 암묵적으로 메인체인 블록을 완결할 수 있도록 해줌.

## Beacon chain

비콘 체인은 PoS 시스템에서의 "메인체인"입니다. 비콘체인의 핵심 역할은:

- 활성, 대기, 종료한 검증인 집합을 저장하고 관리하는 것
- 크로스링크(Cross-link)를 처리하는 것
- FFG 가젯과 더불어, Block-by-block 합의 알고리즘을 처리하는 것.

모든 비콘체인 블록은 다음 필드를 가집니다.

```.python
fields = {
    'parent_hash': 'hash32', # Hash of the parent block
    'skip_count': 'int64', # Number of skips (for the full PoS mechanism)
    'randao_reveal': 'hash32', # Randao commitment reveal
    'attestation_bitfield': 'bytes', # Bitfield of who from the attestation committee participated
    'attestation_aggregate_sig': ['int256'], # Their aggregate sig
    'shard_aggregate_votes': [AggregateVote], # Shard aggregate votes
    'main_chain_ref': 'hash32', # Reference to main chain block
    'state_hash': 'bytes', # Hash of the state
    'sig': ['int256'] # Signature from proposer
}
```
비콘 체인의 상태는 두 개 요소로 나뉘어집니다. 하나는 결정화된 상태(Crystallized state)이고 다른 하나는 활성 상태(active state)입니다. 활성 상태는 매 블록마다 바뀌지만, 결정화된 상태는 에폭(Epoch, 100blocks)마다 변경됩니다.

다음은 활성 상태로 다음 필드를 가집니다.

```.python
fields = {
    'height': 'int64', # Block height
    'randao': 'hash32', # Global RANDAO beacon state
    'ffg_voter_bitfield': 'bytes', # Which validators have made FFG votes this epoch (as bitfield)
    'recent_attesters': ['int24'], # Block attesters in the last epoch
    'partial_crosslinks': [PartialCrosslinkRecord], # Storing data about crosslinks-in-progress in this epoch
    'total_skip_count': 'int64', # Total number of skips (used to determine minimum timestamp)
    'recent_proposers': [RecentProposerRecord] # Block proposers in the last epoch
}
```

`PartialCrosslinkRecord`는 이번 에폭에 포함된 크로스링크에 대한 정보가 한데 담겨있는 객체로 다음 필드를 가집니다.

```.python
fields = {
    'shard_id': 'int16', # What shard is the crosslink being made for
    'shard_block_hash': 'hash32', # Hash of the block
    'voter_bitfield': 'bytes' # Which of the eligible voters are voting for it (as bitfield)
}
```

`RecentProposerRecord`는 최근의 블록 제안자(Prosper)들을 기록하는 객체로 다음 필드를 가집니다.

```.python
fields = {
    'index': 'int24', # Proposer index
    'randao_commitment': 'hash32', # New RANDAO commitment
    'balance_delta': 'int24' # Balance delta
}
```

그리고 다음은 결정화된 상태로 다음 필드를 가집니다.

```.python
fields = {
    'active_validators': [ValidatorRecord], # List of active validators
    'queued_validators': [ValidatorRecord], # List of joined but not yet inducted validators
    'exited_validators': [ValidatorRecord], # List of removed validators pending withdrawal
    'current_shuffling': ['int24'], # The permutation of validators used to determine who cross-links what shard in this epoch
    'current_epoch': 'int64', # The current epoch
    'last_justified_epoch': 'int64', # The last justified epoch
    'last_finalized_epoch': 'int64', # The last finalized epoch
    'dynasty': 'int64', # The current dynasty
    'next_shard': 'int16', # The next shard that cross-linking assignment will start from
    'current_checkpoint': 'hash32', # The current FFG checkpoint
    'crosslink_records': [CrosslinkRecord], # Records about the most recent crosslink for each shard
    'total_deposits': 'int256', # Total balance of deposits
    'crosslink_seed': 'hash32', # Used to select the committees for each shard
    'crosslink_seed_last_reset': 'int64' # Last epoch the crosslink seed was reset
}
```

`ValidatorRecord`는 검증인(Validator)의 정보를 포함하는 객체로 다음 필드를 가집니다.

```.python
fields = {
    'pubkey': 'int256', # The validator's public key
    'withdrawal_shard': 'int16', # What shard the validator's balance will be sent to after withdrawal
    'withdrawal_address': 'address', # And what address
    'randao_commitment': 'hash32', # The validator's current RANDAO beacon commitment
    'balance': 'int64', # Current balance
    'switch_dynasty': 'int64' # Dynasty where the validator can (be inducted | be removed | withdraw their balance)
}
```

`CrosslinkRecord`는 가장 최근에 생성되어 메인체인에 제출될 크로스 링크의 정보를 포함하는 객체로 다음 필드를 가집니다.

```.python
fields = {
    'epoch': 'int64', # What epoch the crosslink was submitted in
    'hash': 'hash32' # The block hash
}
```

루트 상태는 `blake(serialize(crystallized_state))`와 `blake(serialize(active_state))`의 통합과 같습니다. 이는 거의 항상, 결정화된 상태(crystallized state)가 바뀌지 않고, 다시 해쉬될 필요가 없다는 것을 의미합니다. 일반적으로, 활성 상태(active state)는 상대적으로 작은 크기를 가집니다(예를 들면 4백만명의 검증인의 경우 1MB이하입니다. 현실적으로는 100kb 이하가 될 것입니다). 또한 결정화된 상태는 크고 약 10MB에 이릅니다.

## Beacon chain processing

비콘 체인을 처리하는 것은 기본적으로 PoW 체인을 처리하는 방법과 많은 츨면에서 유사합니다. 클라이언트는 블록들을 다운로드하고 처리하며, 어떤 체인이 "캐노니컬 체인(canonical chain)"인지 확인합니다. 하지만 비콘체인이 기존 PoW체인과 가지는 관계와, 또 비콘체인이 PoS체인인 것으로 인해, 몇가지 다른점이 존재합니다.

먼저, 비콘 체인에서의 블록은 노드에 의해 처리되며 블록 처리를 위해서는 다음 세 가지 조건이 만족되어야 합니다.

- `parent-hash`에 의해 가리켜진 부모 블록이 이미 처리되고 기록되었어야(proccessed and accepted) 합니다.
- `main_chain_ref`에 의해 가리켜진 메인 체인 블록이 이미 처리되고 기록되었어야(proccessed and accepted) 합니다.
- 노드의 로컬 시계가 `GENESIS_TIME + height * PER_HEIGHT_DELAY + total_skips * PER_SKIP_DELAY`으로 계산된 값보다 같거나 커야 합니다.

만약 다음 세가지 조건을 만족하지 못하면 클라이언트는 블록처리를 이 조건들이 만족될 때까지 기다리게 됩니다.

블록의 생성과정은 PoS 메커니즘에 의해 PoW와 확연하게 다릅니다. 매번 클라이언트는 헤드를 바꾸게 되고 (아래의 fork choice rule에서 헤드가 어떻게 결정되는지 참조), 블록의 제안자들이 0에서 M(적당하게 큰 숫자)까지의 `skip_count`를 가지도록 계산을 수행합니다. `i`를 선택된 클라이언트의 `skip_count`로 한다면, `timestamp`가 `minimum_timestamp(head) + PER_HEIGHT_DELAY + i * PER_SKIP_DELAY`에 다다를때, 그리고 헤드가 아직 바뀌지 않았을 때, 이 때 클라이언트는 새로운 블록을 발행하게 됩니다.

클라이언트가 헤드를 바꿀 때는 증인들(attesters, 서명을 제공하는 검증인들)의 리스트를 다시 계산합니다. 그리고 즉시 증인에 해당할 경우, 즉시 해당 블록에 대한 부모 블록과 개인키를 활용하여 서명을 만들어 증명을 발행합니다.

## Beacon chain fork choice rule

비콘 체인이 독자적인 PoS가 되면, 포크 선택 규칙은 *highest-scoring-block* 규칙을 따르게 됩니다. 이 것은 Casper FFG의 스코어 정책과 같습니다.

```
score = last_justified_epoch + height * ε
```

비콘 체인이 PoW 체인을 따라가며 구현되지만, 포크 선택 규칙은 독립적입니다. 비콘 체인에서는 가장 높은 점수를 가지는 메인체인을 `main_chain_ref`로 가리키고 있고 비콘 체인 블록 중에서 가장 높은 점수를 가지고 있는 블록이 바로 헤드가 됩니다.

`main_chain_ref`가 부모 블록과 자손 블록 간 같은지 확인해야 하는 추가적인 검증 조건이 추가되었기 때문에, 비콘 체인 상 블록들의 *모든* `main_chain_ref`들이 메인체인 상(가장 점수가 높은)에 존재한다는 것을 알 수 있습니다. 이로써 비콘 체인이 실제 캐노니컬 메인 체인(현재는 PoW)과 연결되어 있는 것을 확실하게 해줍니다.

> 가장 높은 점수의 메인체인(highest-scoring main chain)이 곧 캐노니컬 메인 체인(canonical main chain)이라고 이해하면 됩니다.

포크를 선택하는 것을 다음 알고리즘들을 통해 "온라인으로 업데이트"가 가능해야 합니다. 먼저, 메인 체인과 비콘 체인의 헤드 뿐만 아니라 모든 층의 블록을 계속하여 추적하는 것이 중요합니다. 매 헤드의 변경마다 실행되는 다음 알고리즘으로 이 것이 유지될 수 있습니다.

```.python
def update_head(chain, old_head, new_head):
    a, b = old_head, new_head
    while a.height > b.height:
        a = get_parent(a)
    while b.height > a.height:
        b = get_parent(b)
    while a != b:
        a, b = get_parent(a), get_parent(b)
    b = new_head
    new_chain = []
    while b.height > a.height:
        new_chain = [b] + new_chain
        b = get_parent(b)
    chain = chain[:a.height + 1] + new_chain
```

새로운 비콘 체인 블록을 받으면, 그 점수가 현재 헤드의 점수를 넘을 때 그리고 새로 받은 블록의 `main_chain_ref`가 메인 체인에 존재할 때 헤드를 변경합니다. 코드는 다음과 같습니다.

```.python
def should_I_change_head(main_chain, old_beacon_head, new_beacon_block):
    return get_score(new_beacon_block) > get_score(old_beacon_head) and \
        new_beacon_block.main_chain_ref in main_chain
```

메인 체인이 재구성되면 비콘체인도 재구성됩니다. 코드는 다음과 같습니다.

```.python
def reorg_beacon_chain(main_chain, beacon_chain):
    old_head = beacon_chain[-1]
    while beacon_chain[-1].main_chain_ref not in main_chain:
        beacon_chain.pop()
    queue = [beacon_chain[-1]]
    new_head = beacon_chain[-1]
    while len(queue) > 0:
        b = queue.pop(0)
        for c in get_children(b):
            if c.main_chain_ref in main_chain:
                if get_score(c) > get_score(new_head):
                    new_head = c
                queue.append(c)
    update_head(beacon_chain, old_head, new_head)
```

## Beacon chain state transition function

이제 상태 변경 함수에 대해 정의합니다. 추상적 레벨에서 상태 변경은 두 부분으로 구성되어 있습니다.

1. 에폭 상태변경(The epoch transition)은 `active_state.height % SHARD_COUNT == 0`의 조건에서만 발생합니다. 그리고 결정화된 상태(crystallized state)와 활성상태(active state)를 모두 변경합니다.
1. 블록당 처리(The per-block processing)은 모든 블록마다 진행되고 활성상태에만 영향을 끼칩니다. 에폭 상태변경(The epoch transition)이 진행되는 블록이라면 에폭 상태변경 이후에 처리됩니다.

에폭 상태변경(The epoch transition)은 일반적으로 검증인 집합을 변경하는 것에 초점을 둡니다. 또한 계좌의 잔고를 조정하고 검증인을 추가하고 제거하고 크로스 링크를 처리하고 FFG 체크포인트를 설정하는 것도 진행합니다. 블록당처리(per-block processing)는 일반적으로 활성 상태에서 블록내활동(in-block activity)과 관련된 임시적인 기록들을 기록하는 것에 초점을 두고 있습니다.

### Helper functions

몇 가지 보조 알고리즘을 정의하면서 시작해보겠습니다. 먼저, 검증인 집합을 어떤 `seed`에 따라 유사난수적으로 섞는(shuffling) 알고리즘입니다.

```.python
def get_shuffling(seed, validator_count):
    assert validator_count <= 16777216
    rand_max = 16777216 - 16777216 % validator_count
    o = list(range(validator_count)); source = seed
    i = 0
    while i < validator_count:
        source = blake(source)
        for pos in range(0, 30, 3):
            m = int.from_bytes(source[pos:pos+3], 'big')
            remaining = validator_count - i
            if remaining == 0:
                break
            if validator_count < rand_max:
                replacement_pos = (m % remaining) + i
                o[i], o[replacement_pos] = o[replacement_pos], o[i]
                i += 1
    return o
```

다음 알고리즘은 샤드 위원회를 선택하고 블록 제안자(prosper)들과 증인(attester)들을 선택하는 것에 사용되는 알고리즘입니다. 주어진 블록에 대해 증인을 선택하고 그 블록의 N-skip 된 블록 제안자를 선정하는 응용입니다.

```.python
def get_attesters_and_proposer(crystallized_state, active_state, skip_count):
    attestation_count = min(len(crystallized_state.active_validators), ATTESTER_COUNT)
    indices = get_shuffling(active_state.randao, len(crystallized_state.active_validators))
    return indices[:attestation_count], indices[attestation_count + skip_count]
```

샤드의 크로스링크를 위한 절차는 조금 더 복잡합니다. 먼저, 각 에폭(epoch)마다 활성화되었던 샤드의 집합을 선택합니다. 우리는 크로스 링크마다 고정된 수의 공증인이 존재하기를 바라는데, 이 때 샤드의 수와 검증인들의 수가 맞지 않을 경우가 발생할 수 있고, 모든 샤드를 처리하지 못하는 에폭이 있을 수 있습니다. 따라서, 각 에폭마다 어떤 샤드를 크로스링킹 할 것인지에 대해 선택해야 합니다.

```.python
def get_crosslink_shards(crystallized_state):
    start_from = crystallized_state.next_shard
    count = len(crystallized_state.active_validators) // NOTARIES_PER_CROSSLINK
    if start_from + count <= SHARD_COUNT:
        return list(range(s, s+count))
    else:
        return list(range(start_from, SHARD_COUNT)) + list(range(start_from + count - SHARD_COUNT))
```

그리고 샤드를 위한 공증인 집합을 계산합니다.

```.python
def get_crosslink_notaries(crystallized_state, shard_id):
    crosslink_shards = get_crosslink_shards(crystallized_state)
    if shard_id not in crosslink_shards:
        return None
    all = len(crystallized_state.current_shuffling)
    start = all * crosslink_shards.index(shard_id) // len(crosslink_shards)
    end = all * (crosslink_shards.index(shard_id)+1) // len(crosslink_shards)
    return crystallized_state.current_shuffling[start: end]
```

`current_shuffling`은 다이너스티 변경(dynasty transition, 아래 항목 참조)마다 새롭게 계산됩니다.

## Per-block processing

블록당 처리(per-block processing)은 세 부분으로 구성됩니다.

### Checking attestation signatures

블록당 기대되는 증인들의 숫자는 대략 `min(len(crystallized_state.active_validators), ATTESTER_COUNT)`입니다. 이 값을 `attester_count`라고 두겠습니다. 증인의 `attestation_bitfield`는 `(attester_count + 7) // 8`의 길이를 가지는 바이트 배열인데, 이 것은 좌에서 우로 향하는 비트리스트라고 보면 됩니다(예를 들면 bit 0은 `attestation_bitfield[0] >> 7`이고 bit 9는 `attestation_bitfield[1] >> 6 입니다`). `attester_count - 1`의 모든 비트는 0입니다. 그리고 증인의 총 수(즉, 1 비트값들의 총 수)는 최소 `attester_count / (2 + block.skip_count)`입니다.

`bitfield`의 1 비트들은 `get_attesters_and_prospers()`를 통해 추출한 증인들의 하위 집합입니다. 증인들의 인덱스들을 추출하고 그것으로 `crystallized_state.active_validators` 로부터 공개 키들을 가져옵니다. 그리고 이 공개 키들을 키집합(aggregate key)에 추가합니다. BLS는 블록상에서 키집합을 공개키로 사용하는 `attestation_aggregate_sig`를 검증하고, 부모 블록을 직렬화시켜 메세지를 만듭니다. 검증이 통과되는 것을 확실히 해야 합니다.

`recent_prospers` 리스트는 블록제안자(prosper)들의 인덱스와 블록제안자의 RANDAO Preimage, 서명을 포함한 증인들의 수를 포함하고 있습니다. `recent_proposers` 리스트에 `ProsperRecord`를 더합니다. 그리고 증인들의 인덱스(bitfield index)를 `recent_attesters`에 더해줍니다.

### Checking partial crosslink records

블록은 0 혹은 그 이상의 `AggregateVote` 객체를 지닐 수 있습니다. `AggregateVote` 객체는 다음 필드를 가지고 있습니다.

```.python
fields = {
    'shard_id': 'int16',
    'shard_block_hash': 'hash32',
    'notary_bitfield': 'bytes',
    'aggregate_sig': ['int256']
}
```

그리고 여기에 포함된 모든 투표들은

- `get_shard_attesters`를 사용하여 크로스링크 증인들의 인덱스 리스트를 받아옵니다. 블록 증인들이 하는 것처럼 증인들의 서명을 공증인의 bitfield를 통해 검증합니다.
- 만일 같은 샤드 ID와 해쉬에 `PartialCrosslinkRecord` 객체가 이미 존재한다면 `AggregateVote`에 참여한 검증인들(voter_bitfield |= AggregateVote.notary_bitfield)의 로컬 인덱스를 `voter_bitfield`에 추가합니다. 아직 `PartialCrosslinkRecord`가 추가되지 않았다면 새로 만들어 넣습니다.
- 또한, 투표자들의 인덱스를 `active_state.ffg_voter_bitfield`에도 추가해줍니다.
- 만일, 아직 투표를 진행하지 않은 n명의 투표자가 있다면, 블록 제안자에게 n만큼 보상으로 지급하고 잔고를 차이를 기록합니다
- `shard_block_hash`의 순서로 정렬된 `PartialCrosslinkRecord`의 새로운 리스트를 저장합니다.

### Miscellaneous

- 블록 height를 1씩 증가시킵니다.
- 서명집합이 모두 0바이트로 설정된 블록을 사용하거, 서명을 블록 상에서 검증합니다.
- 총 skip count를 블록의 skip count에 따라서 늘려나갑니다.
- 블록의 RANDAO reveal이 블록제안자의 저장된 RANDAO 커밋 이미지의 해쉬값과 일치하는지 검증합니다. 활성 RANDAO 상태(active RANDAO state)에 블록의 RANDAO reveal값을 배타논리합을 시키고, 블록의 RANDAO reveal값으 블록제안자의 새 커밋으로 정합니다.
Increase the total skip count by the block’s skip count

## Epoch transitions

현재 블록 높이를 `SHARD_COUNT`로 나눈 나머지가 0일 경우, 에폭 변환(epoch transition)을 실행합니다. 에폭 변환은 다음 몇가지 부분으로 나뉩니다.

### Calculate rewards for FFG votes
- 활성 상태(active state)상의 FFT voter bitfeild에 따라, 마지막 에폭에 참가한 모든 검증인들의 잔고를 계산합니다. 만약 이 값이 모든 검증인의 잔고의 3분의 2보다 크거나 같으면 `crystallized_state.justified_epoch`를 `crystallized_state.current_epoch`와 같도록 설정합니다. 이 때, 기존의 justified 에폭이 `crystallized_state.current_epoch -1`와 같았다면, 그 값을 `crystallized_state.finalized_epoch`으로 설정합니다.

  > current epoch -> justified epoch -> finalized epoch

- Casper FFG 인센티브와 *quadratic leak rules* 에 따라, `online_reward`를 계산하고 `offline_penalty`를  계산합니다. (아직 완벽하게 명시되지 않음)

- `online_reward` 를 마지막 에폭에 참여한 모든 검다증인에게 제공하고 `offline_penalty`를 참여하지 않은 검증인으로부터 차감합니다.



## Calculate rewards for crosslinks

다음을 모든 샤드에 대해서 반복합니다.

- 크로스링크에 대한 `online_reward`와 `offline_penalty`를  계산
- 가장 많은 투표(체크포인트 해쉬에 따라 정렬함)를 받은 파셜 크로스링크(partial crosslink)를 취합니다. 해당 크로스링크에 참여한 검증인들을 보상하고 그렇지 않은 검증인들에게는 페널티를 부과합니다.
- 현재 에폭에서의 잔고 변경은 반영하지 않은 상태로 계산하였을 때, 총 잔고의 3분의 2 이상의 투표를 획득하는 크로스 링크가 있으면 그 것을 가장 최근의 크로스 링크로 저장합니다.

## Process balance deltas

`recent_attesters`에 포함된 모든 증인들의 잔고를 1 추가합니다. `recent_prospers`에 포함된 모든 블록생성자의 잔고를 `RecentProposerRecord` 객체의 `balance_delta` 만큼 증가시킵니다.

## Crosslink seed-related calculations

만약, `current_epoch - crosslink_seed_last_reset`가 2의 제곱수라면, `temp_seed = blake(crosslink_seed + bytes([log2(current_epoch - crosslink_seed_last_reset)]))`를 사용하여 현재 셔플을 다음과 같이 정합니다 `current_shuffling = get_shuffling(temp_seed, len(new_active_validators))`. 모든 임시 위원회는 `crosslink_seed`를 통해 예측가능하지만 포지셔닝이 기하급수적으로 늘어납니다.

이러한 지수적인 백오프는 N개의 에폭들에 대해 크로스링크가 없을 경우, 그 다음 위원회가 ~N/2 에폭을 처리하여 해당 샤드의 ~N개의 에폭의 기록을 검증할 수 있으므로, 위원회가 수행해야 하는 초당 작업량이 제한되게 됩니다.

## Dynasty transition

다음 두 가지 조건을 모두 만족한다면,

- 마지막 두 에폭이 모두 justified되었을 때
- 모든 샤드들에 대해 가장 최근에 기록된 crosslink의 높이(height)가 `crosslink_seed_last_reset`보다 같거나 클 때

다음이 수행됩니다.

- Set `crystallized_state.dynasty += 1`
- Set `crosslink_seed = active_state.randao`
- 대기중인 검증자를 확인하여 `switch_dynasty`값이 새 다이너스티보다 같거나 빠르면, `active_validators`의 맨 뒤에 추가합니다. 최대 `(len(crystallized_state.active_validators) // 30) + 1`까지 추가합니다. `queued_validators`는 정렬되어 있기 때문에, `switch_dynasty` 값이 현재보다 클때까지만 검색해도 충분합니다.
- 모든 활성 검증자들을 확인하고 (i) 잔고가 50% 최초 잔고의 이하이거나  (ii)`switch_dynasty`가 새 다이너스티 값과 작거나 같은면 `exited_validators`로 이동시킵니다. 최대 `(len(crystallized_state.active_validators) // 30) + 1` 만큼 이동시킵니다.

## Miscellaneous

- 현재 에폭을 증가시킵니다.
- `current_checkpoint`를 기존 블록의 해쉬로 설정합니다.
- balance detlas 값과 FFG 투표자, 파셜 크로스링크 (partial crosslink) 리스트를 초기화 시킵니다.
- 활성 검증자들의 RANDAO 커밋을 `RecentProposerRecord`값에 따라서 업데이트 합니다.
