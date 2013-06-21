
def host_template(name, &block)
  name = name.to_sym
  Asbestos::HostTemplate.new(name, block).tap do |host_template|

    #
    # Calling define_method wont let you define block parameters,
    # but doing it this way will
    #
    Object.send(:define_method, name) do |host_name, &block|
      host(host_name, &host_template.template).tap do |h|
        h.instance_eval &block if block
        h.template = name
      end
    end

  end
end

def host(name, &block)
  Asbestos::Host.new(name.to_sym).tap do |h|
    h.instance_eval &block if block_given?
  end
end

def rule_set(name, &template)
  Asbestos::RuleSet[name.to_sym] = template
end

def service(name, &template)
  Asbestos::Service[name.to_sym] = template
end

def address(name, address)
  Asbestos::Address[name] = [*address]
end


# For referencing lazy hosts in the dsl without prepending "Asbestos::"
Host = Asbestos::Host
