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

# parent_child

## mapping

# nested

## mapping

## memo

tamagoの定期回数は、最新定期回数で大なり小なりがあればカバーできるので消す。
