# frozen_string_literal: true

require 'fast_spec_helper'
require_relative Rails.root.join('lib/ci/pipeline_creation/inputs/base_input.rb')

RSpec.describe Ci::PipelineCreation::Inputs::BaseInput, feature_category: :pipeline_composition do
  describe '.matches?' do
    context 'when given is a hash' do
      before do
        stub_const('TestInput', Class.new(described_class))

        TestInput.class_eval do
          def self.type_name
            'test'
          end
        end
      end

      context 'when the spec type matches the input type' do
        it 'returns true' do
          expect(TestInput.matches?({ type: 'test' })).to be_truthy
        end
      end

      context 'when the spec type does not match the input type' do
        it 'returns false' do
          expect(TestInput.matches?({ type: 'string' })).to be_falsey
        end
      end
    end

    context 'when not given a hash' do
      it 'returns false' do
        expect(described_class.matches?([])).to be_falsey
      end
    end
  end

  describe '.type_name' do
    it 'is not implemented' do
      expect { described_class.type_name }.to raise_error(NotImplementedError)
    end
  end

  describe 'attributes' do
    let(:spec) do
      {
        type: 'string',
        default: 'default-value',
        options: %w[default-value another-value]
      }
    end

    let(:input) { described_class.new(name: :the_input_name, spec: spec) }

    it 'has methods to return attributes' do
      expect(input).not_to be_required
      expect(input.default).to eq('default-value')
      expect(input.options).to eq(%w[default-value another-value])
    end
  end
end
