rackspace_cloudmonitoring Cookbook
===================================

NOTE: v2.0.0 is a major rewrite with breaking changes.  Please review this readme for new usage and check the changelog
-----------------------------------------------------------------------------------------------------------------------

# Description

This cookbook provides automated way to manage the various resources using the Rackspace Cloud Monitoring API.
Specifically this recipe will focus on main atom's in the system.

* Entities
* Checks
* Alarms
* Agent
* Agent Tokens

# General Requirements
* Chef 11
* A Rackspace Cloud Hosting account is required to use this tool.  And a valid `username` and `api_key` are required to authenticate into your account.  [sign-up](https://cart.rackspace.com/cloud/?cp_id=cloud_monitoring).

# Credential Handling

As this Cookbook is API focused, credentials for the API are required.
These credentials can be passed to the LWRPs, loaded from an encrypted databag, or pulled from Node attributes.

| Credential | Required | Default | Node Attribute | Databag Attribute |
| ---------- | -------- | ------- | -------------- | ----------------- |
| API Key    | Yes      | NONE    | node['rackspace"]['cloud_credentials']['api_key'] | apikey |
| API Username | Yes    | NONE    | node['rackspace"]['cloud_credentials']['username'] | username |
| API Auth URL | No     | Defined in attributes.rb | node['rackspace_cloudmonitoring']['auth']['url'] | auth_url |
| Agent Token | No      | Generated via API | node['rackspace_cloudmonitoring']['config']['agent']['token'] | agent_token |

Note that the API Key and API Username use the shared node['rackspace"]['cloud_credentials'] namespace, not the node['rackspace_cloudmonitoring'] namespace.
Passing values in via LWRPs will be covered in the LWRP section.

Precedence is as follows:

1. LWRP arguments
2. Node attributes
3. Databag

The details of the databag are as follows:

| Credential | Default | Node Attribute |
| ---------- | ------- | -------------- |
| Name       | Defined in attributes.rb | node['rackspace_cloudmonitoring']['auth']['databag']['name'] |
| Item	     | Defined in attributes.rb | node['rackspace_cloudmonitoring']['auth']['databag']['item'] |

# Usage

## Recipes

This cookbook is broken up into 3 recipes:

| Recipe  | Purpose |
| ------  | ------- |
| default | Installs dependencies needed by the other recipes and LWRPs. |
| agent   | Installs and configures the Cloud Monitoring server agent daemon. |
| monitors | Parses the monitors configuration hash to configure the entity, checks, and alarms |

## Configuration hash usage

The simplest and preferred way to utilize this cookbook is via a configuration hash.
The configuration hash defines the desired monitors and alarms for the server.
The monitors recipe handles all dependencies for configuring the defined checks and will install the agent on the server.

The base namespace is node['rackspace_cloudmonitoring']['monitors'].
node['rackspace_cloudmonitoring']['monitors'] is a hash where each key is the name of a check.
The value is a second hash where the keys are the following attributes:

| Key    | Value Data type | Description | Required | API Documentation Attribute Name | Default Value | Note |
| ------ | --------------- | ----------- | -------- | -------------------------------- | ------------- | ---- |
| type   | String | Check type  | Yes      | type                             | None          | -- |
| period | Integer | The period in seconds for a check | No | period           | node['rackspace_cloudmonitoring']['monitors_defaults']['check']['period'] | The value must be greater than the minimum period set on your account. |
| timeout | Integer | The timeout in seconds for a check | No | timeout | node['rackspace_cloudmonitoring']['monitors_defaults']['check']['timeout'] | This has to be less than the period. |
| details | Hash | Detail data needed by the check | No | details | None | See API documentation for details on details. |
| disabled | Boolean | Disables the check when true | No | disabled | false | -- |
| alarm | Hash | Hash of alarms for this check.  See below. | No | N/A | None | This value is not a API value, it is specific to this cookbook. |
| entity_chef_label | string | Chef label of the entity to associate with this check | No | N/A | node['rackspace_cloudmonitoring']['monitors_defaults']['entity']['label'] | See below for a description of this |

The API documentation can be found here: [Rackspace Cloud Monitoring Developer Guide: Checks](http://docs.rackspace.com/cm/api/v1.0/cm-devguide/content/service-checks.html)
As you can see the node['rackspace_cloudmonitoring']['monitors_defaults'] node hash is used to define defaults so that common options don't need to be defined for every check.
The values for each check is passed to the rackspace_cloudmonitoring_check LWRP to create the check in the API.

The 'alarm' key for a check is very similar, and defines alarms tied to the given check.
Like the check hash, the key of the alarm hash is the name of a alarm.
The value is a fourth hash ([yo-dawg](http://i.imgur.com/b18qXaT.jpg)) where the keys are the following attributes:

| Key    | Value Data type | Description | Required | API Documentation Attribute Name | Default Value | Note |
| ------ | --------------- | ----------- | -------- | -------------------------------- | ------------- | ---- |
| conditional | string | Conditional logic to place in the alarm if() block | Yes | criteria | None | This implementation abstracts part of the criteria DSL, see below |
| disabled | Boolean | Disables the check when true | No | disabled | false | -- |
| notification_plan_idea | string | Notification Plan ID to trigger on alarm | No | notification_plan_id | node['rackspace_cloudmonitoring']['monitors_defaults']['alarm']['notification_plan_id'] | See [the API guide here](http://docs.rackspace.com/cm/api/v1.0/cm-devguide/content/service-notification-plans.html) for details on notification plans |
| entity_chef_label | string | Chef label of the entity to associate with this check | No | N/A | node['rackspace_cloudmonitoring']['monitors_defaults']['entity']['label'] | See below for a description of this |

The API documentation can be found here: [Rackspace Cloud Monitoring Developer Guide: Alarms](http://docs.rackspace.com/cm/api/v1.0/cm-devguide/content/service-alarms.html)
The values for each check is passed to the rackspace_cloudmonitoring_alarm LWRP to create the check in the API.
Also note that node['rackspace_cloudmonitoring']['monitors_defaults']['alarm']['notification_plan_id'] does not have a default.

The Monitoring alarm criteria is abstracted from the API somewhat.
The alarm threshold conditional need only be specified and will be used directly in the if() block.
The body of the criteria conditional is handled by the cookbook.
See recipes/monitors.rb for the exact abstraction and body used.

As mentioned above the monitoring entity will automatically be created or updated.
The entity behavior is configured by the following node variables:

| variable | Description |
| -------- | ----------- |
| default['rackspace_cloudmonitoring']['monitors_defaults']['entity']['label']         | Label for the entity   |
| default['rackspace_cloudmonitoring']['monitors_defaults']['entity']['ip_addresses']  | IP addresses to set in the API |
| default['rackspace_cloudmonitoring']['monitors_defaults']['entity']['search_method'] | Method to use to search for existing entities |
| default['rackspace_cloudmonitoring']['monitors_defaults']['entity']['search_ip']     | IP to use when searching by IP |

Defaults for all are in attributes/default.rb.
See the entity LWRP description below for details about the search method.
For Rackspace Cloud Servers the defaults will result in the existing, automatically generated entity being reused.
Checks and Alarms need to reference the entity and will use the Chef label to do so.

### Configuration Hash Example

The following example configures CPU, load, disk, and filesystem monitors, with alarms enabled on the 5 minute load average:

```ruby
# Calculate default values
# Critical at x4 CPU count
cpu_critical_threshold = (node['cpu']['total'] * 4)
# Warning at x2 CPU count
cpu_warning_threshold = (node['cpu']['total'] * 2)

# Define our monitors
node.default['rackspace_cloudmonitoring']['monitors'] = {
  'cpu' =>  { 'type' => 'agent.cpu', },
  'load' => { 'type'  => 'agent.load_average',
    'alarm' => {
      'CRITICAL' => { 'conditional' => "metric['5m'] > #{cpu_critical_threshold}", },
      'WARNING'  => { 'conditional' => "metric['5m'] > #{cpu_warning_threshold}", },
    },
  },

  'disk' => {
    'type' => 'agent.disk',
    'details' => { 'target' => '/dev/xvda1'},
  },
  'root_filesystem' => {
    'type' => 'agent.filesystem',
    'details' => { 'target' => '/'},
  },
}

#
# Call the monitoring cookbook with our changes
#
include_recipe "rackspace_cloudmonitoring::monitors"
```

The previous example assumes that the API key and API username are set via the node attributes or a databag, and that node['rackspace_cloudmonitoring']['monitors_defaults']['alarm']['notification_plan_id'] is set.

NOTE: Earlier revisions assumed the check was of the "agent." type and automatically prepended "agent.".
This behavior has been removed to allow remote checks, the full name of the check must now be passed!

## Agent Recipe

The agent recipe installs the monitoring agent on the node.
It is called by the monitors recipe so the agent is installed automatically when using the method above.
With the API key and username set it is essentially standalone, it will call the agent_token LWRP to generate a token.

However, the following attributes can be set to bypass API calls and configure the agent completely from node attributes:

| Attribute | Description |
| --------- | ----------- |
| node['rackspace_cloudmonitoring']['config']['agent']['token'] | Agent Token |
| node['rackspace_cloudmonitoring']['config']['agent']['id']    | Agent ID    |

Note that BOTH must be set to bypass API calls.
The ID will be overwritten if only the token is passed.
See the API docs for exact details of these values.

The agent recipe also supports a configuration hash for pulling in plugins.
Plugin directories can be added to the node['rackspace_cloudmonitoring']['agent']['plugins'] hash to install plugins for the agent.
The syntax is node['rackspace_cloudmonitoring']['agent']['plugins'][cookbook] = directory and utilizes the remote_directory chef LWRP.
So to install a plugin at directory foo_dir in cookbook bar_book use:

    node.default['rackspace_cloudmonitoring']['agent']['plugins']['bar_book'] = 'foo_dir'

## LWRP Usage

This cookbook exposes LWRPs to operate on Monitoring API objects at a lower level.
Direct interaction with LWRPs is not required when using the monitors.rb argument hash method.
General precedence for the LWRPs are:

```
Alarm
 | Requires Check Label, Entity Chef Label
 |
 +-> Check
      | Requires Entity Chef Label
	  | 
	  +-> Entity
	       | (Optional) Uses Agent ID
		   |
		   +-> Agent Token
```

A key note is that the UID for an object in the Monitoring API is generated when the object is created.
So the API create action returns the unique identifier which must then be used from then on to reference the object.
This flows counter to Chef where you assign a unique label at creation, and use that label from then on.
The underlying library works to abstract this as much as possible, but it is beneficial to keep in mind, especially with entity objects.

LWRP examples are not provided as LWRPs are considered advanced usage and use of the monitors.rb recipe cookbook is preferred.
However, examples for all LWRPs can be found in this cookbook's recipes.

### Agent Token

This LWRP interacts with the API to create Agent tokens.

The LWRP itself is quite simple, it only takes one argument in addition to the label:

| Option | Description                  | Required | Note |
| ------ | -----------                  | -------- | ---- |
| token  | Monitoring agent token value | No       |      |

The API documentation can be found here: [Rackspace Cloud Monitoring Developer Guide: Agent Tokens](http://docs.rackspace.com/cm/api/v1.0/cm-devguide/content/service-agent-tokens.html)
The label is the only updatable attribute, and the chef LWRP label is used for the API label.

### Entity

This LWRP interacts with the API to create, and delete entity API objects.

| Option | Description | Required | Note |
| ------ | ----------- | -------- | ---- |
| api_label     | Label to use for the label in the API | No | Defaults to the Chef LWRP label |
| metadata      | Metadata for the entity | No |  |
| ip_addresses  | IP addresses that can be referenced by checks on this entity. | No | See API docs |
| agent_id      | ID of the agent associated with his server | No |  |
| search_method | Method to use for locating existing entities | No | See below for details |
| search_ip     | IP to use for IP search | No | See below for details |
| rackspace_api_key | API key to use | No | See Credential Handling for further details |
| rackspace_username| API username to use | No | See Credential Handling for further details |
| rackspace_auth_url| API auth URL to use | No | See Credential Handling for further details |

The API documentation can be found here: [Rackspace Cloud Monitoring Developer Guide: Entities](http://docs.rackspace.com/cm/api/v1.0/cm-devguide/content/service-entities.html)

Unfortunately the label is often not sufficient to locate a proper existing entity due to various factors.
For this, a number of search methods are provided to locate existing entities via the search_method attribute:

| Method | Key used | Matched to |
| ------ | -------- | ---------- |
| [default] | Chef LWRP label | API Label |
| ip      | search_ip argument | Any IP associated with the entity |
| id      | search_id argument | API ID |
| api_label | api_label argument | API Label |

ip is recommend as the easiest method.
id is the most reliable, but the id is not exposed outside of the underlying library.

### Check

This LWRP interacts with the API to create, and delete check API objects.

| Option | Description | Required | Note |
| ------ | ----------- | -------- | ---- |
| entity_chef_label       | The Chef label of the entity to associate to | Yes |  |
| type                    | The type of check | No |See API docs |
| details                 | Details of the check | No |See API docs |
| metadata                | Metadata to associate with the check  | No | See API docs |
| period                  | The period in seconds for a check.  | No | Has restrictions, See API docs |
| timeout                 | The timeout in seconds for a check. | No | Has restrictions, See API docs |
| disabled                | Disables the check when true        | No | |
| target_alias            | (Remote Checks) Key in the entity's 'ip_addresses' hash used to resolve remote check to an IP address. | No | Has restrictions, See API docs |
| target_resolver         | (Remote Checks) Determines how to resolve the remote check target.  | No | See API docs |
| target_hostname         | (Remote Checks) The hostname remote check should target. | No | Has restrictions, See API docs |
| monitoring_zones_poll   | (Remote Checks) Monitoring zones to poll from for remote checks | No | See API Docs |
| rackspace_api_key | API key to use | No | See Credential Handling for further details |
| rackspace_username| API username to use | No | See Credential Handling for further details |
| rackspace_auth_url| API auth URL to use | No | See Credential Handling for further details |

The Chef label is used for the API label, which is used for searching.  Multiple checks on one entity with the same label in the API are NOT supported.
The vast majority of objects are passed through to the API.
The Entity LWRP for the associated entity object must have already been called.
The API documentation can be found here: [Rackspace Cloud Monitoring Developer Guide: Checks](http://docs.rackspace.com/cm/api/v1.0/cm-devguide/content/service-checks.html)

### Alarms

This LWRP interacts with the API to create, and delete alarm API objects.

| Option | Description | Required | Note |
| ------ | ----------- | -------- | ---- |
| entity_chef_label    | The Chef label of the entity to associate to | Yes |  |
| notification_plan_id | The Notification plan to use for this alarm | Yes | See [the API guide here](http://docs.rackspace.com/cm/api/v1.0/cm-devguide/content/service-notification-plans.html) for details on notification plans |
| check_id             | API ID of the underlying check | No | check_id or check_label is required |
| check_label          | Label of the underlying check  | No | check_id or check_label is required |
| metadata             | Metadata to associate with the check  | No | See API docs |
| criteria             | Alarm Criteria | No | See API docs, cannot be used with example criteria |
| disabled                | Disables the check when true        | No | |
| example_id           | Example criteria ID | No | See API docs, cannot be used with criteria
| example_values       | Example criteria values | When using example_id | See API docs |
| rackspace_api_key | API key to use | No | See Credential Handling for further details |
| rackspace_username| API username to use | No | See Credential Handling for further details |
| rackspace_auth_url| API auth URL to use | No | See Credential Handling for further details |

The Chef label is used for the API label, which is used for searching.  Multiple alarms on one ENTITY (not check) with the same label in the API are NOT supported.
The vast majority of objects are passed through to the API.
The Check and Entity LWRPs for the associated check and entity object must Hanover already been called.
The API documentation can be found here: [Rackspace Cloud Monitoring Developer Guide: Alarms](http://docs.rackspace.com/cm/api/v1.0/cm-devguide/content/service-alarms.html)

License & Authors
-----------------
- v2.0.0 Author: Tom Noonan II (<thomas.noonan@rackspace.com>)

```
Copyright:: 2012 - 2014 Rackspace

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```
