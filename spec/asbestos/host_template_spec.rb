
require 'spec_helper'

describe Asbestos::HostTemplate do
  before(:each) do
    Asbestos.reset!
  end

  context "the 'host_template' DSL call" do
    it "should store the block as a template" do

      block = proc do;
      end

      host_template 'hosttemplatename', &block

      Asbestos::HostTemplate[:hosttemplatename].template.should be block
    end

    it "should execute the template block in the context of the host" do
      context = nil
      host_template 'hosttemplatename' do
        context = self
      end

      hosttemplatename 'hostname' do
      end

      Host['hostname'].call.should be context
    end
  end
end
