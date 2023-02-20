# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::AsyncIndexes::PostgresAsyncIndex, type: :model, feature_category: :database do
  it { is_expected.to be_a Gitlab::Database::SharedModel }

  describe 'validations' do
    let(:identifier_limit) { described_class::MAX_IDENTIFIER_LENGTH }
    let(:definition_limit) { described_class::MAX_DEFINITION_LENGTH }
    let(:last_error_limit) { described_class::MAX_LAST_ERROR_LENGTH }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_length_of(:name).is_at_most(identifier_limit) }
    it { is_expected.to validate_presence_of(:table_name) }
    it { is_expected.to validate_length_of(:table_name).is_at_most(identifier_limit) }
    it { is_expected.to validate_presence_of(:definition) }
    it { is_expected.to validate_length_of(:definition).is_at_most(definition_limit) }
    it { is_expected.to validate_length_of(:last_error).is_at_most(last_error_limit) }
  end

  describe 'scopes' do
    let_it_be(:async_index_creation) { create(:postgres_async_index) }
    let_it_be(:async_index_destruction) { create(:postgres_async_index, :with_drop) }

    describe '.to_create' do
      subject { described_class.to_create }

      it { is_expected.to contain_exactly(async_index_creation) }
    end

    describe '.to_drop' do
      subject { described_class.to_drop }

      it { is_expected.to contain_exactly(async_index_destruction) }
    end

    describe '.ordered' do
      before do
        async_index_creation.update!(attempts: 3)
      end

      subject { described_class.ordered.limit(1) }

      it { is_expected.to contain_exactly(async_index_destruction) }
    end
  end

  describe '#handle_exception!' do
    let_it_be_with_reload(:async_index_creation) { create(:postgres_async_index) }

    let(:error) { instance_double(StandardError, message: 'Oups', backtrace: %w[this that]) }

    subject { async_index_creation.handle_exception!(error) }

    it 'increases the attempts number' do
      expect { subject }.to change { async_index_creation.reload.attempts }.by(1)
    end

    it 'saves error details' do
      subject

      expect(async_index_creation.reload.last_error).to eq("Oups\nthis\nthat")
    end
  end
end
