
rule_set :accept_from_self do
  # Accept any connections from the loopback device with local addresses bound for local addresses
  interfaces[:loopback].each do |interface|
    accept :interface => interface,
           :local_address  => '127.0.0.0/8',
           :remote_address => '127.0.0.0/8',
           :comment => "accept via loopback device with from and to loopback addresses"
  end

  # Accept anything from the interface to itself.
  addresses.each do |interface, address|
    next if interface == :loopback # handled by above rule

    accept :local_address  => address,
           :remote_address => address,
           :comment => "accept anything from myself to myself (#{interface})"
  end
end
