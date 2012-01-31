package 'build-essential'
package 'sysstat'
package 'gdb'
package 'python-configobj'
package 'python-gevent'

# for running ceph
package 'libedit2'
package 'libssl0.9.8'
package 'libgoogle-perftools0'
case node[:platform]
when "ubuntu"
  case node[:platform_version]
  when "10.10"
    package 'libcrypto++8'
  when "11.10"
    package 'libcrypto++9'
  else
    Chef::Log.fatal("Unknown ubuntu release: #{node[:platform_version]}")
    exit 1
  end
else
  Chef::Log.fatal("Unknown platform: #{node[:platform]}")
  exit 1
end
package 'libuuid1'

# for compiling helpers and such
package 'libatomic-ops-dev'

# used by workunits
package 'git-core'
package 'attr'
package 'dbench'
package 'bonnie++'
package 'iozone3'
package 'tiobench'
package 'ltp-kernel-test'
package 'valgrind'
package 'python-nose'

# for rgw
execute "add autobuild gpg key to apt" do
  command <<-EOH
wget -q -O- https://raw.github.com/NewDreamNetwork/ceph/master/keys/autobuild.asc \
| sudo apt-key add -
  EOH
end

file '/etc/apt/sources.list.d/radosgw.list' do
  owner 'root'
  group 'root'
  mode '0644'
  # TODO not always natty, not always master, etc; grab branch from
  # config, distro from ohai results (node[:lsb][:codename], but on
  # sepia that's currently maverick not natty, and we only have
  # dists/squeeze!)
  content <<-EOH
deb http://gitbuilder-apache-deb-ndn.ceph.newdream.net/output/ref/master/ squeeze main
deb-src http://gitbuilder-apache-deb-ndn.ceph.newdream.net/output/ref/master/ squeeze main

deb http://gitbuilder-modfastcgi-deb-ndn.ceph.newdream.net/output/ref/master/ squeeze main
deb-src http://gitbuilder-modfastcgi-deb-ndn.ceph.newdream.net/output/ref/master/ squeeze main
  EOH
end

file '/etc/apt/sources.list.d/ceph.list' do
  owner 'root'
  group 'root'
  mode '0644'
  # TODO not always natty, not always master, etc; grab branch from
  # config, distro from ohai results (node[:lsb][:codename], but on
  # sepia that's currently maverick not natty, yet we only have
  # dists/natty!)
  content <<-EOH
deb http://ceph.newdream.net/debian-snapshot-amd64/master/ natty main
deb-src http://ceph.newdream.net/debian-snapshot-amd64/master/ natty main
  EOH
end

execute 'apt-get update' do
end

file '/etc/grub.d/02_force_timeout' do
  owner 'root'
  group 'root'
  mode '0755'
  content <<-EOH
cat <<EOF
set timeout=5
EOF
  EOH
end

execute 'update-grub' do
end

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

# for s3-tests
package 'python-pip'
package 'python-virtualenv'
package 'python-dev'
package 'libevent-dev'

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

file '/etc/fuse.conf' do
  mode "0644"
end

directory '/home/ubuntu/.ssh' do
  owner "ubuntu"
  group "ubuntu"
  mode "0755"
end

ruby_block "set up ssh keys" do
  block do
    names = data_bag('ssh-keys')
    f = File.open('/home/ubuntu/.ssh/authorized_keys.chef', 'w') do |f|
      names.each do |name|
        data = data_bag_item('ssh-keys', name)
        f.puts(data['key'])
      end
    end
  end
end

execute "merge authorized ssh keys" do
  command <<-'EOH'
    set -e
    set -- ~ubuntu/.ssh/authorized_keys.chef
    if [ -e ~ubuntu/.ssh/authorized_keys ]; then
      set -- "$@" ~ubuntu/.ssh/authorized_keys
    fi
    sort -u -o ~ubuntu/.ssh/authorized_keys.tmp -- "$@"
    chown ubuntu:ubuntu -- ~ubuntu/.ssh/authorized_keys.tmp
    mv -- ~ubuntu/.ssh/authorized_keys.tmp ~ubuntu/.ssh/authorized_keys
  EOH
end

execute "enable kernel logging to console" do
  command <<-'EOH'
    set -e
    add_console() {
        sed 's/^GRUB_CMDLINE_LINUX="\(.*\)"$/GRUB_CMDLINE_LINUX="\1 console=tty0 console=ttyS0,115200"/' /etc/default/grub > /etc/default/grub.chef
        mv /etc/default/grub.chef /etc/default/grub
        update-grub
    }
    grep -q '^GRUB_CMDLINE_LINUX=".* console=tty0 console=ttyS0,115200' /etc/default/grub || add_console
  EOH
end

file '/ceph-qa-ready' do
  content "ok\n"
end
