
address :load_balancers, ['lb0.myprovider.com', 'lb1.myprovider.com']
address :monitoring, 'pinger.monitoringservice.com'

host 'app_host' do
  runs :http, from: [:load_balancers, :monitoring]
end
