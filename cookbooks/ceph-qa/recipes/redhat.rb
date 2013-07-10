#Local Repo Mirror
file '/etc/yum.repos.d/rhel6.repo' do
  owner 'root'
  group 'root'
  mode '0644'
  content <<-EOH
[rhel-6-repo]
name=My Red Hat Enterprise Linux $releasever - $basearch
baseurl=http://apt-mirror.front.sepia.ceph.com/rhel6repo/
gpgcheck=0
enabled=1
  EOH
end

#Ceph/qemu Repo
#Local Repo
file '/etc/yum.repos.d/qemu-ceph.repo' do
  owner 'root'
  group 'root'
  mode '0644'
  content <<-EOH
[rhel-6-qemu-local]
name=RHEL 6 QEMU and CEPH mirror
baseurl=http://apt-mirror.front.sepia.ceph.com/rhel6-qemu-kvm/
gpgcheck=0
enabled=1
priority=1
  EOH
end

execute "Clearing yum cache" do
  command "yum clean all"
end

#So we can make our repo highest priority
package 'yum-plugin-priorities'

package 'redhat-lsb'
package 'sysstat'
package 'gdb'
package 'python-configobj'
  
# for running ceph
package 'libedit'
package 'openssl098e'
package 'gperftools-devel'
package 'boost-thread'
package 'xfsprogs'
package 'gdisk'
package 'parted'
package 'libgcrypt'
package 'cryptopp-devel'
package 'cryptopp'

#ceph deploy
package 'python-virtualenv'


# for setting BIOS settings
package 'smbios-utils'


package 'openssl'
package 'libuuid'
package 'fcgi-devel'
package 'btrfs-progs'
  
 
# used by workunits
package 'attr'
package 'valgrind'
package 'python-nose'
package 'mpich2'
package 'ant'
package 'dbench'
package 'bonnie++'
package 'tiobench'
  
# used by the xfstests tasks
package 'libtool'
package 'automake'
package 'gettext'
package 'libuuid-devel'
package 'libacl-devel'
package 'bc'
package 'xfsdump'
  
# for blktrace and seekwatcher
package 'blktrace'
package 'numpy'
package 'python-matplotlib'
  
# for qemu:
package 'usbredir'
package 'qemu-img' do
  action :remove
end
package 'qemu-kvm' do
  action :remove
end
package 'qemu-kvm-tools' do
  action :remove
end
package 'qemu-guest-agent' do
  action :remove
end
package 'ceph-libs' do
  action :remove
end
package 'librados2'
package 'librbd1'
package 'qemu-img' do
  version '0.12.1.2-2.355.el6.2'
end
package 'qemu-kvm' do
  version '0.12.1.2-2.355.el6.2'
end
package 'qemu-kvm-tools' do
  version '0.12.1.2-2.355.el6.2'
end
package 'qemu-guest-agent' do
  version '0.12.1.2-2.355.el6.2'
end
package 'genisoimage'

# for json_xs to investigate JSON by hand
package 'perl-JSON-XS'
  
# for pretty-printing xml
package 'perl-XML-Twig'
  
# for java bindings, hadoop, etc.
package 'java-1.6.0-openjdk-devel'
package 'junit4'
  
# for disk/etc monitoring
package 'smartmontools'
package 'ntp'

cookbook_file '/etc/ntp.conf' do
  source "ntp.conf"
  mode 0644
  owner "root"
  group "root"
  notifies :restart, "service[ntpd]"
end
  
service "ntpd" do
  action [:enable,:start]
end

service "iptables" do
  action [:disable,:stop]
end

cookbook_file '/etc/security/limits.d/remote.conf' do
  source "remote.conf"
  mode 0644
  owner "root"
  group "root"
end


file '/etc/fuse.conf' do
  mode "0644"
end

execute "add user ubuntu to group kvm" do
  command "gpasswd -a ubuntu kvm"
end

execute "Make raid/smart scripts work on centos" do
  command "ln -sf /sbin/lspci /usr/bin/lspci"
end

directory '/home/ubuntu/.ssh' do
  owner "ubuntu"
  group "ubuntu"
  mode "0755"
end

#Unfortunately no megacli/arecacli package for ubuntu -- Needed for raid monitoring and smart.
cookbook_file '/usr/sbin/megacli' do
  source "megacli"
  mode 0755
  owner "root"
  group "root"
end
cookbook_file '/usr/sbin/cli64' do
  source "cli64"
  mode 0755
  owner "root"
  group "root"
end

#Custom netsaint scripts for raid/disk/smart monitoring:
directory "/usr/libexec/" do
  owner "root"
  group "root"
  mode "0755"
  action :create
end
cookbook_file '/usr/libexec/raid.pl' do
  source "raid.pl"
  mode 0755
  owner "root"
  group "root"
end
cookbook_file '/usr/libexec/smart.pl' do
  source "smart.pl"
  mode 0755
  owner "root"
  group "root"
end
cookbook_file '/usr/libexec/diskusage.pl' do
  source "diskusage.pl"
  mode 0755
  owner "root"
  group "root"
end


#SSH template for no strict host checking:
cookbook_file '/etc/ssh/ssh_config' do
  source "ssh_config"
  mode 0755
  owner "root"
  group "root"
end

#NFS servers uport per David Z.
package 'nfs-utils'

# Remove requiretty, not visiblepw and set unlimited security/limits.conf soft core value
execute "Sudoers and security/lmits.conf changes" do
  command <<-'EOH'
    sed -i 's/ requiretty/ !requiretty/g' /etc/sudoers
    sed -i 's/ !visiblepw/ visiblepw/g' /etc/sudoers
    sed -i 's/^#\*.*soft.*core.*0/\*                soft    core            unlimited/g' /etc/security/limits.conf
  EOH
end

file '/ceph-qa-ready' do
  content "ok\n"
end
