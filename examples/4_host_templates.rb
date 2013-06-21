
host_template 'app_host' do
  group :app_hosts

  interface :internal, :eth0

  runs :ssh
  runs :http
end

0.upto(2) do |i|
  app_host "app_host_#{i}"
end

app_host 'app_host_3' do
  runs :nfs
end

host 'dax' do
  interface :internal, :eth0
end

host 'db_host' do
  interface :internal, :eth0

  runs :ssh
  runs :mongodb, on: :internal, from: { :app_hosts  => :internal,
                                        Host['dax'] => :internal }
end
