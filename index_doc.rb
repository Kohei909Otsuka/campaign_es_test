require "elasticsearch"
require "ffaker"

client = Elasticsearch::Client.new log: true
client.transport.reload_connections!

DAY1 = Date.new(2017,11,30)
DAY2 = Date.new(2018,11,30)

# bulk index users
users = []
100.times do |i|
  id = i + 1
  meta = {
    index: {
      _index: "user_segment_parent_child",
      _type: "user",
      _id: id
    }
  }
  data = {
    id: i,
    age: rand(25..35),
    state_id: rand(1..3),
    is_accept_mail: FFaker::Boolean.random,
    created_at: [DAY1, DAY2].sample
  }
  users << meta
  users << data
end
client.bulk body: users


# bulk index course order
course_orders = []
200.times do |i|
  id = i + 1
  meta = {
    index: {
      _index: "user_segment_parent_child",
      _type: "course_order",
      _id: id,
      _parent: rand(1..100)
    }
  }

  data = {
    id: i,
    created_at: [DAY1, DAY2].sample,
    course_order_items: [
      {course_id: rand(1..10), quantity: rand(1..3)},
      {course_id: rand(1..10), quantity: rand(1..3)}
    ]
  }
  course_orders << meta
  course_orders << data
end
client.bulk body: course_orders


# bulk index orders
orders = []
1000.times do |i|
  id = i + 1
  meta = {
    index: {
      _index: "user_segment_parent_child",
      _type: "order",
      _id: id,
      _parent: rand(1..100)
    }
  }

  data = {
    id: i,
    total: rand(1000..10000),
    created_at: [DAY1, DAY2].sample,
    order_items: [
      {product_id: rand(1..10), course_id: rand(1..10), quantity: rand(1..3)},
      {product_id: rand(1..10), course_id: rand(1..10), quantity: rand(1..3)}
    ]
  }
  orders << meta
  orders << data
end
client.bulk body: orders
