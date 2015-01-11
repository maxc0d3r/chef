#
# Role Name:: kafka_zk
#
# Copyright 2014, sychonet
# All rights reserved - Do Not Redistribute
#

name "kafka_zk"
description "Kafka Zookeeper Role"

default_attributes(
  "java" => {
    "install_flavor" => "oracle",
    "jdk_version" => "7",
    "oracle" => {
      "accept_oracle_download_terms" => true
    }
  }
)
run_list  "recipe[zk]"
