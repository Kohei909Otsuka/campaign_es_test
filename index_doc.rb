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
      _index: "test_user",
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
      _index: "test_course_order",
      _type: "course_order",
      _id: id,
    }
  }
  data = {
    id: i,
    status: rand(1..3),
    latest_continuation_times: rand(1..10),
    course_ids: [1,2,3],
    created_at: [DAY1, DAY2].sample,
    user_id: rand(1..50)
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
      _index: "test_order",
      _type: "order",
      _id: id,
    }
  }
  data = {
    id: i,
    course_order_id: [rand(1..200), nil].sample,
    total: rand(1000..10000),
    product_ids: [1,2,3],
    course_ids: [1,2,3],
    created_at: [DAY1, DAY2].sample,
    user_id: rand(1..100)
  }
  orders << meta
  orders << data
end
client.bulk body: orders


segments = []
100.times do |i|
  user_id = i + 1
  4.times do |j|
    segment_id = j + 1
    doc_id = "#{user_id}_#{segment_id}"
    meta = {
      index: {
        _index: "test_summary",
        _type: "segment",
        _id: doc_id
      }
    }

    data = {
      user_id: user_id,
      id: segment_id
    }
    segments << meta
    segments << data
  end
end
client.bulk body: segments
