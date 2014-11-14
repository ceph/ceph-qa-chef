package 'ntp'

cookbook_file '/etc/ntp.conf' do
  source "ntp.conf"
  mode 0644
  owner "root"
  group "root"
  notifies :restart, "service[ntp]"
end

if node['hostname'].match(/^(magna)/)  
  execute "Getting around redhat blocking of NTP" do
    command <<-'EOH'
      sudo sed -i 's/clock3.dreamhost.com/clock.corp.redhat.com/g' /etc/ntp.conf || true
    EOH
  end
end

service "ntp" do
  action [:enable,:start]
end

