class AjaxController < ApplicationController
  def register
    logger.debug "Register Event"
    logger.debug params

    if cookies.has_key? :uuid
      uuid = cookies[:uuid]
      @node = Node.find_by_uuid(uuid)

      if @node.nil?
        render :text => "Invalid UUID #{uuid}.", :status => 500
      else
        @node.touch
        render nothing: true, :status => 200
      end


    else
      logger.debug 'No UUID sent'
      uuid = SecureRandom.uuid
      @node = Node.new
      @node.uuid = uuid
      @node.ip = request.env['REMOTE_ADDR']
      @node.user_agent = request.env['HTTP_USER_AGENT']
      @node.save!

      cookies[:uuid] = uuid
      render nothing: true, :status => 200
    end
  end

  def block_upload
    logger.debug "Block Upload Event"
    logger.debug params

    block_id = params[:block_id]
    block_data = params[:block_data]
    $redis.set(block_id, block_data)
    $redis.expire(block_id, 20)
    render nothing: true, :status => 200
  end

  def heartbeat
    to_delete = []
    uuid = cookies[:uuid]
    @node = Node.find_by_uuid(uuid)
    @node.touch

    if params.has_key? :blocks
      params[:blocks].each do |i,block|
        #If we're not tracking this block, trigger block deletion on the node
        if $redis.zrank("#{block[:block_id]}|nodes", uuid).nil?
          to_delete << block[:block_id]
        end

        if block['md5'] == $redis.get("#{block[:block_id]}|md5")
          $redis.zadd("#{block[:block_id]}|nodes", Time.now.to_i, uuid)
        end
      end
    end

    render :json => {:to_delete => to_delete}, :status => 200
  end

  def check_queue
    uuid = cookies[:uuid]

    fileblocks_to_send = $redis.smembers("#{uuid}|to_send")
    $redis.del("#{uuid}|to_send")

    fileblock_keys_to_store = $redis.smembers("#{uuid}|to_store")
    $redis.del("#{uuid}|to_store")

    fileblocks_to_store = []
    fileblock_keys_to_store.each do |block_id|
      fileblocks_to_store << {
        :block_id => block_id,
        :block_data => $redis.get(block_id)
      }
    end

    render :json => {:to_send => fileblocks_to_send, :to_store => fileblocks_to_store}, :status => 200
  end
end
