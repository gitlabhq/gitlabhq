# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::LooseForeignKeys::RecordStoreSelector, feature_category: :database do
  let(:worker_class) do
    Class.new do
      include Gitlab::LooseForeignKeys::RecordStoreSelector

      public :record_store, :flipper_id
    end
  end

  let(:worker) { worker_class.new }

  before do
    stub_const('TestRecordStoreWorker', worker_class)
  end

  describe '#flipper_id' do
    it 'returns the worker class name' do
      expect(worker.flipper_id).to eq('TestRecordStoreWorker')
    end
  end

  describe '#record_store' do
    context 'when the flag is disabled' do
      before do
        stub_feature_flags(use_loose_foreign_keys_deleted_record_store: false)
      end

      it 'returns LooseForeignKeys::DeletedRecord' do
        expect(worker.record_store).to eq(LooseForeignKeys::DeletedRecord)
      end
    end

    context 'when the flag is enabled globally' do
      before do
        stub_feature_flags(use_loose_foreign_keys_deleted_record_store: true)
      end

      it 'returns Gitlab::LooseForeignKeys::DeletedRecordStore' do
        expect(worker.record_store).to eq(Gitlab::LooseForeignKeys::DeletedRecordStore)
      end
    end
  end

  describe 'per-worker rollout' do
    using RSpec::Parameterized::TableSyntax

    rollout_worker_classes = [
      LooseForeignKeys::CleanupWorker,
      LooseForeignKeys::CiPipelinesBuildsCleanupCronWorker,
      LooseForeignKeys::MergeRequestDiffCommitCleanupWorker
    ]

    where(:described_worker_class) { rollout_worker_classes }

    with_them do
      let(:enabled_worker) { described_worker_class.new }

      before do
        stub_feature_flags(use_loose_foreign_keys_deleted_record_store: enabled_worker)
      end

      it 'enables the facade for the enabled worker' do
        expect(enabled_worker.send(:record_store)).to eq(Gitlab::LooseForeignKeys::DeletedRecordStore)
      end

      it 'keep the facade disabled for the remaining workers', :aggregate_failures do
        rollout_worker_classes.excluding(enabled_worker.class).each do |remaining_worker|
          expect(remaining_worker.new.send(:record_store)).to eq(LooseForeignKeys::DeletedRecord)
        end
      end
    end
  end
end
