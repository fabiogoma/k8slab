# Defining the master and minions names
master_name = 'kube1'
master_eth1 = ip = node['network']['interfaces']['eth1']['addresses'].keys[1]
minion_name = node['hostname']

# Preparing the yum repo for kubernetes instalation
cookbook_file '/etc/yum.repos.d/kubernetes.repo' do
  source 'etc/yum.repos.d/kubernetes.repo'
  owner 'root'
  group 'root'
  mode '0644  '
  action :create
end

# Installing kubernetes etcd and flannel on every host
package ['kubernetes', 'etcd', 'flannel'] do
  action :install
end

# Preparing the file /etc/kubernetes/config on every host
template '/etc/kubernetes/config' do
  source 'etc/kubernetes/config.erb'
  owner 'root'
  group 'root'
  mode '0644'
  variables({
    master_name: "#{master_name}.local"
  })
  action :create
end

# Preparing /etc/etcd/etcd.conf on node master only
cookbook_file '/etc/etcd/etcd.conf' do
  source 'etc/etcd/etcd.conf'
  owner 'root'
  group 'root'
  mode '0644'
  action :create
  only_if { node['hostname'] == master_name }
end

# Preparing /etc/kubernetes/apiserver on node master only
template '/etc/kubernetes/apiserver' do
  source 'etc/kubernetes/apiserver.erb'
  owner 'root'
  group 'root'
  mode '0644'
  variables({
    master_eth1: master_eth1
  })
  action :create
  only_if { node['hostname'] == master_name }
end

# Starting etcd on node master only
service 'etcd' do
  supports status: true, restart: true, reload: true
  action [:enable, :restart]
  only_if { node['hostname'] == master_name }
end

# Preparing etcd to provide network configuration on node master only
execute 'etcd-mkdir' do
  command 'etcdctl mkdir /etc/etcd/network/'
  action :run
  only_if { node['hostname'] == master_name }
end

execute 'etcd-mk' do
  command 'etcdctl mk /etc/etcd/network/config "{ \"Network\": \"172.30.0.0/16\", \"SubnetLen\": 24, \"Backend\": { \"Type\": \"vxlan\" } }"'
  action :run
  only_if { node['hostname'] == master_name }
end

# Preparing flanneld on every node
template '/etc/sysconfig/flanneld' do
  source 'etc/sysconfig/flanneld.erb'
  owner 'root'
  group 'root'
  mode '0644'
  variables({
    master_name: "#{master_name}.local"
  })
  action :create
end

# Start the appropriate services on node master only
services = %w(etcd kube-apiserver kube-controller-manager kube-scheduler flanneld)
services.each do |service_name|
  service service_name do
    supports status: true, restart: true, reload: true
    action [:enable, :restart]
    only_if { node['hostname'] == master_name }
  end
end

# Preparing kubelet on minions nodes only
template '/etc/kubernetes/kubelet' do
  source 'etc/kubernetes/kubelet.erb'
  owner 'root'
  group 'root'
  mode '0644'
  variables({
    master_name: "#{master_name}.local",
    minion_name: "#{minion_name}.local"
  })
  action :create
  not_if { node['hostname'] == master_name }
end

services = %w(kube-proxy kubelet flanneld docker)
services.each do |service_name|
  service service_name do
    supports status: true, restart: true, reload: true
    action [:enable, :restart]
    not_if { node['hostname'] == master_name }
  end
end

execute 'set-cluster' do
  command "kubectl config set-cluster default-cluster --server=http://#{master_name}.local:8080"
  action :run
end

execute 'set-context' do
  command 'kubectl config set-context default-context --cluster=default-cluster --user=default-admin'
  action :run
end

execute 'use-context' do
  command 'kubectl config use-context default-context'
  action :run
end
