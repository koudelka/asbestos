
rule_set :accept_from_self do
  # Accept any connections from the loopback device with local addresses bound for local addresses
  interfaces[:loopback].each do |interface|
    accept :interface => interface,
           :local_address  => '127.0.0.0/8',
           :remote_address => '127.0.0.0/8',
           :comment => "accept via loopback device with from and to loopback addresses"
  end

  # Accept anything from the interface to itself.
  iface_addresses = \
    if !generating_rules_for_current_host?
      # TODO: replace this with #collect#to_h in ruby 2.x
      Hash.new.tap do |hash|
        Asbestos.interfaces.each do |interface, addresses|
          hash[interface] = addresses[:inet_addr]
        end
      end
    else
      self.addresses
    end

  iface_addresses.each do |interface, address|
    next if interface == :loopback # handled by above rule

    accept :local_address  => address,
           :remote_address => address,
           :comment => "accept anything from myself to myself (#{interface})"
  end
end
