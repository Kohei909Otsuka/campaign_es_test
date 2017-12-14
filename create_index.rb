require "elasticsearch"
require "json"

USER_INDEX = '{
  "mappings": {
    "user": {
      "dynamic": "strict",
      "properties": {
        "id": {"type": "integer"},
        "age": {"type": "integer"},
        "state_id": {"type": "integer"},
        "is_accept_mail": {"type": "boolean"},
        "created_at": {"type": "date"}
      }
    }
  }
}'

ORDER_INDEX= '{
  "mappings": {
    "order": {
      "dynamic": "strict",
      "properties": {
        "id": {"type": "integer"},
        "course_order_id": {"type": "integer"},
        "total": {"type": "double"},
        "product_ids": {"type": "string", "index": "not_analyzed"},
        "course_ids": {"type": "string", "index": "not_analyzed"},
        "created_at": {"type": "date"},
        "user_id": {"type": "integer"}
      }
    }
  }
}'

COURSE_ORDER_INDEX = '{
  "mappings": {
    "course_order": {
      "dynamic": "strict",
      "properties": {
        "id": {"type": "integer"},
        "status": {"type": "integer"},
        "latest_continuation_times": {"type": "integer"},
        "course_ids": {"type": "string", "index": "not_analyzed"},
        "created_at": {"type": "date"},
        "user_id": {"type": "integer"}
      }
    }
  }
}'


SUMMARY_INDEX = '{
  "mappings": {
    "segment": {
      "dynamic": "strict",
      "properties": {
        "user_id": {"type": "integer"},
        "id": {"type": "integer"}
      }
    },
    "segment_group": {
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
}'

user_mapping = JSON.parse(USER_INDEX, {:symbolize_names => true})
order_mapping = JSON.parse(ORDER_INDEX, {:symbolize_names => true})
course_order_mapping = JSON.parse(COURSE_ORDER_INDEX, {:symbolize_names => true})
summary_mapping = JSON.parse(SUMMARY_INDEX, {:symbolize_names => true})

client = Elasticsearch::Client.new log: true
client.transport.reload_connections!

client.indices.delete index: '_all'

client.indices.create index: "test_user", body: user_mapping
client.indices.create index: "test_order", body: order_mapping
client.indices.create index: "test_course_order", body: course_order_mapping
client.indices.create index: "test_summary", body: summary_mapping
