
require 'spec_helper'

describe Asbestos::Firewall::IPTables do
  before(:each) do
    Asbestos.reset!

    host "hostname" do
      chain :chainname
    end

    host "drop_by_default" do
      chain :input, :drop
    end

    host "logs_denials" do
      log_denials
    end

    @host = Host['hostname'].call
    @drop_by_default_host = Host['drop_by_default'].call
    @logs_denials_host = Host['logs_denials'].call
  end

  context "#preamble" do
    it "denotes the start of the filter table"  do
      Asbestos::Firewall::IPTables.preamble(@host).should include('*filter')
    end

    it "generates preable with the host's chains"  do
      preamble = Asbestos::Firewall::IPTables.preamble(@host)
      [:input, :output].each do |chain|
        preamble.should include(":#{chain.upcase} ACCEPT [0:0]")
      end

      preamble.should include(":CHAINNAME - [0:0]")
    end
  end

  context "#postamble" do
    it "should COMMIT the rules" do
      Asbestos::Firewall::IPTables.postamble(@host).should include('COMMIT')
    end

    context "log_denials" do
      it "should log denials if told to do so" do
        Asbestos.firewall.should_receive(:log)
        Asbestos::Firewall::IPTables.postamble(@logs_denials_host)
      end

      it "should log denials if not told to do so" do
        Asbestos.firewall.should_not_receive(:log)
        Asbestos::Firewall::IPTables.postamble(@host)
      end
    end

    context "default input chain action" do
      it "should drop packets with a rule when :input chain's policy is ACCEPT" do
        Asbestos.firewall.should_receive(:drop)
        Asbestos::Firewall::IPTables.postamble(@host)
      end

      it "should pass to the chain's policy  when :input chain's policy is not ACCEPT" do
        Asbestos.firewall.should_not_receive(:drop)
        Asbestos::Firewall::IPTables.postamble(@drop_by_default_host)
      end
    end
  end

  context "#chain" do
    context "when no action is provided" do
      it "should generate chain default action '-'" do
        Asbestos::Firewall::IPTables.chain(:chainname, :none).should == ":CHAINNAME - [0:0]"
      end
    end

    context "when an action is provided" do
      it "should generate a proper default action" do
        Asbestos::Firewall::IPTables.chain(:chainname, :accept).should == ":CHAINNAME ACCEPT [0:0]"
      end
    end
  end

  context "firewall verbs" do
    [:accept, :reject, :drop, :log].each do |action|
      it "should call #rule with :action => :#{action}" do
        Asbestos.firewall.should_receive(:rule).with(:action => action)
        Asbestos::Firewall::IPTables.send(action, {})
      end
    end
  end

  context "#rule" do
    context ":chain" do
      it "should default to the INPUT chain" do
        Asbestos::Firewall::IPTables.rule({}).should == "-A INPUT"
      end

      it "should use the provided chain" do
        Asbestos::Firewall::IPTables.rule(:chain => :somechain).should == "-A SOMECHAIN"
      end
    end

    context ":action" do
      it "should use the :action when provided " do
        Asbestos::Firewall::IPTables.rule({:action => :drop}).should == "-A INPUT -j DROP"
      end
    end

    context ":interface and :direction" do
      context "when the chain is built-in" do
        context "when :direction is provided" do
          it "should use :direction if provided properly" do
            Asbestos::Firewall::IPTables.rule({:interface => :eth0, :direction => :incoming}).should == "-A INPUT -i eth0"
            Asbestos::Firewall::IPTables.rule({:interface => :eth0, :direction => :outgoing}).should == "-A INPUT -o eth0"
          end

          it "should raise an error if :direction isn't provided properly" do
            expect do
              Asbestos::Firewall::IPTables.rule({:interface => :eth0, :direction => :junkvalue})
            end.to raise_error
          end
        end

        context "when :direction is not provided" do
          it "should use the incoming direction on the :input or :prerouting chains" do
            Asbestos::Firewall::IPTables.rule({:chain => :input, :interface => :eth0}).should == "-A INPUT -i eth0"
            Asbestos::Firewall::IPTables.rule({:chain => :prerouting, :interface => :eth0}).should == "-A PREROUTING -i eth0"
          end

          it "should use the outgoing direction on the :output or :postrouting chains" do
            Asbestos::Firewall::IPTables.rule({:chain => :output, :interface => :eth0}).should == "-A OUTPUT -o eth0"
            Asbestos::Firewall::IPTables.rule({:chain => :postrouting, :interface => :eth0}).should == "-A POSTROUTING -o eth0"
          end
        end
      end

      context "when using a user-defined chain" do
        it "should raise an error if :direction isn't provided properly" do
          expect do
            Asbestos::Firewall::IPTables.rule({:chain => :mychain, :interface => :eth0, :direction => :junkvalue})
          end.to raise_error
        end

        it "should use :direction if provided properly" do
          Asbestos::Firewall::IPTables.rule({:chain => :mychain, :interface => :eth0, :direction => :incoming}).should == "-A MYCHAIN -i eth0"
          Asbestos::Firewall::IPTables.rule({:chain => :mychain, :interface => :eth0, :direction => :outgoing}).should == "-A MYCHAIN -o eth0"
        end
      end
    end

    context ":comment" do
      it "should provided the comment with the interface when :interface is provided" do
        Asbestos::Firewall::IPTables.rule({:comment => 'this is a comment', :interface => :eth0}).should == %{-A INPUT -i eth0 -m comment --comment "this is a comment on eth0"}
      end
    end

    {
      [:action, :drop]                    => '-j DROP',
      [:protocol, :tcp]                   => '-p tcp',
      [:local_address, '1.2.3.4']         => '-d 1.2.3.4',
      [:remote_address, '5.6.7.8']        => '-s 5.6.7.8',
      [:port, 80]                         => '--dport 80',
      [:limit, '5/min']                   => '-m limit --limit 5/min',
      [:log_prefix, 'iptables dropped: '] => %{--log-prefix "iptables dropped: "},
      [:log_level, 7]                     => '--log-level 7',
      [:icmp_type, 'echo-request']        => '--icmp-type echo-request',
      [:comment, 'this is a comment']     => %{-m comment --comment "this is a comment"},
      [:state, :new]                      => '-m state --state NEW'
    }.each do |action_and_arg, expected|
      action, arg = *action_and_arg
      context ":#{action}" do
        it "should use #{action} if provided" do
          Asbestos::Firewall::IPTables.rule({action => arg}).should == "-A INPUT #{expected}"
        end
      end
    end
  end
end
