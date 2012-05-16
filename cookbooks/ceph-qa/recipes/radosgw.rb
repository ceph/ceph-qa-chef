# TODO once we're building more than squeeze, parameterize distro name

file '/etc/apt/sources.list.d/radosgw.list' do
  owner 'root'
  group 'root'
  mode '0644'

  if node[:platform_version] == "12.04"
    # pull from precise gitbuilder
    content <<-EOH
deb http://gitbuilder.ceph.com/libapache-mod-fastcgi-deb-precise-x86_64-basic/libapache-mod-fastcgi-precise/ref/master/ precise main
deb http://gitbuilder.ceph.com/apache2-deb-precise-x86_64-basic/apache2-precise/ref/master/ precise main
EOH
  elsif node[:platform_version] == "11.10"
    # pull from oneiric gitbuilder
    content <<-EOH
deb http://gitbuilder.ceph.com/apache2-deb-oneiric-x86_64-basic/ref/master/ oneiric main
deb http://gitbuilder.ceph.com/libapache-mod-fastcgi-deb-oneiric-x86_64-basic/ref/master/ oneiric main
EOH
  else
    # use old maverick gitbuilders
    content <<-EOH
deb http://gitbuilder-apache-deb-ndn.ceph.newdream.net/output/ref/master/ squeeze main
deb-src http://gitbuilder-apache-deb-ndn.ceph.newdream.net/output/ref/master/ squeeze main

deb http://gitbuilder-modfastcgi-deb-ndn.ceph.newdream.net/output/ref/master/ squeeze main
deb-src http://gitbuilder-modfastcgi-deb-ndn.ceph.newdream.net/output/ref/master/ squeeze main
EOH
  end
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
