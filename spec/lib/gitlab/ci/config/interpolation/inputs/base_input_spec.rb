# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Config::Interpolation::Inputs::BaseInput, feature_category: :pipeline_composition do
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

  describe '#valid_value?' do
    it 'is not implemented' do
      expect do
        described_class.new(
          name: 'website', spec: { website: nil }, value: { website: 'example.com' }
        ).valid_value?('test')
      end.to raise_error(NotImplementedError)
    end
  end
end
