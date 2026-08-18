# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Aggregation::PartDefinition, feature_category: :database do
  let(:name) { :test_part }
  let(:type) { :integer }
  let(:expression) { -> { 'COUNT(*)' } }
  let(:secondary_expression) { -> { 'SUM(value)' } }
  let(:description) { 'Test part description' }
  let(:formatter) { ->(val) { val * 2 } }

  describe '#format_value' do
    it 'applies the formatter to the value if formatter is present' do
      expect(described_class.new(name, type, formatter: formatter).format_value(5)).to eq(10)
    end

    it 'returns the value unchanged without formatter' do
      expect(described_class.new(name, type).format_value(42)).to eq(42)
    end
  end

  describe '#parameterized?' do
    subject(:part) { described_class.new(name, type) }

    it { is_expected.not_to be_parameterized }
  end

  describe '#identifier' do
    subject(:part) { described_class.new(name, type) }

    it 'returns the part name' do
      expect(part.identifier).to eq(name)
    end
  end

  describe '#instance_key' do
    subject(:part) { described_class.new(name, type) }

    it 'returns the identifier as a string' do
      expect(part.instance_key({})).to eq(name.to_s)
    end
  end

  describe 'dotted names' do
    let(:dotted_class) do
      Class.new(described_class) do
        def identifier
          dotted_name? ? name : :"#{name}_derived"
        end

        private

        def supports_dotted_identifier?
          true
        end
      end
    end

    it 'raises ArgumentError when the definition does not support dotted names' do
      expect { described_class.new(:"duration.max", type, expression) }
        .to raise_error(ArgumentError, /Dotted name `duration.max` is not supported/)
    end

    it 'uses the dotted name verbatim as identifier, skipping derivation' do
      expect(dotted_class.new(:"duration.max", type, expression).identifier).to eq(:"duration.max")
    end

    it 'derives the identifier for dot-free names' do
      expect(dotted_class.new(:duration, type).identifier).to eq(:duration_derived)
    end

    it 'sanitizes dots in the instance key' do
      expect(dotted_class.new(:"duration.max", type, expression).instance_key({})).to eq('duration__max')
    end

    describe '#identifier_parts' do
      it 'returns a single segment for plain identifiers' do
        expect(described_class.new(name, type).identifier_parts).to eq([name])
      end

      it 'returns two segments for dotted identifiers' do
        expect(dotted_class.new(:"duration.max", type, expression).identifier_parts).to eq([:duration, :max])
      end
    end

    it 'raises ArgumentError for more than one dot' do
      expect { dotted_class.new(:"duration.max.extra", type, expression) }
        .to raise_error(ArgumentError, /Invalid dotted name/)
    end

    it 'raises ArgumentError for invalid segments' do
      ['duration.', '.max', 'duration.1max', 'Duration.max'].each do |invalid_name|
        expect { dotted_class.new(invalid_name.to_sym, type, expression) }
          .to raise_error(ArgumentError, /Invalid dotted name/)
      end
    end

    describe '#source_column' do
      it 'returns the name for plain identifiers' do
        expect(described_class.new(name, type).send(:source_column)).to eq(name)
      end

      it 'returns the first segment for dotted identifiers' do
        expect(dotted_class.new(:"duration.max", type).send(:source_column)).to eq(:duration)
      end
    end
  end
end
