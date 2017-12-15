module Lib
  def to_ids search_result
    search_result["hits"]["hits"].map {|hit| hit["_id"].to_i}.uniq
  end

  def backet_to_ids search_result
    search_result["aggregations"]["by_user_id"]["buckets"].map {|bucket| bucket["key"]}.uniq
  end

  def nested_bucket_do_ids_product search_result
    search_result["aggregations"]["by_product_id"]["buckets"].map {
      |p| p["by_user_id"]["buckets"]}.flatten.map {|u| u["key"]}.uniq
  end
  module_function :to_ids, :backet_to_ids, :nested_bucket_do_ids_product
end
