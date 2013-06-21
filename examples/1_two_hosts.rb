
host 'app_host' do
  interface :internal, :eth0
  # 'internal' is an arbitrary name, you can make it anything you want

  runs :ssh
  runs :http
end

host 'db_host' do
  runs :ssh
  runs :mongodb, from: { Host['app_host'] => :internal }
end

host 'db_host_more_specific' do
  runs :ssh
  runs :mongodb, from: { Host['app_host'] => :internal }
end
