# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::AsyncIndexes::PostgresAsyncIndex, type: :model do
  it { is_expected.to be_a Gitlab::Database::SharedModel }

  describe 'validations' do
    let(:identifier_limit) { described_class::MAX_IDENTIFIER_LENGTH }
    let(:definition_limit) { described_class::MAX_DEFINITION_LENGTH }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_length_of(:name).is_at_most(identifier_limit) }
    it { is_expected.to validate_presence_of(:table_name) }
    it { is_expected.to validate_length_of(:table_name).is_at_most(identifier_limit) }
    it { is_expected.to validate_presence_of(:definition) }
    it { is_expected.to validate_length_of(:definition).is_at_most(definition_limit) }
  end

  describe 'scopes' do
    let!(:async_index_creation) { create(:postgres_async_index) }
    let!(:async_index_destruction) { create(:postgres_async_index, :with_drop) }

    describe '.to_create' do
      subject { described_class.to_create }

      it { is_expected.to contain_exactly(async_index_creation) }
    end

    describe '.to_drop' do
      subject { described_class.to_drop }

      it { is_expected.to contain_exactly(async_index_destruction) }
    end
  end
end
