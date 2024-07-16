# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::SourceUserPlaceholderReference, feature_category: :importers do
  describe 'associations' do
    it { is_expected.to belong_to(:source_user).class_name('Import::SourceUser') }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:user_reference_column) }
    it { is_expected.to validate_presence_of(:model) }
    it { is_expected.to validate_presence_of(:namespace_id) }
    it { is_expected.to validate_presence_of(:source_user_id) }
    it { is_expected.to validate_numericality_of(:numeric_key).only_integer.is_greater_than(0) }
    it { expect(described_class).to validate_jsonb_schema(['composite_key']) }
    it { is_expected.to allow_value({ id: 1 }).for(:composite_key) }
    it { is_expected.to allow_value({ id: '1' }).for(:composite_key) }
    it { is_expected.to allow_value({ foo: '1', bar: 2 }).for(:composite_key) }
    it { is_expected.not_to allow_value({}).for(:composite_key) }
    it { is_expected.not_to allow_value({ id: 'foo' }).for(:composite_key) }
    it { is_expected.not_to allow_value(1).for(:composite_key) }

    describe '#validate_numeric_or_composite_key_present' do
      def validation_errors(...)
        described_class.new(...).tap(&:validate)
          .errors
          .where(:base)
      end

      it 'must have numeric_key or composite_key present', :aggregate_failures do
        expect(validation_errors).to be_present
        expect(validation_errors(numeric_key: 1)).to be_blank
        expect(validation_errors(composite_key: { id: 1 })).to be_blank
        expect(validation_errors(numeric_key: 1, composite_key: { id: 1 })).to be_present
      end
    end
  end

  it 'is destroyed when source user is destroyed' do
    reference = create(:import_source_user_placeholder_reference)

    expect { reference.source_user.destroy! }.to change { described_class.count }.by(-1)
  end

  describe 'SERIALIZABLE_ATTRIBUTES' do
    subject(:constant) { described_class::SERIALIZABLE_ATTRIBUTES }

    it 'is the expected list of attribute names' do
      expected_elements = %w[
        composite_key
        model
        namespace_id
        numeric_key
        source_user_id
        user_reference_column
      ]

      failure_message = <<-MSG
        Before fixing this spec, ensure that `#{described_class.name}.from_serialized`
        handles receiving older versions of the array by filling in missing values with defaults.

        You are seeing this message because SERIALIZABLE_ATTRIBUTES has changed.
      MSG

      expect(constant).to eq(expected_elements), failure_message
    end
  end

  describe '#to_serialized' do
    let(:reference) do
      build(:import_source_user_placeholder_reference,
        numeric_key: 1,
        namespace_id: 2,
        source_user_id: 3,
        user_reference_column: 'foo',
        model: 'Model',
        composite_key: { key: 1 }
      )
    end

    subject(:serialized) { reference.to_serialized }

    it { is_expected.to eq('[{"key":1},"Model",2,1,3,"foo"]') }
  end

  describe '.from_serialized' do
    subject(:from_serialized) { described_class.from_serialized(serialized) }

    context 'when serialized reference is valid' do
      let(:serialized) { '[{"key":1},"Model",2,null,3,"foo"]' }

      it 'returns a valid SourceUserPlaceholderReference' do
        expect(from_serialized).to be_a(described_class)
          .and(be_valid)
          .and(have_attributes(
            composite_key: { key: 1 },
            model: 'Model',
            numeric_key: nil,
            namespace_id: 2,
            source_user_id: 3,
            user_reference_column: 'foo'
          ))
      end

      it 'sets the created_at' do
        expect(from_serialized.created_at).to be_like_time(Time.zone.now)
      end
    end

    context 'when serialized reference has different number of elements than expected' do
      let(:serialized) { '[{"key":1},"Model",2,null,3]' }

      it 'raises an exception' do
        expect { from_serialized }.to raise_error(described_class::SerializationError)
      end
    end
  end
end
