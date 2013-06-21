
host 'app_host' do
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
  runs :mongodb, on: :internal, from: { Host['app_host'] => :internal,
                                        Host['dax']      => :internal }
end
