# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::AsyncForeignKeys::PostgresAsyncForeignKeyValidation, type: :model,
  feature_category: :database do
  it { is_expected.to be_a Gitlab::Database::SharedModel }

  describe 'validations' do
    let_it_be(:fk_validation) { create(:postgres_async_foreign_key_validation) }
    let(:identifier_limit) { described_class::MAX_IDENTIFIER_LENGTH }
    let(:last_error_limit) { described_class::MAX_LAST_ERROR_LENGTH }

    subject { fk_validation }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name) }
    it { is_expected.to validate_length_of(:name).is_at_most(identifier_limit) }
    it { is_expected.to validate_presence_of(:table_name) }
    it { is_expected.to validate_length_of(:table_name).is_at_most(identifier_limit) }
    it { is_expected.to validate_length_of(:last_error).is_at_most(last_error_limit) }
  end

  describe 'scopes' do
    let!(:failed_validation) { create(:postgres_async_foreign_key_validation, attempts: 1) }
    let!(:new_validation) { create(:postgres_async_foreign_key_validation) }

    describe '.ordered' do
      subject { described_class.ordered }

      it { is_expected.to eq([new_validation, failed_validation]) }
    end
  end
end
