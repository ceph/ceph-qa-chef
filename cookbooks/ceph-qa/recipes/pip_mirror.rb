directory '/home/ubuntu/.pip' do
  owner 'ubuntu'
  group 'ubuntu'
  action :create
end

file '/home/ubuntu/.pip/pip.conf' do
  owner 'ubuntu'
  group 'ubuntu'
  mode '0644'
  content <<-EOH
[global]
index-url = http://apt-mirror.front.sepia.ceph.com/pypi/simple
  EOH
end

