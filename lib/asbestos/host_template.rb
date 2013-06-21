class Asbestos::HostTemplate
  include Asbestos::ClassCollection

  class_collection :all

  attr_reader :template

  def initialize(name, template)
    @name = name
    @template = template

    self.class[name] = self
  end

end
