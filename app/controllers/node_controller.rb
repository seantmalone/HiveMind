class NodeController < ApplicationController
  http_basic_authenticate_with name: Settings.username, password: Settings.password, except: [:create, :botjs]

  def index
    @nodes_grid = initialize_grid(Node.where("updated_at > ?", 1.minute.ago).reorder('updated_at'))

  end

  def create
    uuid = params[:node][:uuid] rescue SecureRandom.uuid
    @node = Node.find_or_create_by_uuid(uuid)
    @node.ip = request.remote_ip
    @node.user_agent = request.env['HTTP_USER_AGENT']
    @node.touch
    @node.save!

    render json: @node
  end

  def node_test
    @node = Node.find(params[:id])
    logger.debug @node.uuid

    @node.store_block(12345,"testing again")
    @node.request_block(12345)

    render :nothing => true, :status => 200
  end

  def heartbeat
    @node = Node.find_by_uuid(params[:node][:uuid])
    @node.touch

    render :nothing => true, :status => 200
  end

  def botjs
    render "botjs.js.erb"
  end
end
