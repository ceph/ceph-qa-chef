# Use our pip mirror
include_recipe "ceph-qa::pip_mirror"

#Local Epel Mirror:
cookbook_file '/etc/yum.repos.d/epel.repo' do
  source "epel7.repo"
  mode 0755
  owner "root"
  group "root"
end


#Local Repo Mirror
file '/etc/yum.repos.d/rhel7.repo' do
  owner 'root'
  group 'root'
  mode '0644'
  content <<-EOH
[rhel-7-repo]
name=My Red Hat Enterprise Linux $releasever - $basearch
baseurl=http://apt-mirror.front.sepia.ceph.com/rhel7repo/server
gpgcheck=0
enabled=1
  EOH
end
file '/etc/yum.repos.d/rhel7-optional.repo' do
  owner 'root'
  group 'root'
  mode '0644'
  content <<-EOH
[rhel-7-optional]
name=My Red Hat Enterprise Linux $releasever - $basearch
baseurl=http://apt-mirror.front.sepia.ceph.com/rhel7repo/server-optional
gpgcheck=0
enabled=1
  EOH
end

file '/etc/yum.repos.d/rhel7-extras.repo' do
  owner 'root'
  group 'root'
  mode '0644'
  content <<-EOH
[rhel-7-extras]
name=My Red Hat Enterprise Linux $releasever - $basearch
baseurl=http://apt-mirror.front.sepia.ceph.com/rhel7repo/extras
gpgcheck=0
enabled=1
  EOH
end

file '/etc/yum.repos.d/apache-ceph.repo' do
  owner 'root'
  group 'root'
  mode '0644'
  content <<-EOH
[rhel7-apache-ceph]
name=RHEL 7 Local apache Repo
baseurl=http://gitbuilder.ceph.com/apache2-rpm-rhel7-x86_64-basic/ref/master/
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
[rhel7-fcgi-ceph]
name=RHEL 7 Local fastcgi Repo
baseurl=http://gitbuilder.ceph.com/mod_fastcgi-rpm-rhel7-x86_64-basic/ref/master/
gpgcheck=0
enabled=1
priority=2
  EOH
end


execute "Clearing yum cache" do
  command "yum clean all"
end

execute "Fix hostname" do
  command <<-'EOH'
hostname=`hostname | cut -d'.' -f1`
hostname $hostname
echo $hostname > /etc/hostname
  EOH
end

execute "Clearing out previously installed verisons of ceph" do
  command "yum remove -y ceph ceph-common libcephfs1 ceph-radosgw python-ceph librbd1 librados2|| true"
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


#RGW tests
directory '/home/ubuntu/.cpan/CPAN/' do
  owner "ubuntu"
  group "ubuntu"
  mode "0755"
  recursive true
end
cookbook_file '/home/ubuntu/.cpan/CPAN/MyConfig.pm' do
  source "CPANConfig.pm"
  mode 0755
  owner "ubuntu"
  group "ubuntu"
end
directory '/root/.cpan/CPAN/' do
  owner "root"
  group "root"
  mode "0755"
  recursive true
end
cookbook_file '/root/.cpan/CPAN/MyConfig.pm' do
  source "CPANConfig.pm"
  mode 0755
  owner "root"
  group "root"
end
execute "Installing CPAN Amazon::S3" do
  command "cpan  Amazon::S3"
end

package 'openssl'
package 'libuuid'
package 'btrfs-progs'
  
 
# used by workunits
package 'attr'
package 'valgrind'
package 'python-nose'
package 'mpich'
package 'ant'
#package 'dbench'
#package 'bonnie++'
#package 'tiobench'
package 'fuse-sshfs'
#package 'fsstress'

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
package 'qemu-img'
package 'qemu-kvm'
package 'qemu-kvm-tools'
package 'qemu-guest-agent'
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
  version '2.4.6-17_ceph.el7'
end
package 'httpd' do
  version '2.4.6-17_ceph.el7'
end
package 'httpd-tools' do
  version '2.4.6-17_ceph.el7'
end
package 'httpd-devel' do
  version '2.4.6-17_ceph.el7'
end
package 'mod_fastcgi' do
  version '2.4.7-1.ceph.el7'
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

service "firewalld" do
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

# Existing ceph-qa-chef made a link from
# /usr/bin/fsstress to the same as ubuntu
# but on rhel7 we compile this. This is cleanup

execute "Cleanup broken link" do
  command "if [ -L /usr/lib/ltp/testcases/bin/fsstress ]; then rm -f /usr/lib/ltp/testcases/bin/fsstress; fi"
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
