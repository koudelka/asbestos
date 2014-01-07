
rule_set :icmp_protection do

  accept :protocol  => :icmp,
         :icmp_type => 'echo-reply',
         :comment   => "allow us to receive ping responses"


  interfaces[:external].each do |interface|
    from_each_address(allowed_from) do |address|
      accept :protocol  => :icmp,
             :icmp_type => 'echo-request',
             :interface => interface,
             :remote_address => address,
             :limit   => '1/s',
             :comment => "allow icmp from #{address}"
    end

    drop :protocol  => :icmp,
         :interface => interface,
         :comment   => "drop any icmp packets that haven't been explicitly allowed"
  end
end
