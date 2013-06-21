
module Asbestos
  class Service < RuleSet

    class_collection :all

    attr_reader :attributes

    def initialize(name, host)
      @name = name
      @host = host
      @attributes = {}
      #
      # Attribute defaults
      #
      @attributes[:protocols] = [:tcp]
    end

    def inspect
      "#{name}:#{[*ports].join(',')}/#{@attributes.inspect}"
    end

    def firewall_rules
      Array.new.tap do |rules|
        from_each do |host_or_address, remote_interface_tag|
          rules << open_port(:from => host_or_address, :remote_interface_tag => remote_interface_tag)
        end
      end
    end

    def open_port(args = {})
      interfaces = on ? host.interfaces[on] : nil # nil -> all interfaces

      Array.new.tap do |rules|
        protocols.each do |protocol|
          ports.each do |port|
            comment_base = "allow #{name}(#{protocol} port #{port}) from"
            case args[:from]
              when Host # specific host, specific remote interface
                raise "Host '#{args[:from].name}' doesn't have interface '#{args[:remote_interface_tag]}'" unless args[:from].interfaces[args[:remote_interface_tag]]
                args[:from].interfaces[args[:remote_interface_tag]].each do |remote_interface|
                  comment = "#{comment_base} #{args[:from].name}:#{remote_interface} (#{args[:remote_interface_tag]})"
                  rules << Asbestos.firewall.open_port(interfaces, port, protocol, comment, args[:from].addresses[remote_interface])
                end
              when Symbol, String # an address
                comment = "#{comment_base} #{args[:from]}"
                rules << Asbestos.firewall.open_port(interfaces, port, protocol, comment, args[:from])
              else
                comment = "#{comment_base} anyone"
                rules << Asbestos.firewall.open_port(interfaces, port, protocol, comment)
            end
          end
        end
      end
    end

    #
    # DSL ------------------------------------------------------------------------------
    #

    #
    # Most DSL calls needed by Service are caught and handled by method_missing in RuleSet
    #


    #
    # This is a hack to intercept DSL calls to certain singular attributes and send them to
    # method_missing on the superclass in their plural form.
    #
    [
     :port,
     :protocol,
     :group,
    ].each do |method|
      define_method method do |*args|
        if args.empty?
          self.send "#{method}s"
        else
          self.send "#{method}s", *args
        end
      end
    end


  end
end
