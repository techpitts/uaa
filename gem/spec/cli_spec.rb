#--
# Cloud Foundry 2012.02.03 Beta
# Copyright (c) [2009-2012] VMware, Inc. All Rights Reserved.
#
# This product is licensed to you under the Apache License, Version 2.0 (the "License").
# You may not use this product except in compliance with the License.
#
# This product includes a number of subcomponents with
# separate copyright notices and license terms. Your use of these
# subcomponents is subject to the terms and conditions of the
# subcomponent's license, as noted in the LICENSE file.
#++

require 'spec_helper'
require 'cli'
require 'highline'
require 'stringio'

describe "Uaa cli wrapper" do

  before :each do
    @dispatcher = mock(Cloudfoundry::Uaa::Dispatcher)
  end

  def cli(args)
    cli = Cloudfoundry::Uaa::Cli.new(args.split)
    cli.dispatcher = @dispatcher
    cli
  end

  it "should be verbose with --verbose" do
    @dispatcher.stub!(:dispatch).and_return("FOO")
    cli = cli("--verbose decode")
    cli.run().should be_true
    cli.options[:verbose].should be_true
  end

  it "should exit with non nil status if there is a valid switch but no command" do
    cli = cli("--verbose")
    result = cli.run()
    result.should_not be_nil
    result.should be_false
  end

  it "should exit cleanly with valid 'target'" do
    @dispatcher.stub!(:dispatch)
    cli = cli("target uaa.vcap.me")
    cli.run().should be_true
    cli.command.should == :target
  end

  it "should exit cleanly with valid 'decode'" do
    @dispatcher.stub!(:dispatch)
    cli = cli("decode FOO")
    cli.run().should be_true
    cli.command.should == :decode
  end

  it "should exit cleanly with valid 'prompts'" do
    @dispatcher.stub!(:dispatch)
    cli = cli("prompts")
    cli.run().should be_true
    cli.command.should == :prompts
  end

  it "should use the client id if supplied" do
    @dispatcher.should_receive(:dispatch).with(:login, ["marissa", "koala"], {:verbose=>false, :save_token=>true, :client_id=>"foo", :username=>"marissa", :password=>"koala"})
    result = cli("--client_id foo login marissa koala").run()
  end

  it "should prompt for username and password" do
    @dispatcher.should_receive(:dispatch).with(:login, [], {:verbose=>true, :save_token=>true}).and_raise(prompts_error)
    @dispatcher.should_receive(:dispatch).with(:login, [], {:verbose=>true, :save_token=>true, :username=>"marissa", :password=>"koala"})
    runner = cli("--verbose login")
    runner.terminal = HighLine.new(StringIO.new("marissa\nkoala"))
    result = runner.run()
    result.should be_true
  end

  it "should prompt for password" do
    @dispatcher.should_receive(:dispatch).with(:login, ["marissa"], {:verbose=>true, :save_token=>true, :username=>"marissa"}).and_raise(prompts_error)
    @dispatcher.should_receive(:dispatch).with(:login, ["marissa"], {:verbose=>true, :save_token=>true, :username=>"marissa", :password=>"koala"})
    runner = cli("--verbose login marissa")
    runner.terminal = HighLine.new(StringIO.new("koala"))
    result = runner.run()
    result.should be_true
  end

  it "should return a String when dispatched one" do
    @dispatcher.stub!(:dispatch).and_return("FOO")
    result = cli("decode BAR").run()
    result.should == "FOO"
  end

  it "should return a JSON literal when dispatched a hash" do
    @dispatcher.stub!(:dispatch).and_return({:foo=>"bar"})
    result = cli("decode FOO").run()
    result.should == '{"foo":"bar"}'
  end

  def prompts_error
    Cloudfoundry::Uaa::PromptRequiredError.new({:username=>["text", "Username"],:password=>["password", "Password"]})
  end

end
