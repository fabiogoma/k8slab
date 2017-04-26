cookbook_file '/etc/selinux/config' do
  source 'etc/selinux/config'
  owner 'root'
  group 'root'
  mode '0644  '
  action :create
end

execute 'setenfore' do
  command 'setenforce 0'
  action :run
end

service 'firewalld' do
  supports status: true, restart: true, reload: true
  action [:disable, :stop]
end
