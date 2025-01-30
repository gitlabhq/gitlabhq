# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Type::JsonbBoolean, feature_category: :database do
  describe "#cast" do
    # rubocop:disable Lint/BooleanSymbol -- To test expected behavior with boolean symbols
    context 'with falsy values' do
      [false, 0, '0', 'f', 'false', 'off', 'F', 'FALSE', 'OFF', :f, :false, :off].each do |false_value|
        it "returns false for #{false_value}" do
          expect(described_class.new.cast(false_value)).to be false
        end
      end
    end

    context 'with truthy values' do
      [true, 1, '1', 't', 'true', 'on', 'T', 'TRUE', 'ON', :t, :true, :on].each do |true_value|
        it "returns true for #{true_value}" do
          expect(described_class.new.cast(true_value)).to be true
        end
      end
    end
    # rubocop:enable Lint/BooleanSymbol -- To test expected behavior with boolean symbols

    context 'with values that are neither falsy nor truthy' do
      [nil, 'something else', 2, :other_symbol, [], {}].each do |other_value|
        it "returns original value for #{other_value.inspect}" do
          expect(described_class.new.cast(other_value)).to eq(other_value)
        end
      end
    end
  end
end
