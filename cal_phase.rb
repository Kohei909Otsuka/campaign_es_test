require "elasticsearch"
require "json"
require "pry"
require_relative "lib"

def container_to_query bulk_container

  user_segment_groups = []
  bulk_container.each do |user_id_str, matched_segment_group_ids|
    user_id = user_id_str.to_i
    matched_segment_groups = matched_segment_group_ids.map do |id|
      {id: id, is_match: true}
    end
    meta = {
      index: {
        _index: "test_summary",
        _type: "user_segment_group",
        _id: user_id
      }
    }
    data = {
      user_id: user_id,
      true_segment_groups: matched_segment_groups
    }
    user_segment_groups.push meta
    user_segment_groups.push data
  end

  return user_segment_groups
end

def push_in_bulk_container bulk_container, user_ids, segment_group_id
  user_ids.each do |user_id|
    key = user_id.to_s
    if bulk_container[key].nil?
      bulk_container[key] = []
    end
    bulk_container[key].push segment_group_id
  end
  return bulk_container
end

client = Elasticsearch::Client.new log: true
client.transport.reload_connections!



# key: User#id
# value: array of matched_segment_group#id
bulk_container = {}

# example 1(no date specified)
# formula = "SegmentGroup{id: 1}"
# Segment{id: 1}
#   SegmentGroup{id: 1, kind: "user", logic: "and"}
#     - age => 20
#     - age <= 29
#     - state in [1,2]

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

r = client.search index: "test_user", type: "user",
  body: JSON.parse(query1, {:symbolize_names => true})


user_ids = Lib.to_ids r

push_in_bulk_container bulk_container, user_ids, 1

# example 2(no date specified)
# formula = "SegmentGroup{id: 2} and SegmentGroup{id: 3}"
# Segment{id: 2}
#   SegmentGroup{id: 2, kind: "user", logic: "and"}
#     - age => 20
#     - age <= 29
#     - state in [1,2]
#   SegmentGroup{id: 3, kind: "aggregate", logic: "and"}
#     cumulative_purchase_count  >= 10
#     cumulative_purchase_amount >= 50000

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
              "COUNT": "_count"
            },
            "script": "LTV > 50000 && COUNT >= 10"
          }
        }
      }
    }
  }
}'

r1 = client.search index: "test_user", type: "user",
  body: JSON.parse(query1, {:symbolize_names => true})
r2 = client.search index: "test_order", type: "order",
  body: JSON.parse(query2, {:symbolize_names => true})

user_ids_1 = Lib.to_ids r1
user_ids_2 = Lib.backet_to_ids r2

push_in_bulk_container bulk_container, user_ids_1, 2
push_in_bulk_container bulk_container, user_ids_2, 3


# example 3(date specified: 2018-04-04 ~ 2018-12-31)
# formula = "SegmentGroup{id: 4} and SegmentGroup{id: 5}"
# Segment{id: 3}
#   SegmentGroup{id: 4, kind: "user", logic: "and"}
#     - age => 20
#     - age <= 29
#     - state in [1,2]
#   SegmentGroup{id: 5, kind: "aggregate", logic: "and"}
#     cumulative_purchase_count  >= 10
#     cumulative_purchase_amount >= 50000

query3 = '{
  "size": 0,
  "query": {
    "range": {
      "ordered_on": {
        "gte": "2018-11-04",
        "lte": "2018-12-31"
      }
    }
  },
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
              "COUNT": "_count"
            },
            "script": "LTV > 50000 && COUNT >= 10"
          }
        }
      }
    }
  }
}'

r1 = client.search index: "test_user", type: "user",
  body: JSON.parse(query1, {:symbolize_names => true})
r2 = client.search index: "test_order", type: "order",
  body: JSON.parse(query3, {:symbolize_names => true})

user_ids_1 = Lib.to_ids r1
user_ids_2 = Lib.backet_to_ids r2

push_in_bulk_container bulk_container, user_ids_1, 4
push_in_bulk_container bulk_container, user_ids_2, 5


