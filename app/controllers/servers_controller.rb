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

  # GET or POST
  def coupling
    retrieve_data_for_graph
    @server1 = params[:neoServer1]
    @server2 = params[:neoServer2]
    if @server1 && @server2
      if @server1 == @server2 #direct coupling

      end
      @server1 = Neography::Node.load(@server1, @neo)
      @server2 = Neography::Node.load(@server2, @neo)
      relationships = {"type" => 'connect', "direction" => "all"}
      # directPath =
      direct_path = @neo.get_node_relationships_to(@server1, @server2)
      if direct_path[0] != nil
        tightness = @neo.get_relationship_properties(direct_path[0], [:tight])[:tight]
        looseness = @neo.get_relationship_properties(direct_path[0], [:loose])[:loose]
        @classical = [tightness, looseness]
        @worst = [tightness, looseness]
        @best = [tightness, looseness]
        @moderate = [tightness, looseness]
      else
        all_paths = @neo.execute_query("
        match (n1) -[r*]- (n2) where id(n1) = " +params[:neoServer1]+ "
        and id(n2) = "+params[:neoServer2]+ " return r")["data"]

        query1 = @neo.execute_query("Start n=node("+params[:neoServer1]+"), p=node("+params[:neoServer2]+") Match l = n - [k*] - p with extract(x in relationships(l)| x.loose) as levels Return  levels")["data"]
        query2 = @neo.execute_query("Start n=node("+params[:neoServer1]+"), p=node("+params[:neoServer2]+") Match l = n - [k*] - p with extract(x in relationships(l)| x.tight) as levels Return  levels")["data"]
        #empty values should never return 0, therefore remove them now.
        query1.map!{ |x| x.map! {|xx| xx.each_index do |i|
          if xx[i] == ""
            xx.delete_at(i)
          end
        end } }
        query2.map!{ |x| x.map! {|xx| xx.each_index do |i|
          if xx[i] == ""
            xx.delete_at(i)
          end
        end } }
        best_case(query1, query2)
        worst_case(query1, query2)
      end
    end
    render 'servers/coupling'
  end

  #GET
  def connect
    retrieve_data_for_graph
  end

  #POST
  def do_connect
    tight = params[:tight_coupling]
    loose = params[:loose_coupling]
    if params[:neoServer1] != params[:neoServer2] && tight && loose
      @neo = Neography::Rest.new
      server1 = Neography::Node.load(params[:neoServer1], @neo)
      server2 = Neography::Node.load(params[:neoServer2], @neo)
      direct_path = @neo.get_node_relationships_to(server1, server2)
      if direct_path[0] != nil #there exists already a relation, so delete that before creating a new one
        @neo.delete_relationship direct_path[0]
      end
      relation = @neo.create_relationship(:connected, server1, server2)
      @neo.set_relationship_properties(relation, {tight: tight})
      @neo.set_relationship_properties(relation, {loose: loose})
      redirect_to action: 'connect', notice: 'Connection was successfully created.'
    else
      redirect_to action: 'connect', alert: 'Connecting a node with itself  or leaving parameters empty is not permitted.'
    end
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
      name = Server.find(params[:id]).name
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
    destroy_server @server
    respond_to do |format|
      format.html { redirect_to servers_url, notice: 'Server was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  def destroy_everything
    Server.all.each do |server|
      destroy_server server
    end
    redirect_to action: 'index', notice: 'Everything was successfully destroyed.'
  end

  private
# Use callbacks to share common setup or constraints between actions.
  def set_server
    @server = Server.find(params[:id])
  end

  def destroy_server(server)
    n = Neography::Node.find('servers', 'name', server.name)
    n.del if n
    server.destroy
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

          tightness = @neo.get_relationship_properties(relationship, [:tight])[:tight]
          looseness = @neo.get_relationship_properties(relationship, [:loose])[:loose]
          target_node_id = relationship.end_node[:id]
          target_id = 0 # we need to have relative numbers for d3.js
          @neo_servers.each do |possible_target|
            break if possible_target['server']['data']['id'] == target_node_id
            target_id += 1
          end
          #enter everything into the @links array
          @links << {source: source_id, target: target_id, tight: tightness, loose: looseness}

        end
      end
      source_id +=1 # check out the next source in the next iteration
    end
  end

  def worst_case(loose, tight)
    tightlycouplinglist = []
    @worst = []

    tight.each do |x|
      tightlycouplinglist.append(x[0].min)
    end
    #or

    x = tightlycouplinglist.length
    y = 0

    if x > 1
      while y < x-1
        product = tightlycouplinglist[y].to_f*tightlycouplinglist[y+1].to_f
        sum = tightlycouplinglist[y].to_f+tightlycouplinglist[y+1].to_f
        tightlycouplinglist[y] = sum - product
        y += 1
      end
      @worst[0]=tightlycouplinglist[y-1]
    else
      @worst[0]=tightlycouplinglist[0]
    end
    looselycouplinglist = []
    product = 1.0

    #and
    loose.each do |record| #for some reason, there are strings around.
      record.map! { |xy| xy.map! { |xyz| xyz.to_f } }
    end
    loose.each do |record|
      looselycouplinglist.append(record[0].max)
    end
    #or
    if looselycouplinglist.length > 1
      looselycouplinglist.each { |x| product = product * x.to_f }
      @worst[1]=product
    else
      @worst[1]=looselycouplinglist[0]
    end

  end

  def best_case(loose, tight)
    tightlycouplinglist = []
    tightproduct = 1.0
    @best = []
    #and
    tight.each do |x|
      x[0].each do |y|
        tightproduct = tightproduct * y.to_f
      end
      tightlycouplinglist.append(tightproduct)
      tightproduct = 1.0
    end

    #or
    @best[0]=tightlycouplinglist.max

    #loosely
    looselycouplinglist = []
    product = 1.0
    sum = 0.0
    #and
    loose.each do |record|
      copy = record[0]
      x = copy.length
      y = 0
      if x > 1
        while y < x-1
          product = copy[y].to_f * copy[y+1].to_f
          sum = copy[y].to_f + copy[y+1].to_f
          copy[y] = sum - product
          y += 1
        end
        looselycouplinglist.append(copy[y-1])

      else
        looselycouplinglist.append(copy[0].to_f)
      end
    end
    #or
    @best[1]=looselycouplinglist.min


  end

end
