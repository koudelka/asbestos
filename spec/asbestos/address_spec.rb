
require 'spec_helper'

describe Asbestos::Host do
  before(:each) do
    Asbestos.reset!
  end

  context "the 'address' DSL call" do

    it "should create a new named address" do
      address "some_host", '1.2.3.4'

      Asbestos::Address['some_host'].should == ['1.2.3.4']
    end

    it "should create a new address set" do
      address "some_host", ['1.2.3.4', 'some_hostname']

      Asbestos::Address['some_host'].should == ['1.2.3.4', 'some_hostname']
    end

  end
end

