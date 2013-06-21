
host 'app_host_0' do
  group :app_hosts

  interface :internal, :eth0

  runs :ssh
  runs :http
end

host 'app_host_1' do
  group :app_hosts

  interface :internal, :eth0

  runs :ssh
  runs :http
end

host 'app_host_2' do
  group :app_hosts

  interface :internal, :eth0

  runs :ssh
  runs :http
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
