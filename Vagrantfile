Vagrant.configure(2) do |config|
    config.vm.box = "ubuntu/bionic64"
    config.vm.define "web" do |web|
        web.vm.network "private_network", ip: "192.168.10.10"
        web.vm.network "forwarded_port", host: 8080, guest: 80
        web.vm.provision :shell, path: "bootstrap.sh"
        web.vm.synced_folder "data/config/", "/usr/local/config/data/"
        web.vm.synced_folder "web/config/", "/usr/local/config/web/"
        web.vm.synced_folder "web/dev/", "/var/www/dev/", owner: "www-data", group: "www-data"
        web.vm.provider "virtualbox" do |v|
            v.name = "web.campingverna"
            v.memory = 1024
        end
    end
end
