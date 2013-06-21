require 'asbestos/metadata'

require 'socket'
require 'system/getifaddrs'

require 'forwardable'


module Asbestos

  def self.hostname
    Socket.gethostname[/[^.]*/]
  end

  def self.interfaces
    System.get_ifaddrs
  end

  def self.os
    case
      when RUBY_PLATFORM[/linux/i]
        :linux
      when RUBY_PLATFORM[/darwin/i]
        :darwin
    end
  end

  def self.firewall
    case os
      when :linux
        Asbestos::Firewall::IPTables
      when :darwin
        #FIXME
        Asbestos::Firewall::IPTables
    end
  end

  def self.reset!
    [
      Host.all,
      Host.groups,
      HostTemplate.all,
      Address.all,
      RuleSet.all,
      Service.all,
    ].each do |collection|
      collection.delete_if {|_| true}
    end
  end

  #
  # Didn't want to monkeypatch the Hash class.
  #
  def self.with_indifferent_access!(hash)
    class << hash
      def [](key)
        fetch key.to_sym
      rescue KeyError # key not found
        nil
      end

      def []=(key, value)
        store key.to_sym, value
      end
    end
  end

  module ClassCollection
    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      def class_collection(name, base = self)
        # this is a little nasty, the 'name' variable isn't available
        # in the scope of the eigenclass, so we have to class_eval
        # the eigenclass
        (class << base; self; end).instance_eval do
          extend ::Forwardable

          attr_accessor name
          def_delegators name, :[], :[]= if name == :all
        end

        Hash.new.tap do |hash|
          Asbestos.with_indifferent_access! hash
          base.instance_variable_set "@#{name}", hash
        end
      end
    end

  end

end




require 'asbestos/rule_set'
require 'asbestos/service'
require 'asbestos/host_template'
require 'asbestos/host'
require 'asbestos/address'
require 'asbestos/dsl'

%w{firewalls services rule_sets}.each do |dir|
  Dir["#{File.dirname(__FILE__)}/asbestos/#{dir}/*.rb"].each { |f| require File.expand_path(f) }
end
