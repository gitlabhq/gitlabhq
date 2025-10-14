# frozen_string_literal: true

require 'fast_spec_helper'
require_dependency 'active_model'

RSpec.describe ::Gitlab::Ci::Config::Entry::Includes, feature_category: :pipeline_composition do
  subject(:include_entry) { described_class.new(config) }

  describe '#initialize' do
    let(:config) { 'test.yml' }

    it 'does not increase aspects' do
      2.times { expect { described_class.new(config) }.not_to change { described_class.aspects.count } }
    end
  end

  describe 'validations' do
    let(:config) { [1, 2] }

    let(:includes_entry) { described_class.new(config, max_size: 1) }

    it 'returns invalid' do
      expect(includes_entry).not_to be_valid
    end

    it 'returns the appropriate error' do
      expect(includes_entry.errors).to include('includes config is too long (maximum is 1)')
    end
  end

  describe '#composable_class' do
    let(:config) { ['test.yml'] }

    it 'returns Entry::Include class' do
      expect(include_entry.composable_class).to eq(::Gitlab::Ci::Config::Entry::Include)
    end

    context 'when base implementation is called' do
      # This test ensures coverage of the base composable_class method in BaseIncludes concern
      # that raises NotImplementedError when not overridden by subclasses
      let(:test_class) do
        Class.new(::Gitlab::Config::Entry::ComposableArray) do
          include ::Gitlab::Ci::Config::Entry::Concerns::BaseIncludes
          # Don't override composable_class to test base implementation
        end
      end

      let(:test_instance) { test_class.new(['test.yml']) }

      it 'raises NotImplementedError from base concern' do
        expect do
          test_instance.composable_class
        end.to raise_error(NotImplementedError, 'Subclasses must define composable_class')
      end
    end
  end
end
