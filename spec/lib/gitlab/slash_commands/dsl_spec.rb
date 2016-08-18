require 'spec_helper'

describe Gitlab::SlashCommands::Dsl do
  before :all do
    DummyClass = Struct.new(:project) do
      include Gitlab::SlashCommands::Dsl

      desc 'A command with no args'
      command :no_args, :none do
        "Hello World!"
      end

      params 'The first argument'
      command :one_arg, :once, :first do |arg1|
        arg1
      end

      desc do
        "A dynamic description for #{noteable.upcase}"
      end
      params 'The first argument', 'The second argument'
      command :two_args do |arg1, arg2|
        [arg1, arg2]
      end

      command :cc

      condition do
        project == 'foo'
      end
      command :cond_action do |arg|
        arg
      end
    end
  end

  describe '.command_definitions' do
    it 'returns an array with commands definitions' do
      no_args_def, one_arg_def, two_args_def, cc_def, cond_action_def = DummyClass.command_definitions

      expect(no_args_def.name).to eq(:no_args)
      expect(no_args_def.aliases).to eq([:none])
      expect(no_args_def.description).to eq('A command with no args')
      expect(no_args_def.params).to eq([])
      expect(no_args_def.condition_block).to be_nil
      expect(no_args_def.action_block).to be_a_kind_of(Proc)

      expect(one_arg_def.name).to eq(:one_arg)
      expect(one_arg_def.aliases).to eq([:once, :first])
      expect(one_arg_def.description).to eq('')
      expect(one_arg_def.params).to eq(['The first argument'])
      expect(one_arg_def.condition_block).to be_nil
      expect(one_arg_def.action_block).to be_a_kind_of(Proc)

      expect(two_args_def.name).to eq(:two_args)
      expect(two_args_def.aliases).to eq([])
      expect(two_args_def.to_h(noteable: "issue")[:description]).to eq('A dynamic description for ISSUE')
      expect(two_args_def.params).to eq(['The first argument', 'The second argument'])
      expect(two_args_def.condition_block).to be_nil
      expect(two_args_def.action_block).to be_a_kind_of(Proc)

      expect(cc_def.name).to eq(:cc)
      expect(cc_def.aliases).to eq([])
      expect(cc_def.description).to eq('')
      expect(cc_def.params).to eq([])
      expect(cc_def.condition_block).to be_nil
      expect(cc_def.action_block).to be_nil

      expect(cond_action_def.name).to eq(:cond_action)
      expect(cond_action_def.aliases).to eq([])
      expect(cond_action_def.description).to eq('')
      expect(cond_action_def.params).to eq([])
      expect(cond_action_def.condition_block).to be_a_kind_of(Proc)
      expect(cond_action_def.action_block).to be_a_kind_of(Proc)
    end
  end
end
