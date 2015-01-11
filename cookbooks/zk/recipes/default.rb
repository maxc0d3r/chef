#
# Cookbook Name:: zookeeper
# Recipe:: default
#
# Copyright 2014, Indix
#
# All rights reserved - Do Not Redistribute
#
include_recipe "java"
include_recipe "runit"

group node["zookeeper"]["group"]

user node["zookeeper"]["user"] do
  comment "Kafka user"
  gid "#{node["zookeeper"]["group"]}"
  shell "/bin/bash"
  supports :manage_home => false
end

directory "#{node["zookeeper"]["log_dir"]}" do
  owner "#{node["zookeeper"]["user"]}"
  group "#{node["zookeeper"]["user"]}"
  mode "0755"
end

directory "#{node["zookeeper"]["data_dir"]}" do
  owner "#{node["zookeeper"]["user"]}"
  group "#{node["zookeeper"]["user"]}"
  mode "0755"
end

directory "#{node["zookeeper"]["install_dir"]}" do
  owner "#{node["zookeeper"]["user"]}"
  group "#{node["zookeeper"]["user"]}"
  mode "0755"
  recursive true
end

bash "setup_zookeeper" do
  user "root"
  code <<-EOH
    cd /tmp
    rm -f zookeeper-#{node["zookeeper"]["version"]}.tar.gz
    rm -rf zookeeper-#{node["zookeeper"]["version"]}
    rm -rf #{node["zookeeper"]["install_dir"]}/zookeeper-#{node["zookeeper"]["version"]}
    wget #{node["zookeeper"]["url"]}/zookeeper-#{node["zookeeper"]["version"]}/zookeeper-#{node["zookeeper"]["version"]}.tar.gz
    tar -zxf zookeeper-#{node["zookeeper"]["version"]}.tar.gz && mv zookeeper-#{node["zookeeper"]["version"]} #{node["zookeeper"]["install_dir"]}
    ln -sf #{node["zookeeper"]["install_dir"]}/zookeeper-#{node["zookeeper"]["version"]} #{node["zookeeper"]["app_dir"]}
    chown -R #{node["zookeeper"]["user"]}:#{node["zookeeper"]["user"]} #{node["zookeeper"]["data_dir"]}
    chown -R #{node["zookeeper"]["user"]}:#{node["zookeeper"]["user"]} #{node["zookeeper"]["app_dir"]}
    chown -R #{node["zookeeper"]["user"]}:#{node["zookeeper"]["user"]} #{node["zookeeper"]["install_dir"]}/zookeeper-#{node["zookeeper"]["version"]}
  EOH
  creates "#{node["zookeeper"]["install_dir"]}/zookeeper-#{node["zookeeper"]["version"]}"
end

link "#{node["zookeeper"]["app_dir"]}/logs" do
  to "#{node["zookeeper"]["log_dir"]}"
  owner "#{node["zookeeper"]["user"]}"
  group "#{node["zookeeper"]["user"]}"
end

cookbook_file "#{node["zookeeper"]["app_dir"]}/bin/zkEnv.sh" do
  source "#{node["zookeeper"]["app_dir"]}/bin/zkEnv.sh"
  owner "#{node["zookeeper"]["user"]}"
  group "#{node["zookeeper"]["user"]}"
  mode "0755"
end

zk_quorum = Array.new
if not Chef::Config.solo
  search(:node, "role:kafka_zk").each do |zk_nodes|
    zk_quorum << zk_nodes
  end
end

template "#{node["zookeeper"]["app_dir"]}/conf/zoo.cfg" do
	source "#{node["zookeeper"]["app_dir"]}/conf/zoo.cfg.erb"
	owner "#{node["zookeeper"]["user"]}"
	group "#{node["zookeeper"]["user"]}"
	mode "0644"
  variables ({
    :zk_quorum => zk_quorum
  })
end

cookbook_file "#{node["zookeeper"]["app_dir"]}/conf/log4j.properties" do
  source "#{node["zookeeper"]["app_dir"]}/conf/log4j.properties"
  owner "#{node["zookeeper"]["user"]}"
  group "#{node["zookeeper"]["user"]}"
  mode "0644"
end

file "#{node["zookeeper"]["data_dir"]}/myid" do
	content node["ipaddress"].gsub(".","")
	owner "#{node["zookeeper"]["user"]}"
	group "#{node["zookeeper"]["user"]}"
	mode "0644"
	action :create_if_missing
end

if zk_quorum.length >= 3
  runit_service "zookeeper"
end
