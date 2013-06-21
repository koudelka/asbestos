
host 'dax' do
  interface :external, :eth0  #=> address is "dax_external"
  interface :dmz, [:eth1, :eth2]  #=> addresses are "dax_dmz_eth1" and "dax_dmz_eth2"

  runs :ssh, from: {Host['kira'] => :external}
end


host 'kira' do
  group :developers

  interface :external, :eth3 do |host|
    [host.groups.join, host.name, 'foo'].join('_')
  end
  #=> address is "developers_kira_foo"

  interface :internal, :eth4, 'bar' #=> address is "bar"
end
