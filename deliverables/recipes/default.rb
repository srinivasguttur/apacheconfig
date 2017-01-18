#
# Cookbook Name:: deliverables
# Recipe:: default
#
# Copyright 2017, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#
# Check and install http and https packages

sslfile = '/etc/httpd/conf.d/ssl.conf'
httpfile = '/etc/httpd/conf/httpd.conf'

case node[:platform]
when "redhat"
  yum_package "httpd" do
    action :install
  end
  service "httpd" do
    action [ :enable, :start ]
  end

  file "#{sslfile}.bkp" do
     content IO.read("#{sslfile}")
     only_if {File.exists?("#{sslfile}")}
   end

  File.open("#{sslfile}", 'r') do
      output = File.read("#{sslfile}")
      reg = output.gsub(/#Listen 443 https/, "Listen 443 https")
      File.open("#{sslfile}", 'w') {|file| file.puts reg}
    end
  File.open("#{httpfile}", 'r') do
      output = File.read("#{httpfile}")
      reg = output.gsub(/^.*#Listen.*$/, "Listen 443 80")
      File.open("#{httpfile}", 'w') {|file| file.puts reg}
    end

  template "#{sslfile}" do
    source "ssl.conf.erb"
    mode 0644
    owner "root"
    roup "root"
    variables(
               :sslcertificate => "#{node['apache']['sslpath']}/apache.crt",
               :sslkey => "#{node['apache']['sslpath']}/apache.key",
               :sslcacertificate => "#{node['apache']['sslpath']}/ca-bundle.crt",
               :servername => "#{node['apache']['servername']}"
    )
  end

  cookbook_file "/var/www/html/index.html" do
     source "index.html.erb"
      owner "root"
      mode '644'
   end

  service "httpd" do
    action :restart
  end

  execute "Enabling the firewall ports 22 80 443" do
    command "iptables -A INPUT -i lo -j ACCEPT;iptables -A INPUT -p tcp -m tcp --dport 22 -j ACCEPT;iptables -A INPUT -p tcp -m tcp --dport 80 -j ACCEPT;iptables -A INPUT -p tcp -m tcp --dport 443 -j ACCEPT"
  end

  service "iptables" do
    action :restart
  end
end
