#
# Cookbook Name:: rackspace_cloudmonitoring
# Recipe:: entity
#
# Configure the cloud_monitoring_entity LWRP to use the existing entity
# for the node by matching the server IP.
#
# This cookbook consumes node data set in the agent recipe.
#
# Copyright 2014, Rackspace
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

rackspace_cloudmonitoring_entity node.hostname do
  agent_id              node[:rackspace_cloudmonitoring][:agent][:id]
  search_method         "ip"
  search_ip             node["cloud"]["local_ipv4"]
  action :create                                 
end                                              
