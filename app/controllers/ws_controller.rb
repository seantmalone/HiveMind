class WsController < WebsocketRails::BaseController
  def client_connected
    logger.debug "Client Connected!"
  end

  def register
    logger.debug "Register Event"
    logger.debug message

    if message.has_key? :uuid
      uuid = message[:uuid]
      @node = Node.find_by_uuid(uuid)

      if connection_store.collect_all(:uuid).include? uuid
        trigger_failure ({:message => "There is already a connection with UUID #{uuid}."})
      elsif @node.nil?
        trigger_failure ({:message => "Invalid UUID #{uuid}."})
      else
        @node.touch
        connection_store[:uuid] = uuid
        trigger_success( {'uuid' => uuid} )
      end


    else
      logger.debug 'No UUID sent'
      uuid = SecureRandom.uuid
      @node = Node.new
      @node.uuid = uuid
      @node.ip = connection.env['REMOTE_ADDR']
      @node.user_agent = connection.env['HTTP_USER_AGENT']
      @node.touch
      @node.save!

      connection_store[:uuid] = uuid
      trigger_success( {'uuid' => uuid} )
    end
  end

  def block_upload
    logger.debug "Block Upload Event"
    logger.debug message

    block_id = message[:block_id]
    block_data = message[:block_data]
    $redis.set(block_id, block_data)
    $redis.expire(block_id, 20)
  end

  def heartbeat
    to_delete = []

    message.each do |block|
      #If we're not tracking this block, trigger block deletion on the node
      if $redis.zrank("#{block[:block_id]}|nodes", connection_store[:uuid]).nil?
        to_delete << block[:block_id]
      end

      if block['md5'] == $redis.get("#{block[:block_id]}|md5")
        $redis.zadd("#{block[:block_id]}|nodes", Time.now.to_i, connection_store[:uuid])
      end
    end

    trigger_success to_delete
  end
end
