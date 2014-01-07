rule_set :sanity_check do
 chain 'valid-src'
 chain 'valid-dst'

 # Require all packets to or from the internet to go through sanity checks.
 interfaces[:external].each do |interface|
   rule :chain  => :input,
        :action => 'valid-src',
        :interface => interface,
        :comment => "all traffic from internet goes through sanity check"

   rule :chain  => :output,
        :action => 'valid-dst',
        :interface => interface,
        :comment => "all traffic to internet goes through sanity check"
 end

 # Private interface addresses should never be talking to our external IP.
 [
   '0.0.0.0/8',
   '10.0.0.0/8',
   '127.0.0.0/8',
   '169.254.0.0/16',
   '172.16.0.0/12',
   '192.168.0.0/16',
   '224.0.0.0/4',
   '240.0.0.0/5'
 ].each do |internal_ip_range|
   drop :chain => 'valid-src',
        :local_address => internal_ip_range,
        :comment => "drop private ip talking to external interface"
 end

 drop :chain => 'valid-src',
      :remote_address => '255.255.255.255',
      :comment => "drop broadcast ip talking to external interface"

 drop :chain => 'valid-dst',
      :remote_address => '224.0.0.0/4',
      :comment => "ignore multicast"
end
