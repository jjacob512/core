# Copyright 2013, Dell
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
class BarclampNetwork::NetworksController < ::ApplicationController
  respond_to :html, :json

  # Create should be passed a JSON blob that looks like this:
  # {
  #    "name":       "networkname",
  #    "deployment": "deploymentname",
  #    "vlan":       your_vlan,
  #    "use_vlan":   true or false,
  #    "team_mode":  teaming mode,
  #    "use_team":   true or false,
  #    "use_bridge": true or false
  #    "conduit":    "1g0,1g1", // or whatever you want to use as a conduit for this network
  #    "ranges": [
  #       { "name": "name", "first": "192.168.124.10/24", "last": "192.168.124.245/24" }
  #    ],
  #    "router": {
  #       "pref": 255, // or whatever pref you want.  Lowest on a host will win.
  #       "address": "192.168.124.1/24"
  #    }
  # }
  def create

    Rails.logger.debug("Creating network #{params[:name]}");

    # provide reasonable defaults
    params[:ranges] ||= [{:name=>t('all'), :first=>"10.10.10.1/24", :last=>"10.10.10.245/24" }]
    params[:router] ||= { :pref => 255, :address => "10.10.10.1/24" }
    params[:use_vlan] = true if params[:vlan].to_int > 0 rescue false 
    params[:use_team] = true if params[:team].to_int > 0 rescue false
    params[:use_bridge] = true if params[:use_bridge].to_int > 0 rescue false
    params[:deployment_id] = Deployment.find_key(params[:deployment]).id if params.has_key? :deployment

    @network = BarclampNetwork::Network.make_network(
                                                     :name => params[:name],
                                                     :deployment_id => params[:deployment_id],
                                                     :vlan => params[:vlan] || 0,
                                                     :use_vlan => params[:use_vlan] || false,
                                                     :use_bridge => params[:use_bridge] || false,
                                                     :team_mode => params[:team_mode] || 5,
                                                     :use_team => params[:use_team] || false,
                                                     :conduit => params[:conduit],
                                                     :ranges => params[:ranges],
                                                     :router => params[:router])
    respond_with(@network) do |format|
      format.html {} 
      format.json { render :json => @network.to_template }
    end
  end

  def update
    @network = BarclampNetwork::Network.find_key(params[:id])
    # Only allow teaming and conduit stuff to be updated for now.
    @network.team_mode = params[:team_mode] if params.has_key?(:team_mode)
    @network.conduit = params[:conduit] if params.has_key?(:conduit)
    @network.use_team = params[:use_team] if params.has_key?(:use_team)
    @network.description = params[:description] if params.has_key?(:description)
    @network.order = params[:order] if params.has_key?(:order)
    @network.conduit = params[:conduit] if params.has_key?(:conduit)
    @network.save
    respond_with(@network) do |format|
      format.html { render :action=>:show } 
      format.json { render api_show :network, BarclampNetwork::Network, nil, nil, @network }
    end
  end

  def destroy
    raise ArgumentError.new("Cannot destroy networks for now")
  end

  def ip
    if request.post?
      allocate_ip
    elsif request.delete?
      deallocate_ip
    end
  end
      
  def allocate_ip
    network = BarclampNetwork::Network.find_key(params[:id])
    node = Node.find_key(params[:node_id])
    range = network.ranges.where(:name => params[:range]).first
    suggestion = params[:suggestion]

    ret = range.allocate(node,suggestion)
    render :json => ret
  end

  def deallocate_ip
    raise ArgumentError.new("Cannot deallocate addresses for now")
    node = Node.find_key(params[:node_id])
    allocation = BarclampNetwork::Allocation.where(:address => params[:cidr], :node_id => node.id)
    allocation.destroy
  end

  def enable_interface
    raise ArgumentError.new("Cannot enable interfaces without IP address allocation for now.")
    
    deployment_id = params[:deployment_id]
    deployment_id = nil if deployment_id == "-1"
    network_id = params[:id]
    node_id = params[:node_id]

    ret = @barclamp.network_enable_interface(deployment_id, network_id, node_id)
    return render :text => ret[1], :status => ret[0] if ret[0] != 200
    render :json => ret[1]
  end

  def show
    @network = BarclampNetwork::Network.find_key(params[:id])
    respond_with(@network) do |format|
      format.html { render }
      format.json { render :json => @network.to_template }
    end
  end
  
  def index
    Rails.logger.debug("NetworksController.index");
    @networks = BarclampNetwork::Network.all
    respond_with(@networks) do |format|
      format.html do
        render
      end
      format.json do
        render :json => "[ #{@networks.map{|n|n.to_template}.join(", ")} ]"
      end
    end
  end

  def edit
    Rails.logger.debug("NetworksController.edit");
    @network = BarclampNetwork::Network.find(params[:id]) unless params[:id].nil?
    @conduits = BarclampNetwork::Conduit.all
    respond_to do |format|
      format.html {
        Rails.logger.debug("NetworksController.edit Format HTML: #{@network.inspect}");
      }
    end
  end

end
