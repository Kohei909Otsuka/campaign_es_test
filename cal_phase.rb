require "elasticsearch"
require "json"
require "pry"
require_relative "lib"

def segment_group_query user_ids, segment_id,
  segment_group_id

  segment_groups = []
  user_ids.each do |user_id|
    meta = {
      index: {
        _index: "test_summary",
        _type: "segment_group",
        _parent: "#{user_id}_#{segment_id}",
        _id: "#{user_id}_#{segment_id}_#{segment_group_id}"
      }
    }
    data = {
     id: segment_group_id,
     match: true
    }
    segment_groups << meta
    segment_groups << data
  end
  return segment_groups
end

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
  "size": 1000,
  "query": {
    "bool": {
      "filter": {
        "bool": {
          "must": [
            { "range": {"age": {"gte": 20}}},
            { "range": {"age": {"lte": 29}}},
            { "terms": {"state_id": [1,2]}}
          ]
        }
      }
    }
  }
}'

r = client.search index: "test_user", type: "user",
  body: JSON.parse(query, {:symbolize_names => true})


user_ids = Lib.to_ids r
query = segment_group_query user_ids, 1, 1

client.bulk body: query

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

query1 = '{
  "size": 1000,
  "query": {
    "bool": {
      "filter": {
        "bool": {
          "must": [
            { "range": {"age": {"gte": 20}}},
            { "range": {"age": {"lte": 29}}},
            { "terms": {"state_id": [1,2]}}
          ]
        }
      }
    }
  }
}'
query2 = '{
  "size": 0,
  "aggs": {
    "by_user_id": {
      "terms": {
        "field": "user_id",
        "size": 1000
      },
      "aggs": {
        "ltv": {
          "sum": {
            "field": "total"
          }
        },
        "ltv_bucket_filter": {
          "bucket_selector": {
            "buckets_path": {
              "LTV": "ltv",
              "count": "_count"
            },
            "script": "LTV > 50000 && count >= 10"
          }
        }
      }
    }
  }
}'

r1 = client.search index: "test_user", type: "user",
  body: JSON.parse(query1, {:symbolize_names => true})
binding.pry
r2 = client.search index: "test_order", type: "order",
  body: JSON.parse(query2, {:symbolize_names => true})
binding.pry

user_ids_1 = Lib.to_ids r1
user_ids_2 = Lib.backet_to_ids r2
query_1 = segment_group_query user_ids_1, 2, 2
binding.pry
query_2 = segment_group_query user_ids_2, 2, 3
binding.pry

client.bulk body: query_1
client.bulk body: query_2
