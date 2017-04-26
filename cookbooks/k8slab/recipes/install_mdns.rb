package 'epel-release' do
  action :install
end

package ['nss-mdns', 'net-tools', 'telnet', 'tcpdump', 'lsof', 'strace'] do
  action :install
end

cookbook_file '/etc/avahi/avahi-daemon.conf' do
  source 'etc/avahi/avahi-daemon.conf'
  owner 'root'
  group 'root'
  mode '0644  '
  action :create
end

service 'avahi-daemon' do
  supports status: true, restart: true, reload: true
  action [:enable, :restart]
end
