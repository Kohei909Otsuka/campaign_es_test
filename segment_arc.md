# 期間との関連性

- 期間関係なし(実際には期間でfilterすることが計算上できるが,仕様として期間関係ないと定義するもの)
  - 初回流入媒体
  - 初回購入日
  - 最終購入日
  - 在籍日数
  - 休眠日数
- 期間関係あり(期間指定が無い場合、全期間)
  - 合計購入回数
  - 購入合計額
  - 購入履歴

- 商品でfilterされるのは、購入履歴のみ


***言葉で表現***

[ProductA, ProductB]の単品のみ購入回数が5回
  => count(あるUserの期間中のOrderでOrderItem#merchandisableがProduct A or Bであるもの) {==/<=/>=} 5
[ProductA, ProductB]の全購入回数が5回
  => count(あるUserの期間中のOrderでOrderItem#variant.productがProduct A or Bであるもの) {==/<=/>=} 5

[CourseA, CourseB]の購入回数が5回
  => count(あるUserの期間中のOrderでOrderItem#merchandisableがCourseA  or Bであるもの) {==/<=/>=} 5
[CourseA, CourseB]の継続回数が5回のものが存在する
  => exsist?(あるUserの期間中のCourseOrderでCourseOrderItem#courseがCourseA  or Bであるものでかつ、継続回数が5回のもの)
[CourseA, CourseB]の定期注文statusが:activeのものが存在する
  => exsist?(あるUserの期間中のCourseOrderでCourseOrderItem#courseがCourseA  or Bであるものでかつ、statusが:activeもの)

# nestedとparent-childの違い

- nested
  - documentは常にroot document単位で扱う(search, add, remove...etc)
  - nested aggsと reverse-nested aggs の両方がsupportされる。
- parent-child
  - documentはparentとchildで別々に扱う(search, add, remove...etc)
  - parentとchildは同じshardにいる
  - child aggはできるが、parent aggはsupportされない。


tamagoの定期回数は、最新定期回数で大なり小なりがあればカバーできるので消す。

# 方針

前提ElasticSearchは集計した値を基に、documentをfilterすることができない
=> ので、他の方法を探さないと...


ElasticSearchにupdateという概念は基本的にない(update endpointが内部でやっていることはただのreindexでHTTP requestが一回減るだけ)。
ので、nestedの中に追加をしようとするといっかいGETでfetchしてきて、現在のnestedの中野状態をする必要がある。これだけHTTP requestが増えるのは痛い。

であれば、parent-childにしてしまって、親に対して追加、親に対して削除。をしたほうがいい。

***最初のidea: segmentの下にnestedでsegment_gruop_boolsを設ける。***
```
"mappings": {
  "user": {
    "properties": {
      "id": {"type": "integer"},
    }
  },
  "segment": {
    "_parent": {
      "type": "user"
    },
    "properties": {
      "id": {"type": "integer"}
      "segment_group_bools": {
        "type": "nested",
        "properties": {
          "id": {"type": "integer"}
          "match": {"type": "boolean"}
        }
      }
    }
  }
}
```

***次のidea: segmentの下にparent-childeでsegment_gruop_boolsを設ける。***

user typeの_id: user_id
segment typeの_id: "#{user_id}_#{segment_id}"
segment_groupの_id: "#{user_id}_#{segment_id}-#{segment_group_id}"

- 前提
  - user分だけdocがある
  - user * segment分だけdocがある
  - user * segment * segment_group分だけdocがある(全false)
- 処理
  - segment_group_idをputする指定true

```
"mappings": {
  "user": {
    "dynamic": "strict",
    "properties": {
      "id": {"type": "integer"}
    }
  },
  "segment": {
    "dynamic": "strict",
    "_parent": {
      "type": "user"
    },
    "properties": {
      "id": {"type": "integer"}
    }
  },
  "segment_group_bool": {
    "dynamic": "strict",
    "_parent": {
      "type": "segment"
    },
    "properties": {
      "id": {"type": "integer"},
      "match": {"type": "boolean"}
    }
  }
}
```


# 想定するロジック

- cal phase
  - for SegmentGroups
    - find users who meets the SegmentGroup
    - batch indexing on user index
- query phase
  - build query based on formula
  - find users on user index, who meets the query

## Cal Phase

### SegementGroup{kind: user}
問い合せるindex: user

### SegementGroup{kind: product_purchase}
問い合せるindex: order

### SegementGroup{kind: course_purchase}
問い合せるindex: course_order

### SegementGroup{kind: aggregate}
問い合せるindex: order

## Query Phase

Segment#formulaをpaseして、boolean queryへ書き換えて問い合わせ、User#idを取得する。
