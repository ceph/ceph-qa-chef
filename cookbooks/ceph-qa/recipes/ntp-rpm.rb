package 'ntp'

cookbook_file '/etc/ntp.conf' do
  source "ntp.conf"
  mode 0644
  owner "root"
  group "root"
end

# Stop NTP service and then manually run ntpd to immediatley update time
service "ntpd" do
  action [:enable,:stop]
end

if node['hostname'].match(/^(magna)/)
  execute "Getting around redhat blocking of NTP" do
    command <<-'EOH'
      sudo sed -i 's;^server [A-Z:a-z:.:-:0-9]*;server clock.corp.redhat.com;g' /etc/ntp.conf || true
      sleep 1
      sudo ntpd -gq || true
      sleep 1
    EOH
  end
end

service "ntpd" do
  action [:start]
end
