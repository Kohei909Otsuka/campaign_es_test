module Lib
  def to_ids search_result
    search_result["hits"]["hits"].map {|hit| hit["_id"].to_i}
  end

  def backet_to_ids search_result
    search_result["aggregations"]["by_user_id"]["buckets"].map {|bucket| bucket["key"]}
  end
  module_function :to_ids, :backet_to_ids
end
