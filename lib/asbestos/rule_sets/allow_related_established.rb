
rule_set :allow_related_established do
  # Allow all currently established and related packets
  accept :state => 'RELATED,ESTABLISHED'
end
