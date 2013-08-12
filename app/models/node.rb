class Node < ActiveRecord::Base
  #attr_accessible :ip, :user_agent, :uuid

  def store_block(block_id, block_data)
    data = {
      'block_id' => block_id,
      'block_data' => block_data
    }
    WebsocketRails[self.uuid].trigger(:store_block, data)

    $redis.sadd("#{uuid}|to_store", block_id)
    $redis.set(block_id, block_data)
    $redis.expire(block_id, 20)
  end

  def request_block(block_id)
    data = {
      'block_id' => block_id
    }
    WebsocketRails[self.uuid].trigger(:send_block, data)

    $redis.sadd("#{uuid}|to_send", block_id)
  end

end
