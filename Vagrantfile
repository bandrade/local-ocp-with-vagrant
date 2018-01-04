require 'socket'

hostname = Socket.gethostname
disks = 'lab-ocp3.6/' 
config_playbook = "/usr/share/ansible/openshift-ansible/playbooks/byo/config.yml"
localmachineip = IPSocket.getaddress(Socket.gethostname)
puts %Q{ This machine has the IP '#{localmachineip} and host name '#{hostname}'}

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = '2'

REQUIRED_PLUGINS = %w(vagrant-hostmanager)
SUGGESTED_PLUGINS = %w(vagrant-sshfs landrush)

def message(name)
  "#{name} plugin is not installed, run `vagrant plugin install #{name}` to install it."
end

SUGGESTED_PLUGINS.each { |plugin| print("note: " + message(plugin) + "\n") unless Vagrant.has_plugin?(plugin) }
sync_type = 'sshfs'
errors = []

# Validate and collect error message if plugin is not installed
REQUIRED_PLUGINS.each { |plugin| errors << message(plugin) unless Vagrant.has_plugin?(plugin) }
unless errors.empty?
  msg = errors.size > 1 ? "Errors: \n* #{errors.join("\n* ")}" : "Error: #{errors.first}"
  fail Vagrant::Errors::VagrantError.new, msg
end


override_box_url = ''
box_name = 'rhel-7.2'

NETWORK_BASE = '192.168.50'
INTEGRATION_START_SEGMENT = 20

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|


  config.registration.skip = true
  config.registration.unregister_on_halt = false
  config.hostmanager.enabled = true
  config.hostmanager.manage_host = true
  config.hostmanager.ignore_private_ip = false
#  config.hostmanager.include_offline = true
  
  if Vagrant.has_plugin?('landrush')
    config.landrush.enabled = true
    config.landrush.tld = 'example.com'
    config.landrush.guest_redirect_dns = false
  end

  # Configure eth0 via script, will disable NetworkManager and enable legacy network daemon:
  config.vm.provision "shell", path: "provision/setup.sh", args: [NETWORK_BASE]

  config.vm.provider "virtualbox" do |v, override|
    #v.customize ["setextradata", :id, "VBoxInternal2/SharedFoldersEnableSymlinksCreate//vagrant","1"]
    v.memory = 1024
    v.cpus = 1
    override.vm.box = box_name
    provider_name = 'virtualbox'
  end

  config.vm.provider "libvirt" do |libvirt, override|
    libvirt.cpus = 1
    libvirt.memory = 1024
    libvirt.driver = 'kvm'
    override.vm.box = box_name
    provider_name = 'libvirt'
  end

  # Suppress the default sync in both CentOS base and CentOS Atomic Host
  config.vm.synced_folder '.', '/vagrant', disabled: true
  config.vm.synced_folder '.', '/home/vagrant/sync', disabled: true

  config.vm.define "master1" do |master1|
    master1.vm.network :private_network, ip: "#{NETWORK_BASE}.#{INTEGRATION_START_SEGMENT}"
    master1.vm.hostname = "master1.example.com"
    master1.hostmanager.aliases = %w(master1)
    selected_disk= disks + "master1.vdi"
    master1.vm.provider :virtualbox do |domain|
    unless File.exist?(selected_disk)
        domain.customize ['createhd', '--filename', selected_disk, '--size', 10 * 1024]
      end
      domain.customize ['storageattach', :id, '--storagectl', 'SATA', '--port', 1, '--device', 0, '--type', 'hdd', '--medium', selected_disk]
   end
  end

  config.vm.define "node1" do |node1|
    node1.vm.network :private_network, ip: "#{NETWORK_BASE}.#{INTEGRATION_START_SEGMENT + 2}"
    node1.vm.hostname = "node1.example.com"
    node1.hostmanager.aliases = %w(node1)
    selected_disk= disks + "node1.vdi"
    node1.vm.provider :virtualbox do |domain|
    unless File.exist?(selected_disk)
        domain.customize ['createhd', '--filename', selected_disk, '--size', 10 * 1024]
      end
      domain.customize ['storageattach', :id, '--storagectl', 'SATA', '--port', 1, '--device', 0, '--type', 'hdd', '--medium', selected_disk]
      domain.memory = 3096
   end
  end

  config.vm.define "node2" do |node2|
    node2.vm.network :private_network, ip: "#{NETWORK_BASE}.#{INTEGRATION_START_SEGMENT + 3}"
    node2.vm.hostname = "node2.example.com"
    node2.hostmanager.aliases = %w(node2)
    selected_disk= disks + "node2.vdi"
    node2.vm.provider :virtualbox do |domain|
    unless File.exist?(selected_disk)
        domain.customize ['createhd', '--filename', selected_disk, '--size', 10 * 1024]
      end
      domain.customize ['storageattach', :id, '--storagectl', 'SATA', '--port', 1, '--device', 0, '--type', 'hdd', '--medium', selected_disk]
      domain.memory = 3096
   end
  end
 
  config.vm.define "infranode1" do |infranode1|
    infranode1.vm.network :private_network, ip: "#{NETWORK_BASE}.#{INTEGRATION_START_SEGMENT + 4}"
    infranode1.vm.hostname = "infranode1.example.com"
    infranode1.hostmanager.aliases = %w(infra-node1)
    selected_disk= disks + "infranode1.vdi"
    infranode1.vm.provider :virtualbox do |domain|
	domain.memory = 4096
        unless File.exist?(selected_disk)
          domain.customize ['createhd', '--filename', selected_disk, '--size', 10 * 1024]
        end
        domain.customize ['storageattach', :id, '--storagectl', 'SATA', '--port', 1, '--device', 0, '--type', 'hdd', '--medium', selected_disk]
    end

  end

  config.vm.define "admin1" do |admin1|
    admin1.vm.network :private_network, ip: "#{NETWORK_BASE}.#{INTEGRATION_START_SEGMENT + 6}"
    admin1.vm.hostname = "admin1.example.com"
    admin1.hostmanager.aliases = %w(admin1)
    admin1.vm.provider :virtualbox do |domain|
        domain.memory = 512 
    end
    


    admin1.vm.provision :ansible_local do |ansible|
      ansible.verbose        = true
      ansible.install        = true
      ansible.limit          = 'OSEv3:localhost'
      ansible.provisioning_path = '/home/vagrant/sync/vagrant'
      ansible.playbook       = '/home/vagrant/sync/vagrant/install.yaml'
      ansible.inventory_path  = '/home/vagrant/sync/vagrant/inventory'
    end
    
    admin1.vm.synced_folder "..", "/home/vagrant/sync", type: sync_type
    admin1.vm.synced_folder ".vagrant", "/home/vagrant/.hidden", type: sync_type
 
    admin1.vm.provision :ansible_local do |ansible|
      ansible.verbose        = true
      ansible.install        = false
      ansible.limit          = "OSEv3:localhost"
      ansible.provisioning_path = '/home/vagrant/sync/vagrant'
      ansible.playbook = config_playbook
      ansible.inventory_path  = '/home/vagrant/sync/vagrant/inventory'

    end

  end
end
