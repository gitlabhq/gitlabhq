# frozen_string_literal: true

require 'fast_spec_helper'

require 'declarative_policy'
require 'request_store'
require 'tempfile'

require 'gitlab/safe_request_store'

require_relative '../../app/models/ability'
require_relative '../support/ability_check'

RSpec.describe Support::AbilityCheck, feature_category: :system_access do # rubocop:disable RSpec/SpecFilePathFormat
  let(:user) { :user }
  let(:child) { Testing::Child.new }
  let(:parent) { Testing::Parent.new(child) }

  before do
    # Usually done in spec/spec_helper.
    described_class.inject(Ability.singleton_class)

    stub_const('Testing::BasePolicy', Class.new(DeclarativePolicy::Base))

    stub_const('Testing::Parent', Struct.new(:parent_of))
    stub_const('Testing::ParentPolicy', Class.new(Testing::BasePolicy) do
      delegate { @subject.parent_of }
      condition(:is_adult) { @subject.is_a?(Testing::Parent) }
      rule { is_adult }.enable :drink_coffee
    end)

    stub_const('Testing::Child', Class.new)
    stub_const('Testing::ChildPolicy', Class.new(Testing::BasePolicy) do
      condition(:always) { true }
      rule { always }.enable :eat_ice
    end)
  end

  def expect_no_deprecation_warning(&block)
    expect(&block).not_to output.to_stderr
  end

  def expect_deprecation_warning(policy_class, ability, &block)
    expect(&block)
      .to output(/DEPRECATION WARNING: Ability :#{ability} in #{policy_class} not found./)
      .to_stderr
  end

  def expect_allowed(user, ability, subject)
    expect(Ability.allowed?(user, ability, subject))
  end

  shared_examples 'ability found' do
    it 'policy ability is found' do
      expect_no_deprecation_warning do
        expect_allowed(user, ability, subject).to eq(true)
      end
    end
  end

  shared_examples 'ability not found' do |warning:|
    description = 'policy ability is not found'
    description += warning ? ' and emits a warning' : ' without warning'

    it description do
      check = -> { expect_allowed(user, ability, subject).to eq(false) }

      if warning
        expect_deprecation_warning(warning, ability, &check)
      else
        expect_no_deprecation_warning(&check)
      end
    end
  end

  shared_context 'with custom TODO YAML' do
    let(:yaml_file) { Tempfile.new }

    before do
      yaml_file.write(yaml_content)
      yaml_file.rewind

      stub_const("#{described_class}::Checker::TODO_YAML", yaml_file.path)
      described_class::Checker.clear_memoization(:todo_list)
    end

    after do
      described_class::Checker.clear_memoization(:todo_list)
      yaml_file.unlink
    end
  end

  describe 'checking ability' do
    context 'with valid direct ability' do
      let(:subject) { parent }
      let(:ability) { :drink_coffee }

      include_examples 'ability found'

      context 'with empty TODO yaml' do
        let(:yaml_content) { nil }

        include_context 'with custom TODO YAML'
        include_examples 'ability found'
      end

      context 'with non-Hash TODO yaml' do
        let(:yaml_content) { '[]' }

        include_context 'with custom TODO YAML'
        include_examples 'ability found'
      end
    end

    context 'with unreachable ability' do
      let(:subject) { child }
      let(:ability) { :drink_coffee }

      include_examples 'ability not found', warning: 'Testing::ChildPolicy'

      context 'when ignored in TODO YAML' do
        let(:yaml_content) do
          <<~YAML
          Testing::ChildPolicy:
          - #{ability}
          YAML
        end

        include_context 'with custom TODO YAML'
        include_examples 'ability not found', warning: false
      end
    end

    context 'with unknown ability' do
      let(:subject) { parent }
      let(:ability) { :unknown }

      include_examples 'ability not found', warning: 'Testing::ParentPolicy'
    end

    context 'with delegated ability' do
      let(:subject) { parent }
      let(:ability) { :eat_ice }

      include_examples 'ability found'
    end
  end
end
