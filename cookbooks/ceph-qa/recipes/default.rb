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


# what distro name to use in apt sources list
distro = node[:lsb][:codename]
case distro
when "maverick"
  # we don't actually build for maverick, but natty seems to work
  # fine; old sepia is still maverick
  distro = "natty"
when "oneiric"
  # TODO we don't yet build debs for oneiric, so kludge it back to
  # natty; FIX ME
  distro = "natty"
end

# for rgw
execute "add autobuild gpg key to apt" do
  command <<-EOH
wget -q -O- 'http://ceph.newdream.net/git/?p=ceph.git;a=blob_plain;f=keys/autobuild.asc;hb=HEAD' \
| sudo apt-key add -
  EOH
end

file '/etc/apt/sources.list.d/ceph.list' do
  owner 'root'
  group 'root'
  mode '0644'
  # TODO not always master, etc; grab branch from config
  content <<-EOH
deb http://ceph.newdream.net/debian-snapshot-amd64/master/ #{distro} main
deb-src http://ceph.newdream.net/debian-snapshot-amd64/master/ #{distro} main
  EOH
end

execute 'apt-get update' do
end

if node[:platform] == "ubuntu" and node[:platform_version] == "10.10"
  include_recipe "ceph-qa::radosgw"
else
  Chef::Log.info("radosgw not supported on: #{node[:platform]} #{node[:platform_version]}")
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
