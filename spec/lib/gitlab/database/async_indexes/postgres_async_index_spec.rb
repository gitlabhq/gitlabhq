# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::AsyncIndexes::PostgresAsyncIndex, type: :model, feature_category: :database do
  it { is_expected.to be_a Gitlab::Database::SharedModel }

  describe 'validations' do
    subject(:model) { build(:postgres_async_index) }

    let(:table_name_limit) { described_class::MAX_TABLE_NAME_LENGTH }
    let(:identifier_limit) { described_class::MAX_IDENTIFIER_LENGTH }
    let(:definition_limit) { described_class::MAX_DEFINITION_LENGTH }
    let(:last_error_limit) { described_class::MAX_LAST_ERROR_LENGTH }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_length_of(:name).is_at_most(identifier_limit) }
    it { is_expected.to validate_presence_of(:table_name) }
    it { is_expected.to validate_length_of(:table_name).is_at_most(table_name_limit) }
    it { is_expected.to validate_presence_of(:definition) }
    it { is_expected.to validate_length_of(:definition).is_at_most(definition_limit) }
    it { is_expected.to validate_length_of(:last_error).is_at_most(last_error_limit) }

    shared_examples 'table_name is invalid' do
      before do
        model.table_name = table_name
      end

      it 'is invalid' do
        expect(model).to be_invalid
        expect(model.errors).to have_key(:table_name)
      end
    end

    context 'when passing a long schema name' do
      let(:table_name) { "#{'schema_name' * 10}.table_name" }

      it_behaves_like 'table_name is invalid'
    end

    context 'when passing a long table name' do
      let(:table_name) { "schema_name.#{'table_name' * 10}" }

      it_behaves_like 'table_name is invalid'
    end

    context 'when passing a long table name and schema name' do
      let(:table_name) { "#{'schema_name' * 10}.#{'table_name' * 10}" }

      it_behaves_like 'table_name is invalid'
    end

    context 'when invalid table name is given' do
      let(:table_name) { 'a.b.c' }

      it_behaves_like 'table_name is invalid'
    end

    context 'when passing a definition with beginning or trailing whitespace' do
      let(:model) { super().tap { |m| m.definition = definition } }
      let(:definition) do
        <<-SQL
          CREATE UNIQUE INDEX CONCURRENTLY foo_index ON bar_field (uuid);
        SQL
      end

      it "strips the definition field" do
        expect(model).to be_valid
        model.save!
        expect(model.definition).to eq(definition.strip)
      end
    end
  end

  describe 'scopes' do
    let_it_be(:async_index_creation) { create(:postgres_async_index, attempts: 0) }
    let_it_be(:async_index_destruction) { create(:postgres_async_index, :with_drop, attempts: 0) }

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
