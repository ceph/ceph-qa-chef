# Use our pip mirror
include_recipe "ceph-qa::pip_mirror"
include_recipe "ceph-qa::brokencloud"

#Local Epel Mirror:
cookbook_file '/etc/yum.repos.d/epel.repo' do
  source "epel6.repo"
  mode 0755
  owner "root"
  group "root"
end
cookbook_file '/etc/yum.repos.d/epel-testing.repo' do
  source "epel6-testing.repo"
  mode 0755
  owner "root"
  group "root"
end

#Local Repo Mirror
file '/etc/yum.repos.d/rhel6.repo' do
  owner 'root'
  group 'root'
  mode '0644'
  content <<-EOH
[rhel6-server]
name=My Red Hat Enterprise Linux Server $releasever - $basearch
baseurl=http://apt-mirror.front.sepia.ceph.com/rhel6repo-server/
gpgcheck=0
enabled=1
  EOH
end

#Local Repo Mirror
file '/etc/yum.repos.d/rhel6-server-optional.repo' do
  owner 'root'
  group 'root'
  mode '0644'
  content <<-EOH
[rhel6-server-optional]
name=My Red Hat Enterprise Linux Optional $releasever - $basearch
baseurl=http://apt-mirror.front.sepia.ceph.com/rhel6repo-server-optional
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
[centos6-qemu-ceph]
name=Cent OS 6 Local Qemu Repo
baseurl=http://ceph.com/packages/ceph-extras/rpm/rhel6/x86_64/
gpgcheck=0
enabled=1
priority=2
  EOH
end


file '/etc/yum.repos.d/apache-ceph.repo' do
  owner 'root'
  group 'root'
  mode '0644'
  content <<-EOH
[centos6-apache-ceph]
name=Cent OS 6 Local apache Repo
baseurl=http://gitbuilder.ceph.com/apache2-rpm-rhel6-x86_64-basic/ref/master/
gpgcheck=0
enabled=1
priority=2
  EOH
end

file '/etc/yum.repos.d/fcgi-ceph.repo' do
  owner 'root'
  group 'root'
  mode '0644'
  content <<-EOH
[centos6-fcgi-ceph]
name=Cent OS 6 Local fastcgi Repo
baseurl=http://gitbuilder.ceph.com/mod_fastcgi-rpm-rhel6-x86_64-basic/ref/master/
gpgcheck=0
enabled=1
priority=2
  EOH
end

file '/etc/yum.repos.d/misc-ceph.repo' do
  owner 'root'
  group 'root'
  mode '0644'
  content <<-EOH
[centos6-misc-ceph]
name=Cent OS 6 Local misc Repo
baseurl=http://apt-mirror.front.sepia.ceph.com/misc-rpms/
gpgcheck=0
enabled=1
priority=2
  EOH
end

file '/etc/yum.repos.d/ceph.repo' do
  owner 'root'
  group 'root'
  mode '0644'
  content <<-EOH
[centos6-ceph]
name=Cent OS 6 Local ceph Repo
baseurl=http://ceph.com/rpm-cuttlefish/rhel6/x86_64/
gpgcheck=0
enabled=1
priority=2
  EOH
end

execute "Clearing yum cache" do
  command "yum clean all"
end

execute "Clearing out previously installed verisons of ceph" do
  command "for package in ceph ceph-common ceph-debuginfo ceph-release libcephfs1 ceph-radosgw python-ceph librbd1 librados2; do yum remove -y $package|| true; done"
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
package 'fuse'
package 'fuse-libs'

#ceph deploy
package 'python-virtualenv'


# for setting BIOS settings
package 'smbios-utils'


package 'openssl'
package 'libuuid'
package 'btrfs-progs'
  
 
# used by workunits
package 'attr'
package 'valgrind'
package 'python-nose'
package 'mpich2'
package 'ant'
package 'dbench'
package 'bonnie++'
package 'fuse-sshfs'
package 'fsstress'

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
package 'librados2' do
  version '0.61.9-0.el6'
end
package 'librbd1' do
  version '0.61.9-0.el6'
end
package 'qemu-img' do
  version '0.12.1.2-2.415.el6.3ceph'
end
package 'qemu-kvm' do
  version '0.12.1.2-2.415.el6.3ceph'
end
package 'qemu-kvm-tools' do
  version '0.12.1.2-2.415.el6.3ceph'
end
package 'qemu-guest-agent' do
  version '0.12.1.2-2.415.el6.3ceph'
end
package 'genisoimage'


#Rados GW

#Force downgrade of packages doesnt work on older chef, uninstall first.
package 'httpd' do
  action :remove
end
package 'http-devel' do
  action :remove
end
package 'httpd-tools' do
  action :remove
end
package 'mod_ssl' do
  version '2.2.22-1.ceph.el6'
end
package 'httpd' do
  version '2.2.22-1.ceph.el6'
end
package 'httpd-tools' do
  version '2.2.22-1.ceph.el6'
end
package 'httpd-devel' do
  version '2.2.22-1.ceph.el6'
end
package 'mod_fastcgi' do
  version '2.4.7-1.ceph.el6'
end
service "httpd" do
  action [ :disable, :stop ]
end


package 'python-pip'
package 'libevent-devel'

# for json_xs to investigate JSON by hand
package 'perl-JSON-XS'
  
# for pretty-printing xml
package 'perl-XML-Twig'
  
# for java bindings, hadoop, etc.
package 'java-1.6.0-openjdk-devel'
package 'junit4'
  
# tgt & open-iscsi
package 'scsi-target-utils'
package 'iscsi-initiator-utils'

# for disk/etc monitoring
package 'smartmontools'

#NTP
include_recipe "ceph-qa::ntp-rpm"

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

execute "FStest ubuntu dir" do
  command "mkdir -p /usr/lib/ltp/testcases/bin"
end

execute "Make fsstress same path as ubuntu" do
  command "ln -sf /usr/bin/fsstress /usr/lib/ltp/testcases/bin/fsstress"
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

bash "ssh_max_sessions" do
  user "root"
  cwd "/etc/ssh"
  code <<-EOT
    echo "MaxSessions 1000" >> sshd_config
  EOT
  not_if {File.read("/etc/ssh/sshd_config") =~ /^MaxSessions/}
end

service "sshd" do
  action [:restart]
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
