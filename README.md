# what is this

Segment機能を作る前に、実験をしていたrepositoryになります。
サブスクストアとは完全に独立していて、かつシンプルになっているので、セグメント機能の動作イメージ
を掴むのに良いです。

# 手順

``` shell
# elastic search のscriptをenable
# Caused by: ScriptException[scripts of type [inline], operation [aggs] and lang [groovy] are disabled]
https://discuss.elastic.co/t/scripts-of-type-inline-operation-aggs-and-lang-groovy-are-disabled/2493/2

# install dependency

bundle install --path vendor/bundler/

# create ElasticSearch index
bundle exec ruby create_index.rb

# indexができていることの確認
curl localhost:9200/_cat/indices?v

health status index             pri rep docs.count docs.deleted store.size pri.store.size
yellow open   test_user           5   1          0            0       130b           130b
yellow open   test_course_order   5   1          0            0       260b           260b
yellow open   test_summary        5   1          0            0       260b           260b
yellow open   test_order          5   1          0            0       260b           260b

# index document on index
bundle exec ruby index_doc.rb

# documentが入っていることの確認(test_summary以外のdocs.countが増えてる)
curl localhost:9200/_cat/indices?v

health status index             pri rep docs.count docs.deleted store.size pri.store.size
yellow open   test_user           5   1        100            0     31.2kb         31.2kb
yellow open   test_course_order   5   1        200            0     46.2kb         46.2kb
yellow open   test_summary        5   1          0            0       795b           795b
yellow open   test_order          5   1       1000            0    211.8kb        211.8kb

# cal phase
bundle exec ruby cal_phase.rb

# test_summary　indexにdocumentが入ったことを確認
curl localhost:9200/_cat/indices?v

health status index             pri rep docs.count docs.deleted store.size pri.store.size
yellow open   test_user           5   1        100            0     31.2kb         31.2kb
yellow open   test_course_order   5   1        200            0     46.2kb         46.2kb
yellow open   test_summary        5   1        306            0     29.2kb         29.2kb
yellow open   test_order          5   1       1000            0    211.8kb        211.8kb


# query phase
bundle exec ruby query_phase.rb
```
