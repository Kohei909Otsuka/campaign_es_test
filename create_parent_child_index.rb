require "elasticsearch"
require "json"

MAPPING = '{
  "mappings": {
    "user": {
      "properties": {
        "id": {"type": "integer"},
        "age": {"type": "integer"},
        "state_id": {"type": "integer"},
        "is_accept_mail": {"type": "boolean"},
        "created_at": {"type": "date"}
      }
    },
    "order": {
      "_parent": {
        "type": "user"
      },
      "properties": {
        "id": {"type": "integer"},
        "total": {"type": "double"},
        "created_at": {"type": "date"},
        "order_items": {
          "type": "nested",
          "properties": {
            "product_id": {"type": "integer"},
            "course_id": {"type": "integer"},
            "quantity": {"type": "integer"}
          }
        }
      }
    },
    "course_order": {
      "_parent": {
        "type": "user"
      },
      "properties": {
        "id": {"type": "integer"},
        "created_at": {"type": "date"},
        "course_order_items": {
          "type": "nested",
          "properties": {
            "course_id": {"type": "integer"},
            "quantity": {"type": "integer"}
          }
        }
      }
    }
  }
}'

mapping = JSON.parse(MAPPING, {:symbolize_names => true})
client = Elasticsearch::Client.new log: true
client.transport.reload_connections!
client.indices.create index: "user_segment_parent_child", body: mapping
