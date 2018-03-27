require 'spec_helper'

describe Gitlab::QuickActions::Dsl do
  before :all do
    DummyClass = Struct.new(:project) do
      include Gitlab::QuickActions::Dsl # rubocop:disable RSpec/DescribedClass

      desc 'A command with no args'
      command :no_args, :none do
        "Hello World!"
      end

      params 'The first argument'
      explanation 'Static explanation'
      command :explanation_with_aliases, :once, :first do |arg|
        arg
      end

      desc do
        "A dynamic description for #{noteable.upcase}"
      end
      params 'The first argument', 'The second argument'
      command :dynamic_description do |args|
        args.split
      end

      command :cc

      explanation do |arg|
        "Action does something with #{arg}"
      end
      condition do
        project == 'foo'
      end
      command :cond_action do |arg|
        arg
      end

      parse_params do |raw_arg|
        raw_arg.strip
      end
      command :with_params_parsing do |parsed|
        parsed
      end

      params '<Comment>'
      substitution :something do |text|
        "#{text} Some complicated thing you want in here"
      end
    end
  end

  describe '.command_definitions' do
    it 'returns an array with commands definitions' do
      no_args_def, explanation_with_aliases_def, dynamic_description_def,
      cc_def, cond_action_def, with_params_parsing_def, substitution_def =
        DummyClass.command_definitions

      expect(no_args_def.name).to eq(:no_args)
      expect(no_args_def.aliases).to eq([:none])
      expect(no_args_def.description).to eq('A command with no args')
      expect(no_args_def.explanation).to eq('')
      expect(no_args_def.params).to eq([])
      expect(no_args_def.condition_block).to be_nil
      expect(no_args_def.action_block).to be_a_kind_of(Proc)
      expect(no_args_def.parse_params_block).to be_nil

      expect(explanation_with_aliases_def.name).to eq(:explanation_with_aliases)
      expect(explanation_with_aliases_def.aliases).to eq([:once, :first])
      expect(explanation_with_aliases_def.description).to eq('')
      expect(explanation_with_aliases_def.explanation).to eq('Static explanation')
      expect(explanation_with_aliases_def.params).to eq(['The first argument'])
      expect(explanation_with_aliases_def.condition_block).to be_nil
      expect(explanation_with_aliases_def.action_block).to be_a_kind_of(Proc)
      expect(explanation_with_aliases_def.parse_params_block).to be_nil

      expect(dynamic_description_def.name).to eq(:dynamic_description)
      expect(dynamic_description_def.aliases).to eq([])
      expect(dynamic_description_def.to_h(OpenStruct.new(noteable: 'issue'))[:description]).to eq('A dynamic description for ISSUE')
      expect(dynamic_description_def.explanation).to eq('')
      expect(dynamic_description_def.params).to eq(['The first argument', 'The second argument'])
      expect(dynamic_description_def.condition_block).to be_nil
      expect(dynamic_description_def.action_block).to be_a_kind_of(Proc)
      expect(dynamic_description_def.parse_params_block).to be_nil

      expect(cc_def.name).to eq(:cc)
      expect(cc_def.aliases).to eq([])
      expect(cc_def.description).to eq('')
      expect(cc_def.explanation).to eq('')
      expect(cc_def.params).to eq([])
      expect(cc_def.condition_block).to be_nil
      expect(cc_def.action_block).to be_nil
      expect(cc_def.parse_params_block).to be_nil

      expect(cond_action_def.name).to eq(:cond_action)
      expect(cond_action_def.aliases).to eq([])
      expect(cond_action_def.description).to eq('')
      expect(cond_action_def.explanation).to be_a_kind_of(Proc)
      expect(cond_action_def.params).to eq([])
      expect(cond_action_def.condition_block).to be_a_kind_of(Proc)
      expect(cond_action_def.action_block).to be_a_kind_of(Proc)
      expect(cond_action_def.parse_params_block).to be_nil

      expect(with_params_parsing_def.name).to eq(:with_params_parsing)
      expect(with_params_parsing_def.aliases).to eq([])
      expect(with_params_parsing_def.description).to eq('')
      expect(with_params_parsing_def.explanation).to eq('')
      expect(with_params_parsing_def.params).to eq([])
      expect(with_params_parsing_def.condition_block).to be_nil
      expect(with_params_parsing_def.action_block).to be_a_kind_of(Proc)
      expect(with_params_parsing_def.parse_params_block).to be_a_kind_of(Proc)

      expect(substitution_def.name).to eq(:something)
      expect(substitution_def.aliases).to eq([])
      expect(substitution_def.description).to eq('')
      expect(substitution_def.explanation).to eq('')
      expect(substitution_def.params).to eq(['<Comment>'])
      expect(substitution_def.condition_block).to be_nil
      expect(substitution_def.action_block.call('text')).to eq('text Some complicated thing you want in here')
      expect(substitution_def.parse_params_block).to be_nil
    end
  end
end
