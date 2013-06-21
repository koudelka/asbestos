
require 'spec_helper'

describe Asbestos::RuleSet do
  before(:each) do
    Asbestos.reset!
  end

  context "the 'rule_set' DSL call" do
    it "should store the block as a template" do

      block = proc do;
      end

      rule_set 'rulesetname', &block

      Asbestos::RuleSet[:rulesetname].should be block
    end
  end

  context "context DSL" do
    [:rule, :accept, :reject, :drop, :log].each do |action|
      it "should send '#{action}' to the firewall module" do

        Asbestos.firewall.should_receive action

        rule_set 'rulesetname' do
          eval "#{action} :chain => 'input', :remote_address => '224.0.0.0/4'"
        end

        host 'hostname' do
          rulesetname
        end

        Host['hostname'].call.ruleset_rules
      end
    end

    it "should add raw commands with 'command'" do
      rule_set 'rulesetname' do
        command "some raw firewall command"
      end

      host 'hostname' do
        rulesetname
      end

      Host['hostname'].call.rules.join("\n").should match(/some raw firewall command/)
    end

    it "should generate firewall rules properly"
    it "should handle the :from argument to from_each properly"
    it "should handle the :from argument to from_each_address properly"
  end
end
