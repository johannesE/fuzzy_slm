class ServersController < ApplicationController
  before_action :set_server, only: [:show, :edit, :update, :destroy]

  # GET /servers
  # GET /servers.json
  def index
    @servers = Server.all
    @neo_servers = get_all_neo_servers.map { |s| {"server" => s[0]} }
    # @neo_servers = @neo_servers.to_json
    # .inject({}) { |h, i| t = h; i.each { |n| t[n] ||= {}; t = t[n] }; h }.to_json
  end

  # GET /servers/1
  # GET /servers/1.json
  def show
  end

  # GET /servers/new
  def new
    @server = Server.new
  end

  # GET /servers/1/edit
  def edit
  end

  def connect
    @servers = Server.all
    @neo_servers = get_all_neo_servers.map { |s| {"server" => s[0]} }
  end

  # POST /servers
  # POST /servers.json
  def create
    @server = Server.new(server_params)
    @neo = Neography::Rest.new

    respond_to do |format|
      if @server.save && n = Neography::Node.create("name" => server_params[:name])
        n.add_to_index('servers', 'name', server_params[:name])
        n.id = n.neo_id # this construct should be improved..
        format.html { redirect_to @server, notice: 'Server was successfully created.' }
        format.json { render :show, status: :created, location: @server }
      else
        format.html { render :new }
        format.json { render json: @server.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /servers/1
  # PATCH/PUT /servers/1.json
  def update
    respond_to do |format|
      if @server.update(server_params)
        format.html { redirect_to @server, notice: 'Server was successfully updated.' }
        format.json { render :show, status: :ok, location: @server }
      else
        format.html { render :edit }
        format.json { render json: @server.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /servers/1
  # DELETE /servers/1.json
  def destroy
    n = Neography::Node.find('servers', 'name', @server.name)
    n.del if n
    @server.destroy
    respond_to do |format|
      format.html { redirect_to servers_url, notice: 'Server was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_server
    @server = Server.find(params[:id])
  end

  def get_all_neo_servers
    @neo = Neography::Rest.new
    @neo.execute_query("match (n) return n limit 50;")["data"]
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def server_params
    params.require(:server).permit(:name)
  end
end
