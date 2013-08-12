class FileController < ApplicationController
  http_basic_authenticate_with name: Settings.username, password: Settings.password

  def index
    @files_grid = initialize_grid(HiveFile)
  end

  def detail
    @file = HiveFile.find(params[:file_id])
  end

  def create
    file = params[:hive_file][:file]
    params[:hive_file].delete(:file)

    password = params[:hive_file][:password]
    params[:hive_file].delete(:password)

    @file = HiveFile.create(params[:hive_file])
    @file.uuid = SecureRandom.uuid
    @file.store_file(file, password)
    @file.save!

    redirect_to file_index_path
  end

  def destroy
    @file = HiveFile.find(params[:id])
    @file.destroy

    redirect_to file_index_path
  end

  def fetch
    @file = HiveFile.find(params[:file_id])
  end

  def retrieve
    @file = HiveFile.find(params[:file_id])
    @file.retrieve_file

    render :nothing => true, :status => 200
  end

  def download_ready
    @file = HiveFile.find(params[:file_id])

    begin
      file_data = @file.assemble_file(params[:password])

      render :nothing => true, :status => 200
    rescue HiveFile::FileNotFound => e
      render :json => {:err => 'incomplete', :percentage => e.message}, :status => 404
    rescue OpenSSL::Cipher::CipherError => e
      render :json => {:err => 'password_incorrect'}, :status => 404
    end

  end

  def download
    @file = HiveFile.find(params[:file_id])
    file_data = @file.assemble_file(params[:password])
    if file_data
      logger.debug file_data
      send_data( Base64.decode64(file_data['data']), :filename => file_data['filename'] )
    else
      render :nothing => true, :status => 404
    end
  end
end
