# frozen_string_literal: true

require 'fast_spec_helper'
require 'rspec-parameterized'

RSpec.describe StructWithKwargs, feature_category: :tooling do
  let(:const_name) { 'TEST_STRUCT' }

  before do
    stub_const(const_name, struct)
  end

  context 'with lack of keyword_init: true' do
    subject(:struct) { Struct.new(:foo) }

    it { is_expected.to include(described_class::KwargsCheck) }

    it 'accepts plain values' do
      expect(struct.new(23)).to have_attributes(foo: 23)
    end

    it 'accepts hash' do
      expect(struct.new({ foo: 23 })).to have_attributes(foo: { foo: 23 })
    end

    it 'raises with kwargs' do
      expect { struct.new(foo: 23) }
        .to raise_error(RuntimeError, /Passing only keyword arguments to TEST_STRUCT#initialize/)
    end

    context 'and also positional arguments' do
      subject(:struct) { Struct.new(:foo, :bar) }

      it 'accepts mix of plain and hash' do
        expect(struct.new(1, x: 23)).to have_attributes(foo: 1, bar: { x: 23 })
      end

      it 'raises with kwargs only' do
        expect { struct.new(foo: 23, bar: 42) }
          .to raise_error(RuntimeError, /Passing only keyword arguments to TEST_STRUCT#initialize/)
      end
    end
  end

  context 'with Struct.new(..., keyword_init: true)' do
    subject(:struct) { Struct.new(:foo, keyword_init: true) }

    it { is_expected.not_to include(described_class::KwargsCheck) }

    it 'accepts kwargs or hash', :aggregate_failures do
      expect(struct.new(foo: 23)).to have_attributes(foo: 23)
      expect(struct.new({ foo: 23 })).to have_attributes(foo: 23)
    end
  end

  describe 'excludes' do
    where(:exclude) { described_class::EXCLUDE }

    with_them do
      let(:const_name) { exclude }

      subject(:struct) do
        Struct.new(:a) do
          # Simulate libraries' implementation.
          def initialize(**kwargs)
            super()

            kwargs.each do |key, value|
              self[key] = value
            end
          end
        end
      end

      it { is_expected.to include(described_class::KwargsCheck) }

      it 'accepts hash' do
        expect(struct.new(a: 23)).to have_attributes(a: 23)
      end
    end
  end
end
