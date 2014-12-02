class ServersController < ApplicationController
  before_action :set_server, only: [:show, :edit, :update, :destroy]

  # GET /servers
  # GET /servers.json
  def index
    retrieve_data_for_graph
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
    retrieve_data_for_graph
  end

  def do_connect
    @neo = Neography::Rest.new
    server1 = Neography::Node.load(params[:neoServer1], @neo)
    server2 = Neography::Node.load(params[:neoServer2], @neo)
    relation = @neo.create_relationship(:connected, server1, server2)
    @neo.set_relationship_properties(relation, {tight: params[:tight_coupling]})
    @neo.set_relationship_properties(relation, {loose: params[:loose_coupling]})
    redirect_to action: 'connect', notice: 'Connection was successfully created.'
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
      name  = Server.find(params[:id]).name
      n = Neography::Node.find('servers', 'name', name)
      n.name = server_params[:name]
      n.add_to_index('servers', 'name', server_params[:name]) #TODO: is this necessary?
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


  def retrieve_data_for_graph
    @servers = Server.all
    @neo_servers = get_all_neo_servers.map { |s| {"server" => s[0]} }
    @nodes = []
    x=y=10 #coordinates
    @neo_servers.each do |neo|
      @nodes << {x: x, y: y, name: neo['server']['data']['name']}
      x += 10; y += 2
    end
    @links = []
    source_id = 0
    @neo_servers.each do |neo|
      server = Neography::Node.load(neo['server']['data']['id'], @neo)
      if server.rel?(:outgoing, :connected)
        relationships = server.rels(:connected).outgoing
        relationships.each do |relationship|

          relationship_weight = @neo.get_relationship_properties(relationship, ["weight"])
          target_node_id = relationship.end_node[:id]
          target_id = 0 # we need to have relative numbers for d3.js
          @neo_servers.each do |possible_target|
            break if possible_target['server']['data']['id'] == target_node_id
            target_id += 1
          end
          #enter everything into the @links array
          @links << {source: source_id, target: target_id, weight: relationship_weight}

        end
      end
      source_id +=1 # check out the next source in the next iteration
    end
  end
end
