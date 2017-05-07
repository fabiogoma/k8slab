boxes = %w(kube1 kube2 kube3 kube4)
# boxes = %w(kube1 kube2)

Vagrant.configure('2') do |config|
  config.vm.box = 'centos/7'
  config.vm.box_version = '1703.01'
  config.vm.network 'public_network', bridge: 'wlp8s0'

  config.vm.provider :virtualbox do |vb|
    vb.customize ['modifyvm', :id, '--natdnshostresolver1', 'on']
    vb.customize ['modifyvm', :id, '--natdnsproxy1', 'on']
  end

  config.vm.synced_folder '.', '/vagrant', disabled: true

  boxes.each do |box|
    config.vm.define box.to_s do |node|
      node.vm.hostname = box.to_s
      node.vm.provision 'chef_solo' do |chef|
        chef.synced_folder_type = 'rsync'
        chef.add_recipe 'k8slab'
      end
    end
  end
end