# product_purchase SegmentGroup, can't filter by single query
# 単品のみはmissingでqueryすればいける
# example 4(no date specified)
# formula = "(SegmentGroup{id: 6} and SegmentGroup{id: 7}) or SegmentGroup{id: 8}"
# Segment{id: 4}
#   SegmentGroup{id: 6, kind: "user", logic: "and"}
#     - age => 20
#     - age <= 29
#     - state in [1,2]
#   SegmentGroup{id: 7, kind: "aggregate", logic: "and"}
#     cumulative_purchase_count  >= 10
#     cumulative_purchase_amount >= 50000
#   SegmentGroup{id: 8, kind: "product_purchase", logic: "or"}
#     -
#       - product_ids in [1,2]
#       - only_product_purchase_count >= 2
#     -
#       - product_ids in [3]
#       - include_course_purchase_count >= 3

query4_1 = '{
  "size": 0,
  "query": {
    "terms": {
      "product_ids": [
        1,
        2
      ]
    }
  },
  "aggs": {
    "by_product_id": {
      "terms": {
        "field": "product_ids",
        "size": 1000
      },
      "aggs": {
        "by_user_id": {
          "terms": {
            "field": "user_id",
            "size": 100
          },
          "aggs": {
            "purchase_count_filter": {
              "bucket_selector": {
                "buckets_path": {
                  "COUNT": "_count"
                },
                "script": "COUNT >= 2"
              }
            }
          }
        }
      }
    }
  }
}'

query4_2 = '{
  "size": 0,
  "query": {
    "terms": {
      "product_ids": [
        3
      ]
    }
  },
  "aggs": {
    "by_product_id": {
      "terms": {
        "field": "product_ids",
        "size": 1000
      },
      "aggs": {
        "by_user_id": {
          "terms": {
            "field": "user_id",
            "size": 100
          },
          "aggs": {
            "purchase_count_filter": {
              "bucket_selector": {
                "buckets_path": {
                  "COUNT": "_count"
                },
                "script": "COUNT >= 3"
              }
            }
          }
        }
      }
    }
  }
}'

r1 = client.search index: "test_user", type: "user",
  body: JSON.parse(query1, {:symbolize_names => true})
r2 = client.search index: "test_order", type: "order",
  body: JSON.parse(query2, {:symbolize_names => true})
r3_1 = client.search index: "test_order", type: "order",
  body: JSON.parse(query4_1, {:symbolize_names => true})
r3_2 = client.search index: "test_order", type: "order",
  body: JSON.parse(query4_2, {:symbolize_names => true})

user_ids_1 = Lib.to_ids r1
user_ids_2 = Lib.backet_to_ids r2

user_ids_3_1 = Lib.nested_bucket_do_ids_product r3_1
user_ids_3_2 = Lib.nested_bucket_do_ids_product r3_2
user_ids_3 = user_ids_3_1 | user_ids_3_2

push_in_bulk_container bulk_container, user_ids_1, 6
push_in_bulk_container bulk_container, user_ids_2, 7
push_in_bulk_container bulk_container, user_ids_3, 8

# example 5(no date specified)
# formula = "(SegmentGroup{id: 9} and SegmentGroup{id: 10}) or
#             (SegmentGroup{id: 11} and SegmentGroup{id: 12})"
# Segment{id: 9}
#   SegmentGroup{id: 6, kind: "user", logic: "and"}
#     - age => 20
#     - age <= 29
#     - state in [1,2]
#   SegmentGroup{id: 10, kind: "aggregate", logic: "and"}
#     cumulative_purchase_count  >= 10
#     cumulative_purchase_amount >= 50000
#   SegmentGroup{id: 11, kind: "product_purchase", logic: "or"}
#     -
#       - product_ids in [1,2]
#       - only_product_purchase_count >= 2
#     -
#       - product_ids in [3]
#       - include_course_purchase_count >= 3
#   SegmentGroup{id: 12, kind: "course_purchase", logic: "or"}
#     -
#       - course_ids in [1,2]
#       - only_product_purchase_count >= 2
#     -
#       - course_ids in [3]
#       - include_course_purchase_count >= 3

# NOTE: bulk index
query = container_to_query bulk_container
client.bulk body: query

