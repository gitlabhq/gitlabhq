# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::AsyncConstraints::PostgresAsyncConstraintValidation, type: :model,
  feature_category: :database do
  it { is_expected.to be_a Gitlab::Database::SharedModel }

  describe 'validations' do
    let_it_be(:constraint_validation) { create(:postgres_async_constraint_validation) }
    let(:identifier_limit) { described_class::MAX_IDENTIFIER_LENGTH }
    let(:last_error_limit) { described_class::MAX_LAST_ERROR_LENGTH }

    subject { constraint_validation }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name).scoped_to(:table_name) }
    it { is_expected.to validate_length_of(:name).is_at_most(identifier_limit) }
    it { is_expected.to validate_presence_of(:table_name) }
    it { is_expected.to validate_length_of(:table_name).is_at_most(identifier_limit) }
    it { is_expected.to validate_length_of(:last_error).is_at_most(last_error_limit) }
  end

  describe 'scopes' do
    let!(:failed_validation) { create(:postgres_async_constraint_validation, attempts: 1) }
    let!(:new_validation) { create(:postgres_async_constraint_validation) }

    describe '.ordered' do
      subject { described_class.ordered }

      it { is_expected.to eq([new_validation, failed_validation]) }
    end

    describe '.foreign_key_type' do
      before do
        new_validation.update_column(:constraint_type, 99)
      end

      subject { described_class.foreign_key_type }

      it { is_expected.to eq([failed_validation]) }

      it 'does not apply the filter if the column is not present' do
        expect(described_class)
          .to receive(:constraint_type_exists?)
          .and_return(false)

        is_expected.to match_array([failed_validation, new_validation])
      end
    end

    describe '.check_constraint_type' do
      before do
        new_validation.update!(constraint_type: :check_constraint)
      end

      subject { described_class.check_constraint_type }

      it { is_expected.to eq([new_validation]) }
    end
  end

  describe '.table_available?' do
    subject { described_class.table_available? }

    it { is_expected.to be_truthy }

    context 'when the table does not exist' do
      before do
        described_class
          .connection
          .drop_table(described_class.table_name)
      end

      it { is_expected.to be_falsy }
    end
  end

  describe '.constraint_type_exists?' do
    it { expect(described_class.constraint_type_exists?).to be_truthy }

    it 'always asks the database' do
      control1 = ActiveRecord::QueryRecorder.new(skip_schema_queries: false) do
        described_class.constraint_type_exists?
      end

      control2 = ActiveRecord::QueryRecorder.new(skip_schema_queries: false) do
        described_class.constraint_type_exists?
      end

      expect(control1.count).to eq(1)
      expect(control2.count).to eq(1)
    end
  end

  describe '#handle_exception!' do
    let_it_be_with_reload(:constraint_validation) { create(:postgres_async_constraint_validation) }

    let(:error) { instance_double(StandardError, message: 'Oups', backtrace: %w[this that]) }

    subject { constraint_validation.handle_exception!(error) }

    it 'increases the attempts number' do
      expect { subject }.to change { constraint_validation.reload.attempts }.by(1)
    end

    it 'saves error details' do
      subject

      expect(constraint_validation.reload.last_error).to eq("Oups\nthis\nthat")
    end
  end
end
