require 'spec_helper'

describe Asbestos::Service do
  before(:each) do
    Asbestos.reset!
  end

  context "the 'service' DSL call" do
    it "should store the block as a template" do

      block = proc do;
      end

      service 'servicename', &block

      Asbestos::Service[:servicename].should be block
    end
  end

  context "context DSL" do
    it "should store arbitrary calls as attributes" do
      service 'servicename' do
        some_attribute :some_value
      end

      host 'hostname' do
        runs :servicename
      end

      Host['hostname'].call.rulesets.first.name.should be :servicename
      Host['hostname'].call.rulesets.first.some_attribute.should be :some_value
    end

    it "should store certain attributes under their plural name" do
      service 'servicename' do
        port 9000
        protocol :icmp
        group :service_group
      end

      host 'hostname' do
        runs :servicename
      end

      Host['hostname'].call.rulesets.first.name.should be :servicename

      Host['hostname'].call.rulesets.first.port.should == [9000]
      Host['hostname'].call.rulesets.first.ports.should == [9000]

      Host['hostname'].call.rulesets.first.protocol.should == [:icmp]
      Host['hostname'].call.rulesets.first.protocols.should == [:icmp]

      Host['hostname'].call.rulesets.first.group.should == [:service_group]
      Host['hostname'].call.rulesets.first.groups.should == [:service_group]
    end
  end

  it "should generate firewall rules properly"
  it "should handle the :from argument to open_port properly"
end
