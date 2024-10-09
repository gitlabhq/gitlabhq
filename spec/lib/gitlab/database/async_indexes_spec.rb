# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::AsyncIndexes, feature_category: :database do
  describe '.create_pending_indexes!' do
    subject(:create_pending_indexes) { described_class.create_pending_indexes! }

    before do
      create_list(:postgres_async_index, 4)
    end

    it 'takes 2 pending indexes and creates those' do
      indexes = described_class::PostgresAsyncIndex.to_create.order(:id).limit(2).to_a

      expect_next_instances_of(described_class::IndexCreator, 2, indexes) do |creator|
        expect(creator).to receive(:perform)
      end

      create_pending_indexes
    end

    context 'when there are indexes to be created in the queue with higher attempts' do
      before do
        described_class::PostgresAsyncIndex.first(2).each do |async_index|
          async_index.update!(attempts: 1)
        end
      end

      it 'does not pick up failed indexes' do
        expect { create_pending_indexes }
          .to change { described_class::PostgresAsyncIndex.count }.by(-2)
          .and not_change { described_class::PostgresAsyncIndex.where('attempts > ?', 0).count }
      end
    end
  end

  describe '.drop_pending_indexes!' do
    subject(:drop_pending_indexes) { described_class.drop_pending_indexes! }

    before do
      create_list(:postgres_async_index, 4, :with_drop)
    end

    it 'takes 2 pending indexes and destroys those' do
      indexes = described_class::PostgresAsyncIndex.to_drop.order(:id).limit(2).to_a

      expect_next_instances_of(described_class::IndexDestructor, 2, indexes) do |destructor|
        expect(destructor).to receive(:perform)
      end

      drop_pending_indexes
    end

    context 'when there are indexes to be destroyed in the queue with higher attempts' do
      before do
        described_class::PostgresAsyncIndex.first(2).each do |async_index|
          async_index.update!(attempts: 1)
        end
      end

      it 'does not pick up failed indexes' do
        expect { drop_pending_indexes }
          .to change { described_class::PostgresAsyncIndex.count }.by(-2)
          .and not_change { described_class::PostgresAsyncIndex.where('attempts > ?', 0).count }
      end
    end
  end

  describe '.execute_pending_actions!' do
    subject { described_class.execute_pending_actions!(how_many: how_many) }

    let_it_be(:failed_creation_entry) { create(:postgres_async_index, attempts: 5) }
    let_it_be(:failed_removal_entry) { create(:postgres_async_index, :with_drop, attempts: 1) }
    let_it_be(:creation_entry) { create(:postgres_async_index) }
    let_it_be(:removal_entry) { create(:postgres_async_index, :with_drop) }

    context 'with one entry' do
      let(:how_many) { 1 }

      it 'executes instructions ordered by attempts and ids' do
        expect { subject }
          .to change { queued_entries_exist?(creation_entry) }.to(false)
          .and change { described_class::PostgresAsyncIndex.count }.by(-how_many)
      end
    end

    context 'with two entries' do
      let(:how_many) { 2 }

      it 'executes instructions ordered by attempts' do
        expect { subject }
          .to change { queued_entries_exist?(creation_entry, removal_entry) }.to(false)
          .and change { described_class::PostgresAsyncIndex.count }.by(-how_many)
      end
    end

    context 'when the budget allows more instructions' do
      let(:how_many) { 3 }

      it 'retries failed attempts' do
        expect { subject }
          .to change { queued_entries_exist?(creation_entry, removal_entry, failed_removal_entry) }.to(false)
          .and change { described_class::PostgresAsyncIndex.count }.by(-how_many)
      end
    end

    def queued_entries_exist?(*records)
      described_class::PostgresAsyncIndex.where(id: records).exists?
    end
  end
end
