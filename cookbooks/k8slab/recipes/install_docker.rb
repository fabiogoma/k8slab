package 'docker' do
  action :install
end

group 'docker' do
  members 'vagrant'
  action :create
  append true
end

cookbook_file '/etc/docker/daemon.json' do
  source 'etc/docker/daemon.json'
  owner 'root'
  group 'root'
  mode '0644  '
  action :create
end

service 'docker' do
  supports status: true, restart: true, reload: true
  action [:enable, :restart]
end
