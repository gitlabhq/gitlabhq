# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Config::Entry::Validators::NestedArrayHelpers do
  let(:config_struct) do
    Struct.new(:value, keyword_init: true) do
      include ActiveModel::Validations
      extend Gitlab::Config::Entry::Validators::NestedArrayHelpers

      validates_each :value do |record, attr, value|
        unless validate_nested_array(value, 2) { |v| v.is_a?(Integer) }
          record.errors.add(attr, "is invalid")
        end
      end
    end
  end

  describe '#validate_nested_array' do
    let(:config) { config_struct.new(value: value) }

    subject(:errors) { config.errors }

    before do
      config.valid?
    end

    context 'with valid values' do
      context 'with arrays of integers' do
        let(:value) { [10, 11] }

        it { is_expected.to be_empty }
      end

      context 'with nested arrays of integers' do
        let(:value) { [10, [11, 12]] }

        it { is_expected.to be_empty }
      end
    end

    context 'with invalid values' do
      subject(:error_messages) { errors.messages }

      context 'with single integers' do
        let(:value) { 10 }

        it { is_expected.to eq({ value: ['is invalid'] }) }
      end

      context 'when it is nested over the limit' do
        let(:value) { [10, [11, [12]]] }

        it { is_expected.to eq({ value: ['is invalid'] }) }
      end

      context 'when a value in the array is not valid' do
        let(:value) { [10, 11.5] }

        it { is_expected.to eq({ value: ['is invalid'] }) }
      end

      context 'when a value in the nested array is not valid' do
        let(:value) { [10, [11, 12.5]] }

        it { is_expected.to eq({ value: ['is invalid'] }) }
      end
    end
  end
end
