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
end
