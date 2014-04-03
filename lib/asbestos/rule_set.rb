require 'forwardable'

class Asbestos::RuleSet
  extend ::Forwardable
  include Asbestos::ClassCollection

  class_collection :all

  attr_reader :name
  attr_reader :host
  attr_reader :attributes
  attr_reader :commands

  def initialize(name, host, template)
    @name = name
    @host = host
    @attributes = {}
    @commands = []
    @template = template
  end

  def inspect
    "#{name}:#{@attributes.inspect}"
  end


  #
  # Asks this RuleSet to generate its firewall rules
  #
  def firewall_rules
    instance_eval &@template
    @commands
  end

  #
  # DSL ------------------------------------------------------------------------------
  #

  #
  # These host functions are useful when building rules.
  #
  def_delegators :@host, :chain, :interfaces, :command, :addresses, :generating_rules_for_current_host?

  #
  # Records a literal firewall command for this host, ignoring firewall type (iptables, ipfw, etc)
  #
  def command(str)
    @commands << str
  end

  #
  # Requests a rule from this platform's firewall, with the given args.
  #
  [:rule, :accept, :reject, :drop, :log].each do |action|
    define_method(action) do |args|
      @commands << Asbestos.firewall.send(action, args)
    end
  end

  #
  # Given a list of "from" objects, resolve a list of hosts or addresses
  #
  def from_each(froms = @attributes[:from], &block)
    case froms
      when Array # a list of any of the other types
        froms.each do |from|
          from_each from, &block
        end
      when Hash # either a group or a specific host paired with an interface
        froms.each do |host_or_group, their_interface_tag|
          if [Symbol, String].include? host_or_group.class # it's a group name
            Host.groups[host_or_group].uniq.each do |group_host|
              next if group_host == @host
              yield group_host, their_interface_tag
            end
          else # it's a Host or a lazly defined Host in a proc
            host = host_or_group.is_a?(Proc) ?  host_or_group.call : host_or_group
            yield host, their_interface_tag
          end
        end
      when String, Symbol # some kind of address(es)
        if Asbestos::Address[froms]
          Asbestos::Address[froms].each do |address|
            yield address
          end
        else
          yield froms
        end
      when nil # from everyone
        yield nil
      when Host, Proc
        raise "#{@host.name}/#{name}: you specified a 'from' Host but no remote interface"
      else
        raise "#{@host.name}/#{name}: invalid 'from' object"
    end
  end

  #
  # Resolves a set of "from" objects into addresses
  #
  def from_each_address(froms = @attributes[:from])
    from_each(froms) do |host_or_address, remote_interface_tag|
      case host_or_address
        when Host # specific host, specific remote interface
          host_or_address.interfaces[remote_interface_tag].each do |remote_interface|
              yield host_or_address.addresses[remote_interface]
          end
        else
          yield host_or_address
      end
    end
  end

  #
  # Responsible for storing and retrieving unspecified DSL calls as service attributes.
  #
  def method_missing(attribute, *args)
    if args.empty?
      @attributes[attribute]
    else
      #
      # Certain DSL properties should be stored as arrays
      #
      if [:ports, :protocols, :groups].include? attribute
        @attributes[attribute] = [*args]
      else
        @attributes[attribute] = args.first
      end
    end
  end
end
