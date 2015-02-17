# Use our pip mirror
include_recipe "ceph-qa::pip_mirror"

execute "add autobuild gpg key to apt" do
  command <<-EOH
  wget -q -O- 'http://ceph.com/git/?p=ceph.git;a=blob_plain;f=keys/autobuild.asc;hb=HEAD' \
  | sudo apt-key add -
  EOH
end

execute "add autobuild gpg key to apt" do
  command <<-EOH
  wget -q -O- 'http://ceph.com/git/?p=ceph.git;a=blob_plain;f=keys/release.asc;hb=HEAD' \
  | sudo apt-key add -
  EOH
end

#Setup sources.list
if node[:platform_version] >= "6.0" and node[:platform_version] < "7.0"
  cookbook_file '/etc/apt/sources.list' do
    source "sources.list.squeeze"
    mode 0644
    owner "root"
    group "root"
  end
end


#Apt priority
file '/etc/apt/preferences.d/ceph.pref' do
  owner 'root'
  group 'root'
  mode '0644'
    content <<-EOH
Package: *
Pin: origin gitbuilder.ceph.com
Pin-Priority: 999
EOH
end

#Ceph Extras:
file '/etc/apt/sources.list.d/ceph-extras.list' do
  owner 'root'
  group 'root'
  mode '0644'

  if node[:platform_version] >= "7.0" and node[:platform_version] < "8.0"
    # pull from wheezy gitbuilder
    content <<-EOH
deb http://ceph.com/packages/ceph-extras/debian/ wheezy main
EOH
  end
end

#Ceph Dumpling:
file '/etc/apt/sources.list.d/ceph-dumpling.list' do
  owner 'root'
  group 'root'
  mode '0644'

  if node[:platform_version] >= "7.0" and node[:platform_version] < "8.0"
    # pull from wheezy gitbuilder
    content <<-EOH
deb http://ceph.com/debian-dumpling/ wheezy main
EOH
  end
end

#Rados GW:
file '/etc/apt/sources.list.d/radosgw.list' do
  owner 'root'
  group 'root'
  mode '0644'

  if node[:platform_version] >= "7.0" and node[:platform_version] < "8.0"
    # pull from wheezy gitbuilder
    content <<-EOH
deb http://gitbuilder.ceph.com/libapache-mod-fastcgi-deb-wheezy-x86_64-basic/ref/master/ wheezy main
EOH
  elsif node[:platform_version] >= "6.0" and node[:platform_version] < "7.0"
    # pull from squeeze gitbuilder
    content <<-EOH
deb http://gitbuilder.ceph.com/libapache-mod-fastcgi-deb-squeeze-x86_64-basic/ref/master/ squeeze main
EOH
  else
    # hrm!
  end
end


#Work around broken wget onwheezy
file '/etc/wgetrc' do
  owner 'root'
  group 'root'
  mode '0644'
    content <<-EOH
check_certificate = off
passive_ftp = on
EOH
end

execute 'apt-get update' do
  command <<-'EOH'
    apt-get update || apt-get update || true
  EOH
end

package 'apt' do
  action :upgrade
end

package 'lsb-release'
package 'build-essential'
package 'sysstat'
package 'gdb'
package 'python-configobj'
package 'python-gevent'
package 'python-dev'
package 'python-virtualenv'
package 'libevent-dev'
if node[:platform_version] >= "7.0" and node[:platform_version] < "8.0"
  package 'fuse'
  package 'libssl1.0.0'
  package 'libgoogle-perftools4'
  package 'libboost-thread1.49.0'
  package 'cryptsetup-bin'
  package 'libcrypto++9'
  package 'iozone3'
  package 'libmpich2-3'
  package 'collectl'
  service "collectl" do
    action [:disable,:stop]
  end
  #NFS servers uport per David Z.
  package 'nfs-kernel-server'
  package 'libcurl3-gnutls' do
    action :upgrade
  end
end

if node[:platform_version] >= "6.0" and node[:platform_version] < "7.0"
  package 'fuse-utils'
  package 'libfuse2'
  package 'libssl0.9.8'
  package 'libgoogle-perftools0'
  package 'libboost-thread1.42.0'
  package 'cryptsetup'
  package 'libcrypto++8'
  package 'libmpich2-1.2'
end

#RADOS GW
package 'apache2' do
  action :upgrade
end
package 'libapache2-mod-fastcgi' do
  action :upgrade
end
package 'libfcgi0ldbl'

service "apache2" do
  action [ :disable, :stop ]
end


# for running ceph
package 'libedit2'

package 'xfsprogs'
package 'gdisk'
package 'parted'

# for setting BIOS settings
package 'libsmbios-bin'


package 'libuuid1'
package 'libfcgi'
package 'btrfs-tools'

# for compiling helpers and such
package 'libatomic-ops-dev'

# used by workunits
package 'git-core'
package 'attr'
package 'dbench'
package 'bonnie++'

