require 'spec_helper'

describe Gitlab::SlashCommands::Dsl do
  before :all do
    DummyClass = Struct.new(:project) do
      include Gitlab::SlashCommands::Dsl

      desc 'A command with no args'
      command :no_args, :none do
        "Hello World!"
      end

      desc { "A command with #{something}" }
      command :returning do
        42
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

      command :wildcard do |*args|
        args
      end
    end
  end

  describe '.command_definitions' do
    let(:base_expected) do
      [
        {
          name: :no_args, aliases: [:none],
          description: 'A command with no args', params: [],
          condition_block: nil, action_block: a_kind_of(Proc)
        },
        {
          name: :returning, aliases: [],
          description: 'A command returning a value', params: [],
          condition_block: nil, action_block: a_kind_of(Proc)
        },
        {
          name: :one_arg, aliases: [:once, :first],
          description: '', params: ['The first argument'],
          condition_block: nil, action_block: a_kind_of(Proc)
        },
        {
          name: :two_args, aliases: [],
          description: '', params: ['The first argument', 'The second argument'],
          condition_block: nil, action_block: a_kind_of(Proc)
        },
        {
          name: :cc, aliases: [],
          description: '', params: [],
          condition_block: nil, action_block: nil
        },
        {
          name: :wildcard, aliases: [],
          description: '', params: [],
          condition_block: nil, action_block: a_kind_of(Proc)
        }
      ]
    end

    it 'returns an array with commands definitions' do
      no_args_def, returning_def, one_arg_def, two_args_def, cc_def, cond_action_def, wildcard_def = DummyClass.command_definitions

      expect(no_args_def.name).to eq(:no_args)
      expect(no_args_def.aliases).to eq([:none])
      expect(no_args_def.description).to eq('A command with no args')
      expect(no_args_def.params).to eq([])
      expect(no_args_def.condition_block).to be_nil
      expect(no_args_def.action_block).to be_a_kind_of(Proc)

      expect(returning_def.name).to eq(:returning)
      expect(returning_def.aliases).to eq([])
      expect(returning_def.description).to be_a_kind_of(Proc)
      expect(returning_def.to_h(something: "a block description")[:description]).to eq('A command with a block description')
      expect(returning_def.params).to eq([])
      expect(returning_def.condition_block).to be_nil
      expect(returning_def.action_block).to be_a_kind_of(Proc)

      expect(one_arg_def.name).to eq(:one_arg)
      expect(one_arg_def.aliases).to eq([:once, :first])
      expect(one_arg_def.description).to eq('')
      expect(one_arg_def.params).to eq(['The first argument'])
      expect(one_arg_def.condition_block).to be_nil
      expect(one_arg_def.action_block).to be_a_kind_of(Proc)

      expect(cc_def.name).to eq(:cc)
      expect(cc_def.aliases).to eq([])
      expect(cc_def.description).to eq('')
      expect(cc_def.params).to eq([])
      expect(cc_def.condition_block).to be_nil
      expect(cc_def.action_block).to be_nil

      expect(wildcard_def.name).to eq(:wildcard)
      expect(wildcard_def.aliases).to eq([])
      expect(wildcard_def.description).to eq('')
      expect(wildcard_def.params).to eq([])
      expect(wildcard_def.condition_block).to be_nil
      expect(wildcard_def.action_block).to be_a_kind_of(Proc)
    end
  end
end
