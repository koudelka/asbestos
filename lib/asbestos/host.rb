
class Asbestos::Host
  include Asbestos::ClassCollection

  class_collection :all
  class_collection :groups

  class << self
    # returns a lazily evaluated block, to allow hosts to be 
    # defined in the DSL without a lot of hoopla
    def [](name)
      lambda { @all[name] }
    end
  end


  attr_reader :name
  attr_reader :groups
  attr_reader :interfaces
  attr_reader :addresses
  attr_reader :rulesets
  attr_reader :chains

  # the HostTemplate that built this host
  attr_accessor :template


  def initialize(name)
    @name = name
    @groups = []
    @rulesets = []

    @chains = {}

    @interfaces = {} # maps interface's tag to /dev name
    @addresses = {} # maps interface's /dev name to an ip address


    Asbestos.with_indifferent_access! @chains
    Asbestos.with_indifferent_access! @interfaces
    Asbestos.with_indifferent_access! @addresses

    if generating_rules_for_current_host?
      Asbestos.interfaces.each do |if_name, info|
        @addresses[if_name] = info[:inet_addr]
      end
    end

    #
    # Define the necessary chains
    # # FIXME do we need :forward too?
    #
    [:input, :output].each do |name|
      chain(name, :accept)
    end

    self.class.all[name] = self
  end

  def debug
    [
      "Hostname: #{@name}",
      (@template ? "  Template: #{@template}" : nil),
      "  Interfaces: #{@interfaces}",
      "  Addresses: #{@addresses}",
    ].tap do |a|
      a << "  Groups: #{@groups.sort.join(', ')}" unless @groups.empty?
      unless @rulesets.empty?
        a << "  RuleSets/Services:"
        @rulesets.each { |s| a << "    #{s.inspect}" }
      end
    end.join("\n")
  end

  def inspect
    "#<Host name:#{name}>"
  end

  alias_method :to_s, :inspect


  #
  # DSL ------------------------------------------------------------------------------
  #

  #
  # Indicates if Asbestos is generating rules for the host it's running on
  #
  def generating_rules_for_current_host?
    Asbestos.hostname.to_s == @name.to_s
  end

  #
  # Places this host in a named group
  #
  # host 'dax' do
  #   group :developers
  # end
  #
  def group(name = nil)
    if name
      @groups << name
      self.class.groups[name] ||= []
      self.class.groups[name] << self
    else
      @groups
    end
  end

  #
  # Defines an interface on this host with a given "tag". The interface's address can
  # be defined explicitly, or at runtime via a block.
  #
  # host 'dax' do
  #   group :developers
  #
  #   interface :external, :eth0  #=> address is "dax_external"
  #   interface :dmz, [:eth1, :eth2]  #=> addresses are "dax_dmz_eth1" and "dax_dmz_eth2"
  #
  #   interface :internal, :eth3 do |host|
  #     [host.group, host.name, 'foo'].join('_')
  #   end  #=> address is "developers_dax_foo"
  #
  #   interface :internal, :eth4, 'bar' #=> address is "bar"
  # end
  #
  def interface(tag, if_names, address = nil, &block)
    interfaces = [*@interfaces[tag], *if_names].compact.uniq
    raise "single address, #{address}, given for multiple interfaces, #{interfaces}, on host #{name}" if interfaces.length > 1 && address

    @interfaces[tag] = interfaces

    # determine the address for each interface
    interfaces.each do |if_name|
      new_address = \
        if !address
          if block_given? 
            yield(self, if_name)
          else
            if interfaces.length > 1
              "#{name}_#{tag}_#{if_name}"
            else
              "#{name}_#{tag}"
            end
          end
        else
          address
        end
      @addresses[if_name] = new_address
    end

  end

  #
  # Indicates that this host should log denied firewall packets.
  #
  # host 'dax' do
  #   log_denials
  # end
  def log_denials
    @log_denials = true
  end

  def log_denials?
    !!@log_denials
  end


  #
  # Defines a firewall chain on this host, this may be an IPTables-only concept.
  #
  # The default_action here is also called the chain's "policy" in IPTables parlance
  #
  def chain(name, default_action = :none)
    @chains[name.downcase.to_sym] = default_action
  end

  #
  # Indicates that this host should have rules to allow the corresponding
  # service to run on it. The arguments provided after the service name
  # should be valid DSL calls supported by the service. Certain DSL calls
  # come standard with all services, see the Service class for more info.
  #
  # host 'dax' do
  #   runs :nginx, :on => :external
  #   runs :ssh,   :on => :internal, :port => 22022
  #   runs :riak,  :on => :internal, :from => {:riak_cluster => :internal}
  # end
  #
  def runs(service_name, args = {})
    template = Asbestos::Service[service_name]
    raise "Service not defined: #{service_name}" unless template

    @rulesets <<
      Asbestos::Service.new(service_name, self).tap do |s|
        s.instance_eval &template
        # override template defaults with provided options
        args.each do |k, v|
          s.send k, v
        end
      end
  end


  #
  # Determine this host's firewall rules, according to the firewall type.
  #
  def rules
    #
    # This is called first in case any preable needs to be declared (chains, specifically)
    #
    _ruleset_rules = ruleset_rules

    [
      Asbestos.firewall.preamble(self),
      _ruleset_rules,
      Asbestos.firewall.postamble(self)
    ].flatten
  end

  #
  # Ask each ruleset/service to generate its rules.
  #
  def ruleset_rules
    @rulesets.collect do |r|
      ["# Begin [#{r.name}]",
       r.firewall_rules,
       "# End [#{r.name}]",
       ""]
    end
  end

  #
  # Missing methods should be the name of RuleSets, if not, raise an error
  #
  # This is similar to the "runs" method above, but for RuleSets, rather than services.
  #
  def method_missing(rule_set_name, args = {})
    template = Asbestos::RuleSet[rule_set_name]
    raise %{Unknown host DSL call : "#{rule_set_name}" for host "#{name}"} unless template

    @rulesets << \
      Asbestos::RuleSet.new(rule_set_name, self, template).tap do |rs|
        # override template defaults with provided options
        args.each do |k, v|
          rs.send k, v
        end
      end
  end
end
