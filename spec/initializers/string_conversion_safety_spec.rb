# frozen_string_literal: true

require 'spec_helper'
require 'rspec-parameterized'

RSpec.describe StringConversionSafety, feature_category: :shared do
  using RSpec::Parameterized::TableSyntax

  let(:small_string) { "123" }
  let(:large_string) { "1" * (described_class.max_string_size + 1) }

  describe '.check_string_size!' do
    it 'allows strings smaller than the limit' do
      expect { described_class.check_string_size!(small_string) }.not_to raise_error
    end

    it 'raises ConversionError for strings larger than the limit' do
      expect do
        described_class.check_string_size!(large_string)
      end.to raise_error(StringConversionSafety::ConversionError)
    end
  end

  describe 'String methods' do
    describe 'successful conversions' do
      where(:method, :value, :expected_result) do
        [
          [:to_i, "123", 123],
          [:to_r, "123", Rational(123)],
          [:to_c, "123", Complex(123)]
        ]
      end

      with_them do
        it "correctly handles the conversion" do
          expect(value.send(method)).to eq(expected_result)
        end
      end
    end

    describe 'error cases' do
      where(:method, :expected_result) do
        [
          [:to_i, StringConversionSafety::ConversionError],
          [:to_r, StringConversionSafety::ConversionError],
          [:to_c, StringConversionSafety::ConversionError]
        ]
      end

      with_them do
        it "raises error for large strings" do
          expect { large_string.send(method) }.to raise_error(expected_result)
        end
      end
    end
  end

  describe 'Kernel methods' do
    describe 'successful conversions' do
      where(:method, :value, :expected_result) do
        [
          [:Integer, "123", 123],
          [:Rational, "123", Rational(123)],
          [:Complex, "123", Complex(123)],
          [:Integer, 123.45, 123],
          [:Rational, 123, Rational(123)],
          [:Complex, 123, Complex(123)]
        ]
      end

      with_them do
        it "correctly handles the conversion" do
          expect(send(method, value)).to eq(expected_result)
        end
      end
    end

    describe 'error cases' do
      where(:method, :expected_result) do
        [
          [:Integer, StringConversionSafety::ConversionError],
          [:Rational, StringConversionSafety::ConversionError],
          [:Complex, StringConversionSafety::ConversionError]
        ]
      end

      with_them do
        it "raises error for large strings" do
          expect { send(method, large_string) }.to raise_error(expected_result)
        end
      end
    end
  end

  describe 'configuration' do
    it 'allows changing the max_string_size' do
      original_size = described_class.max_string_size
      begin
        described_class.max_string_size = 10
        expect { "12345678901".to_i }.to raise_error(StringConversionSafety::ConversionError)
        expect { "1234567890".to_i }.not_to raise_error
      ensure
        described_class.max_string_size = original_size
      end
    end
  end
end