package 'valgrind'
package 'python-nose'
package 'mpich2'
package 'libmpich2-dev'
package 'ant'

# used by the xfstests tasks
package 'libtool'
package 'automake'
package 'gettext'
package 'uuid-dev'
package 'libacl1-dev'
package 'bc'
package 'xfsdump'
package 'dmapi'
package 'xfslibs-dev'

#For Mark Nelson:
package 'sysprof'
package 'pdsh'

# for blktrace and seekwatcher
package 'blktrace'
package 'python-numpy'
package 'python-matplotlib'
package 'mencoder'

# for qemu
package 'kvm'
package 'genisoimage'

# for json_xs to investigate JSON by hand
package 'libjson-xs-perl'
# for pretty-printing xml
package 'xml-twig-tools'

# for java bindings, hadoop, etc.
package 'default-jdk'
package 'junit4'

# for disk/etc monitoring
package 'smartmontools'
package 'nagios-nrpe-server'

# for samba testing
package 'cifs-utils'

#DistCC for arm
package 'distcc'

#tgt
package 'tgt' do
  options "--allow-unauthenticated"
end
package 'open-iscsi'

#NTP
include_recipe "ceph-qa::ntp-deb"

execute "add user_xattr to root mount options in fstab" do
  # fugly but works! which is more than i can say for the "mount"
  # resource, which doesn't seem to like a rootfs with an unknown UUID
  # at all.
  command <<-'EOH'
    perl -pe 'if (m{^([^#]\S*\s+/\s+\S+\s+)(\S+)(\s+.*)$}) { $_="$1$2,user_xattr$3\n" unless $2=~m{(^|,)user_xattr(,|$)}; }' -i.bak /etc/fstab
  EOH
end

execute "enable xattr for this boot" do
  command "mount -o remount,user_xattr /"
end

execute "allow fuse mounts to be used by non-owners" do
  command "grep -q ^user_allow_other /etc/fuse.conf || echo user_allow_other >> /etc/fuse.conf"
end

execute "add user ubuntu to group fuse" do
  command "adduser ubuntu fuse"
end

file '/etc/fuse.conf' do
  mode "0644"
end

execute "add user ubuntu to group kvm" do
  command "adduser ubuntu kvm"
end

directory '/home/ubuntu/.ssh' do
  owner "ubuntu"
  group "ubuntu"
  mode "0755"
end

#Unfortunately no megacli/arecacli package for ubuntu/debian -- Needed for raid monitoring and smart.
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

execute "add ubuntu to disk group" do
  command <<-'EOH'
    usermod -a -G disk ubuntu
  EOH
end


#Static IP
package 'ipcalc'

if !node['hostname'].match(/^(vpm)/)
  execute "set up static IP in /etc/hosts" do
    command <<-'EOH'
      cidr=$(ip addr show dev eth0 | grep -iw inet | awk '{print $2}')
      ip=$(echo $cidr | cut -d'/' -f1)
      hostname=$(uname -n)
      sed -i "s/^127.0.1.1[\t]$hostname.front.sepia.ceph.com/$ip\t$hostname.front.sepia.ceph.com/g" /etc/hosts
    EOH
  end
end

execute "Fix PATH in /etc/profile" do
  command <<-'EOH'
    sed -i 's/\/usr\/games"/\/usr\/games:\/usr\/sbin"/g' /etc/profile
    if ! grep -q '/usr/sbin' /home/ubuntu/.bashrc; then sed -i '1iexport PATH=$PATH:/usr/sbin\n' /home/ubuntu/.bashrc; fi 
  EOH
end

#Nagios sudo (for raid utilities)
file '/etc/sudoers.d/90-nagios' do
  owner 'root'
  group 'root'
  mode '0440'
  content <<-EOH
    nagios ALL=NOPASSWD: /usr/sbin/megacli, /usr/sbin/cli64, /usr/sbin/smartctl, /usr/sbin/smartctl
  EOH
end


#Nagios nrpe config
cookbook_file '/etc/nagios/nrpe.cfg' do
  source "nrpe.cfg"
  owner 'root'
  group 'root'
  mode '0644'
  notifies :restart, "service[nagios-nrpe-server]"
end

service "nagios-nrpe-server" do
  action [:enable,:start]
end

#nagios nrpe settings
file '/etc/default/nagios-nrpe-server' do
  owner 'root'
  group 'root'
  mode '0644'
  content <<-EOH
    DAEMON_OPTS="--no-ssl"
  EOH
end

bash "ssh_max_sessions" do
  user "root"
  cwd "/etc/ssh"
  code <<-EOT
    echo "MaxSessions 1000" >> sshd_config
  EOT
  not_if {File.read("/etc/ssh/sshd_config") =~ /MaxSessions/}
end

execute "Remove ceph dumpling file" do
  command <<-'EOH'
    rm -f /etc/apt/sources.list.d/ceph-dumpling.list
  EOH
end

service "ssh" do
  action [:restart]
end


file '/ceph-qa-ready' do
  content "ok\n"
end

