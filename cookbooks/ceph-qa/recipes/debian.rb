package 'lsb-release'
package 'build-essential'
package 'sysstat'
package 'gdb'
package 'python-configobj'
package 'python-gevent'
package 'python-dev'
package 'python-virtualenv'
package 'libevent-dev'
package 'fuse'

# for running ceph
package 'libedit2'
package 'libssl1.0.0'
package 'libgoogle-perftools4'

package 'libboost-thread1.49.0'

package 'cryptsetup-bin'
package 'xfsprogs'
package 'gdisk'
package 'parted'

# for setting BIOS settings
package 'libsmbios-bin'

package 'libcrypto++9'

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
package 'iozone3'
package 'tiobench'

package 'valgrind'
package 'python-nose'
package 'mpich2'
package 'libmpich2-3'
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
package 'collectl'
service "collectl" do
  action [:disable,:stop]
end

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

package 'ntp'

cookbook_file '/etc/ntp.conf' do
  source "ntp.conf"
  mode 0644
  owner "root"
  group "root"
  notifies :restart, "service[ntp]"
end

service "ntp" do
  action [:enable,:start]
end

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

#NFS servers uport per David Z.
package 'nfs-kernel-server'

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

service "ssh" do
  action [:restart]
end


file '/ceph-qa-ready' do
  content "ok\n"
end

