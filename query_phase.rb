require "elasticsearch"
require "json"
require "pry"
require_relative "lib"

client = Elasticsearch::Client.new log: true
client.transport.reload_connections!

# example 1

# formula = "SegmentGroup{id: 1}"
query1 = '{
  "query": {
    "bool": {
      "must": [
        {
          "nested": {
            "path": "true_segment_groups",
            "query": {
              "bool": {
                "must": [
                  {
                    "bool": {
                      "must": [
                        { "term": { "true_segment_groups.id": 1 }},
                        { "term": { "true_segment_groups.is_match": true }}
                      ]
                    }
                  }
                ]
              }
            }
          }
        }
      ]
    }
  }
}'




# example 2(日付 2016-01-01 ~ 2019-01-01)
# formula = "SegmentGroup{id: 2} and SegmentGroup{id: 3}"

query2 = '{
  "query": {
    "bool": {
      "must": [
        {
          "nested": {
            "path": "true_segment_groups",
            "query": {
              "bool": {
                "must": [
                  {
                    "bool": {
                      "must": [
                        { "term": { "true_segment_groups.id": 2 }},
                        { "term": { "true_segment_groups.is_match": true }}
                      ]
                    }
                  }
                ]
              }
            }
          }
        },
        {
          "nested": {
            "path": "true_segment_groups",
            "query": {
              "bool": {
                "must": [
                  {
                    "bool": {
                      "must": [
                        { "term": { "true_segment_groups.id": 3 }},
                        { "term": { "true_segment_groups.is_match": true }}
                      ]
                    }
                  }
                ]
              }
            }
          }
        }
      ]
    }
  }
}'

# example 3(date specified: 2018-04-04 ~ 2018-12-31)
# formula = "SegmentGroup{id: 4} and SegmentGroup{id: 5}"
query3 = '{
  "query": {
    "bool": {
      "must": [
        {
          "nested": {
            "path": "true_segment_groups",
            "query": {
              "bool": {
                "must": [
                  {
                    "bool": {
                      "must": [
                        { "term": { "true_segment_groups.id": 4 }},
                        { "term": { "true_segment_groups.is_match": true }}
                      ]
                    }
                  }
                ]
              }
            }
          }
        },
        {
          "nested": {
            "path": "true_segment_groups",
            "query": {
              "bool": {
                "must": [
                  {
                    "bool": {
                      "must": [
                        { "term": { "true_segment_groups.id": 5 }},
                        { "term": { "true_segment_groups.is_match": true }}
                      ]
                    }
                  }
                ]
              }
            }
          }
        }
      ]
    }
  }
}'

# example 4(no date specified)
# formula = "(SegmentGroup{id: 6} and SegmentGroup{id: 7}) or SegmentGroup{id: 8}"
query4 = '{
  "query": {
    "bool": {
      "should": [
        {
          "bool": {
            "must": [
              {
                "nested": {
                  "path": "true_segment_groups",
                  "query": {
                    "bool": {
                      "must": [
                        {
                          "bool": {
                            "must": [
                              { "term": { "true_segment_groups.id": 8 }}
                            ]
                          }
                        }
                      ]
                    }
                  }
                }
              }
            ]
          }
        },
        {
          "bool": {
            "must": [
              {
                "nested": {
                  "path": "true_segment_groups",
                  "query": {
                    "bool": {
                      "must": [
                        {
                          "bool": {
                            "must": [
                              { "term": { "true_segment_groups.id": 6 }},
                              { "term": { "true_segment_groups.is_match": true }}
                            ]
                          }
                        }
                      ]
                    }
                  }
                }
              },
              {
                "nested": {
                  "path": "true_segment_groups",
                  "query": {
                    "bool": {
                      "must": [
                        {
                          "bool": {
                            "must": [
                              { "term": { "true_segment_groups.id": 7 }},
                              { "term": { "true_segment_groups.is_match": true }}
                            ]
                          }
                        }
                      ]
                    }
                  }
                }
              }
            ]
          }
        }
      ]
    }
  }
}'

r1 = client.search index: "test_summary", type: "user_segment_group",
  body: JSON.parse(query1, {:symbolize_names => true}),
  size: 1000
ids1 = r1["hits"]["hits"].map {|hit| hit["_source"]["user_id"]}

r2 = client.search index: "test_summary", type: "user_segment_group",
  body: JSON.parse(query2, {:symbolize_names => true}),
  size: 1000
ids2 = r2["hits"]["hits"].map {|hit| hit["_source"]["user_id"]}

r3 = client.search index: "test_summary", type: "user_segment_group",
  body: JSON.parse(query3, {:symbolize_names => true}),
  size: 1000
ids3 = r3["hits"]["hits"].map {|hit| hit["_source"]["user_id"]}

r4 = client.search index: "test_summary", type: "user_segment_group",
  body: JSON.parse(query4, {:symbolize_names => true}),
  size: 1000
ids4 = r4["hits"]["hits"].map {|hit| hit["_source"]["user_id"]}


puts "matched user_ids of Segment{id: 1}"
p ids1.length
p ids1

puts "matched user_ids of Segment{id: 2}"
p ids2.length
p ids2

puts "matched user_ids of Segment{id: 3}"
p ids3.length
p ids3

puts "matched user_ids of Segment{id: 4}"
p ids4.length
p ids4
