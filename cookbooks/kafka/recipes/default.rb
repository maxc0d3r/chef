#
# Cookbook Name:: kafka
# Recipe:: default
#
# Copyright 2015, Indix
#
# All rights reserved - Do Not Redistribute
#
include_recipe "runit"

kafka_nodes = Array.new
if not Chef::Config.solo
  kafka_nodes = search(:node, "role:kafka AND chef_environment:#{node.chef_environment}")
end

template "/etc/hosts" do
  source "system/hosts.erb"
  owner "root"
  group "root"
  variables({
    :kafka_nodes => kafka_nodes
  })
end

group node["kafka"]["group"]

user node["kafka"]["user"] do
  comment "Kafka user"
  gid "#{node["kafka"]["group"]}"
  shell "/bin/bash"
  supports :manage_home => false
end

directory "#{node["kafka"]["log_dir"]}" do
  owner "#{node["kafka"]["user"]}"
  group "#{node["kafka"]["user"]}"
  mode "0755"
end

directory "#{node["kafka"]["install_dir"]}" do
  owner "#{node["kafka"]["user"]}"
  group "#{node["kafka"]["user"]}"
  mode "0755"
  recursive true
end

bash "setup_kafka" do
  user "root"
  code <<-EOH
  cd /tmp
  wget #{node["kafka"]["url"]}/#{node["kafka"]["version"]}/kafka_#{node["kafka"]["scala"]["version"]}-#{node["kafka"]["version"]}.tgz
  tar -zxf kafka_#{node["kafka"]["scala"]["version"]}-#{node["kafka"]["version"]}.tgz
  mv kafka_#{node["kafka"]["scala"]["version"]}-#{node["kafka"]["version"]} #{node["kafka"]["install_dir"]}
  chown -R #{node["kafka"]["user"]}:#{node["kafka"]["user"]} #{node["kafka"]["install_dir"]}/kafka_#{node["kafka"]["scala"]["version"]}-#{node["kafka"]["version"]}
  EOH
  not_if { File.directory?("#{node["kafka"]["install_dir"]}/kafka_#{node["kafka"]["scala"]["version"]}-#{node["kafka"]["version"]}") }
end

link "#{node["kafka"]["app_dir"]}" do
  to "#{node["kafka"]["install_dir"]}/kafka_#{node["kafka"]["scala"]["version"]}-#{node["kafka"]["version"]}"
  owner "#{node["kafka"]["user"]}"
  group "#{node["kafka"]["user"]}"
end

zk_quorum = Array.new
if not Chef::Config.solo
  search(:node, "role:kafka_zk").each do |zk_nodes|
    zk_quorum << "#{zk_nodes["fqdn"]}:#{zk_nodes["zookeeper"]["clientPort"]}"
  end
end

template "#{node["kafka"]["app_dir"]}/config/server.properties" do
  source "kafka/server.properties.erb"
  owner "#{node["kafka"]["user"]}"
  group "#{node["kafka"]["user"]}"
  mode "0644"
  variables ({
      :zk_quorum => zk_quorum
  })
end

template "#{node["kafka"]["app_dir"]}/bin/service-control" do
  source "system/service-control.erb"
  owner "#{node["kafka"]["user"]}"
  group "#{node["kafka"]["user"]}"
  mode "0755"
  variables ({
    :install_dir => node["kafka"]["app_dir"],
    :log_dir => node["kafka"]["log_dir"],
    :java_home => node['java']['java_home'],
    :java_class => "kafka.Kafka",
    :user => node["kafka"]["user"]
  })
end

if zk_quorum.length >= 3
  runit_service "kafka" do
    options({
      :install_dir => node["kafka"]["app_dir"],
      :user => node["kafka"]["user"]
    })
  end
end
