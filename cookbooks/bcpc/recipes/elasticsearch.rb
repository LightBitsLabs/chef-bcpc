#
# Cookbook Name:: bcpc
# Recipe:: elasticsearch
#
# Copyright 2013, Bloomberg Finance L.P.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

if node['bcpc']['enabled']['logging'] then

    include_recipe "bcpc::default"

    apt_repository 'elasticsearch' do
        uri node['bcpc']['repos']['elasticsearch']
        distribution 'stable'
        components ['main']
        key 'elasticsearch.key'
    end

    package "openjdk-7-jre-headless" do
        action :install
    end

    package 'elasticsearch' do
        action :install
    end

    cookbook_file "/usr/local/bin/ess-shard-rebalancing" do
        source "ess-shard-rebalancing"
        owner "root"
        group "root"
        mode 00755
    end

    template "/etc/default/elasticsearch" do
        source "elasticsearch-default.erb"
        owner "root"
        group "root"
        mode 00644
        variables(
            :es_heap_size => node['bcpc']['elasticsearch']['heap_size'],
            :es_java_opts => node['bcpc']['elasticsearch']['java_opts']
        )
        notifies :restart, "service[elasticsearch]", :delayed
    end

    service "elasticsearch" do
        action [:enable, :start]
    end

    template "/etc/elasticsearch/elasticsearch.yml" do
        source "elasticsearch.yml.erb"
        owner "root"
        group "root"
        mode 00644
        variables(
            :servers => search_nodes("recipe", "elasticsearch"),
            :min_quorum => search_nodes("recipe", "elasticsearch").length/2 + 1
        )
        notifies :restart, "service[elasticsearch]", :immediately
    end

    directory "/usr/share/elasticsearch/plugins" do
        owner "root"
        group "root"
        mode 00755
    end

    cookbook_file "/tmp/elasticsearch-plugins.tgz" do
        source "bins/elasticsearch-plugins.tgz"
        owner "root"
        mode 00444
    end

    bash "install-elasticsearch-plugins" do
        code <<-EOH
            tar zxf /tmp/elasticsearch-plugins.tgz -C /usr/share/elasticsearch/plugins/
        EOH
        not_if "test -d /usr/share/elasticsearch/plugins/head"
    end

    package "curl" do
        action :upgrade
    end

    bash "set-elasticsearch-replicas" do
        min_quorum = search_nodes("recipe", "elasticsearch").length/2 + 1
        code <<-EOH
            curl -XPUT '#{node['bcpc']['monitoring']['vip']}:9200/_settings' -d '
            {
                "index" : {
                    "number_of_replicas" : #{min_quorum-1}
                }
            }
            '
        EOH
    end

end
