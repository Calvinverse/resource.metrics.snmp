# frozen_string_literal: true

#
# Cookbook Name:: resource_metrics_snmp
# Recipe:: default
#
# Copyright 2018, P. van der Velde
#

# Always make sure that apt is up to date
apt_update 'update' do
  action :update
end

#
# Include the local recipes
#

include_recipe 'resource_metrics_snmp::firewall'

include_recipe 'resource_metrics_snmp::meta'
include_recipe 'resource_metrics_snmp::provisioning'

include_recipe 'resource_metrics_snmp::snmp'
