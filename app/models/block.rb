class Block
  def self.store(block_id, block_data)
    distribution_nodes_uuids = Node.where("updated_at > ?", 1.minute.ago).pluck(:uuid).shuffle[0..(Settings.distribution_node_count - 1)]

    distribution_nodes_uuids.each do |node_uuid|
      Node.find_by_uuid(node_uuid).store_block(block_id, block_data)
      $redis.zadd("#{block_id}|nodes", Time.now.to_i, node_uuid)
      $redis.set("#{block_id}|md5", Digest::MD5.hexdigest(block_data))
    end
  end

  def self.request(block_id)
    node_uuids = $redis.zrangebyscore("#{block_id}|nodes", Settings.block_expiration.minutes.ago.to_i, '+inf')
    node_uuids.each do |node_uuid|
      Node.find_by_uuid(node_uuid).request_block(block_id)
    end
  end

  def self.delete(block_id)
    $redis.del(block_id, "#{block_id}|md5", "#{block_id}|nodes")
  end

  def self.replicate(block_id)
    current_block_count = $redis.zcount("#{block_id}|nodes", Settings.block_expiration.minutes.ago.to_i, '+inf')
    if current_block_count < Settings.minimum_node_count
      #If we have the data, store on new nodes
      #If not, request the data.  We'll store it next time around.
      block_data = $redis.get(block_id)
      if block_data.nil?
        Block.request(block_id)
      else
        Block.store(block_id, block_data)
      end
    end
  end
end