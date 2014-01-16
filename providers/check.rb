#
# Cookbook Name:: rackspace_cloudmonitoring
# Provider:: check
#
# Copyright 2014, Rackspace, US, Inc.
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

include Opscode::Rackspace::Monitoring

action :create do
  Chef::Log.debug("Beginning action[:create] for #{new_resource}")
  new_resource.updated_by_last_action(@current_resource.update(
    :label => new_resource.label,
    :type => new_resource.type,
    :details => new_resource.details,
    :metadata => new_resource.metadata, 
    :monitoring_zones_poll => new_resource.monitoring_zones_poll,
    :target_alias => new_resource.target_alias,
    :target_hostname => new_resource.target_hostname,
    :target_resolver => new_resource.target_resolver,
    :timeout => new_resource.timeout,
    :period => new_resource.period
  ))
end

action :delete do
  Chef::Log.debug("Beginning action[:delete] for #{new_resource}")
  new_resource.updated_by_last_action(@current_resource.delete())
end

def load_current_resource
  @current_resource = CM_check.new(node)
  
  # Configure the entity details, if specified
  if @new_resource.entity_label then
    raise Exception, "Cannot specify entity_label and entity_id" unless @new_resource.entity_id.nil?
    @current_resource.lookup_entity_by_label(@new_resource.entity_label)
  else
    if @new_resource.entity_id
      @current_resource.lookup_entity_by_id(@new_resource.entity_id)
    end
  end

  # Lookup the check
  @current_resource.lookup_by_label(@new_resource.label)
end
