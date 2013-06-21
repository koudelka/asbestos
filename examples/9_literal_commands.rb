
rule_set :creates_chaos do
  command "-A INPUT -m statistic --mode random --probability 0.01 -j REJECT --reject-with host-unreach"
end

host 'app_host' do
  creates_chaos
end
