require 'spec_helper'

describe Asbestos::Host do
  before(:each) do
    Asbestos.reset!
  end

  context "the 'host' DSL call" do

    context "when a block is provided" do
      it "should create a new host" do
        Host.all.tap do |hosts|
          hosts.should be_empty
          host 'hostname' do
          end

          hosts.should_not be_empty
        end
      end

      it "should evaluate the block in the context of the new host" do
        context = nil

        host 'hostname' do
          context = self
        end

        Host['hostname'].call.should be context
      end
    end

    context "when a block is not provided" do
      it "should create a new host" do
        Host.all.tap do |hosts|
          hosts.should be_empty
          host 'hostname'
          hosts.should_not be_empty
        end
      end
    end
  end

  context "context DSL" do
    it "should properly add services via 'runs'" do
      service :ssh do
        port :ssh
      end

      host 'hostname' do
        runs :ssh
      end

      Host['hostname'].call.rulesets.first.name.should be :ssh
    end

    it "should properly add be added to groups via 'group'" do
      host 'hostname' do
        group :some_group
      end

      Host.groups.should have_key(:some_group)
      Host.groups[:some_group].should == [Host['hostname'].call]
    end

    context "the 'interface' call" do
      it "should tag singular interfaces" do
        host 'hostname' do
          interface :some_tag, :eth0
        end

        Host['hostname'].call.interfaces[:some_tag].should == [:eth0]
      end

      it "should tag multiple interfaces" do
        host 'hostname' do
          interface :some_tag, [:eth0, :eth1]
        end

        Host['hostname'].call.interfaces[:some_tag].should == [:eth0, :eth1]
      end

      it "should add interfaces to the tag when called more than once" do
        host 'hostname' do
          interface :some_tag, :eth0
          interface :some_tag, :eth1
        end

        Host['hostname'].call.interfaces[:some_tag].should == [:eth0, :eth1]
      end

      context "generating addresses" do
        context "defaults" do
          it "should generate defaults for singular interfaces" do
            host 'hostname' do
              interface :some_tag, :eth0
            end

            Host['hostname'].call.addresses[:eth0].should == 'hostname_some_tag'
          end

          it "should generate defaults for multiple interfaces" do
            host 'hostname' do
              interface :some_tag, [:eth0, :eth1]
            end

            Host['hostname'].call.addresses[:eth0].should == 'hostname_some_tag_eth0'
            Host['hostname'].call.addresses[:eth1].should == 'hostname_some_tag_eth1'
          end
        end

        context "overriding" do
          context "singular interface" do
            it "should allow overriding with a static address" do
              host 'hostname' do
                interface :some_tag, :eth0, "1.2.3.4"
              end

              Host['hostname'].call.addresses[:eth0].should == '1.2.3.4'
            end

            it "should allow overriding with a block" do
              host 'hostname' do
                interface :some_tag, :eth0 do |host|
                  "#{host.name}_blah"
                end
              end

              Host['hostname'].call.addresses[:eth0].should == 'hostname_blah'
            end
          end

          context "multiple interfaces" do
            it "should not allow overriding with a static address" do
              expect do
                host 'hostname' do
                  interface :some_tag, [:eth0, :eth1], '1.2.3.4'
                end
              end.to raise_error
            end

            it "should allow overriding with a block" do
              host 'hostname' do
                interface :some_tag, [:eth0, :eth1] do |host, if_name|
                  "#{host.name}_blah_#{if_name}"
                end
              end

              Host['hostname'].call.addresses[:eth0].should == 'hostname_blah_eth0'
              Host['hostname'].call.addresses[:eth1].should == 'hostname_blah_eth1'
            end
          end
        end
      end
    end

    it "should turn on denial logging with 'log_denials'" do
      host 'hostname' do
        log_denials
      end

      Host['hostname'].call.log_denials?.should be_true
    end

    it "should add iptables chains with the 'chain' call" do
      host 'hostname' do
        chain :some_chain, :drop
      end

      Host['hostname'].call.chains[:some_chain].should be :drop
    end

    it "should raise an error for unknown DSL calls" do
      expect {
        host 'hostname' do
          this_isnt_a_dsl_call
        end
      }.to raise_error
    end

  end # context DSL

end
