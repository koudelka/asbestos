
service :my_service do
  ports 1337
  protocols :tcp, :udp
end

host 'app_host' do
  runs :my_service
end
