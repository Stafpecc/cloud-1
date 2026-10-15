Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-22.04"

  {
    "srv1" => "192.168.56.10",
    "srv2" => "192.168.56.11"
  }.each do |name, ip|
    config.vm.define name do |node|
      node.vm.hostname = name
      node.vm.network "private_network", ip: ip
      node.vm.provider "virtualbox" do |vb|
        vb.name = "cloud1-#{name}"
        vb.memory = 2048
        vb.cpus = 1
      end
    end
  end
end