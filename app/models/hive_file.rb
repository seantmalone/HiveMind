class HiveFile < ActiveRecord::Base
  class FileNotFound < StandardError
  end

  attr_accessible :uuid, :name, :file

  before_destroy :delete_blocks

  def store_file(file, password)
    filename = file.original_filename
    content_type = file.content_type
    data = file.read
    file_redis_key = "file.#{self.id}"

    file_data = {
      'filename' => filename,
      'content_type' => content_type,
      'data' => Base64.encode64(data)
    }

    json_file_data = file_data.to_json

    encrypted_file_data = AES.encrypt(json_file_data, Digest::SHA256.hexdigest(password), {:iv => AES.iv(:base_64)})

    split_file_data = encrypted_file_data.chars.each_slice(Settings.block_size).map(&:join)

    split_file_data.each do |block|
      fileblock_redis_key = "fileblock.#{SecureRandom.uuid}"
      $redis.rpush(file_redis_key, fileblock_redis_key)

      Block.store(fileblock_redis_key, block)

      logger.debug block
    end
  end

  def retrieve_file
    self.fileblock_keys.each do |fileblock_key|
      logger.debug fileblock_key
      Block.request(fileblock_key)
    end
  end

  def assemble_file(password)
    fileblock_redis_keys = self.fileblock_keys
    number_of_blocks = fileblock_redis_keys.size

    block_data_array = []
    nilcount = 0

    fileblock_redis_keys.each do |fileblock_key|

      block_data = $redis.get(fileblock_key)
      logger.debug [fileblock_key, block_data]

      block_data_array << block_data
      if block_data.nil?
        nilcount += 1
      end
    end

    if nilcount != 0
      logger.debug [nilcount, number_of_blocks]
      percentage = ( (number_of_blocks - nilcount) * 100 ) / number_of_blocks
      raise FileNotFound, percentage
    end

    encrypted_data = block_data_array.join('')

    JSON.parse AES.decrypt(encrypted_data, Digest::SHA256.hexdigest(password))

  end

  def fileblock_keys
    file_redis_key = "file.#{self.id}"
    number_of_blocks = $redis.llen(file_redis_key)
    $redis.lrange( file_redis_key, 0, number_of_blocks )
  end

  def replicate
    self.fileblock_keys.each do |fileblock_key|
      Block.replicate fileblock_key
    end
  end

  #The main replication function
  def self.replicate
    begin
      logger.debug "Beginning Replication"
      HiveFile.all.each do |file|
        file.replicate
      end
      logger.debug "Replication Complete"
      sleep(10)
    end while true
  end

  def password

  end

  private
    def delete_blocks
      self.fileblock_keys.each do |fileblock_key|
        Block.delete fileblock_key
        $redis.del("file.#{self.id}")
      end
    end
end
