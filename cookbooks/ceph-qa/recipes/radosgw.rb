# TODO once we're building more than squeeze, parametrize distro name

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

# TODO do this only once, after all sources.list manipulation is done,
# but before first package directive (that uses non-default sources)
execute 'apt-get update' do
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
