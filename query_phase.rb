require "elasticsearch"
require "json"
require "pry"
require_relative "lib"

client = Elasticsearch::Client.new log: true
client.transport.reload_connections!

# example 1

# formula = "SegmentGroup{id: 1}"
# Segment{id: 1}
#   SegmentGroup{id: 1, kind: "user", logic: "and"}
#     - age => 20
#     - age <= 29
#     - state in [1,2]

query = '{
  "query": {
    "has_child": {
      "type": "segment_group",
      "query": {
        "bool": {
          "must": [
            {
              "bool": {
                 "must": [
                    {"term": {"id": 1}},
                    {"term": {"match": true}}
                 ]
              }
            }
          ]
        }
      }
    }
  }
}'


r = client.search index: "test_summary", type: "segment",
  body: JSON.parse(query, {:symbolize_names => true}),
  size: 1000

p r["hits"]["hits"].map {|hit| hit["_source"]["user_id"]}

# example 2(日付 2016-01-01 ~ 2019-01-01)
# formula = "SegmentGroup{id: 2} and SegmentGroup{id: 3}"
# Segment{id: 2}
#   SegmentGroup{id: 2, kind: "user", logic: "and"}
#     - age => 20
#     - age <= 29
#     - state in [1,2]
#   SegmentGroup{id: 3, kind: "aggregate", logic: "and"}
#     cumulative_purchase_count  >= 10
#     cumulative_purchase_amount >= 50000

query = '{
  "query": {
    "has_child": {
      "type": "segment_group",
      "query": {
        "bool": {
          "must": [
            {
              "bool": {
                 "must": [
                    {"term": {"id": 2}},
                    {"term": {"match": true}}
                 ]
              }
            },
            {
              "bool": {
                 "must": [
                    {"term": {"id": 3}},
                    {"term": {"match": true}}
                 ]
              }
            }
          ]
        }
      }
    }
  }
}'

r = client.search index: "test_summary", type: "segment",
  body: JSON.parse(query, {:symbolize_names => true}),
  size: 1000

p r["hits"]["hits"].map {|hit| hit["_source"]["user_id"]}
