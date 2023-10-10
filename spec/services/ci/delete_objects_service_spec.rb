# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::DeleteObjectsService, :aggregate_failures, feature_category: :continuous_integration do
  let(:service) { described_class.new }
  let(:artifact) { create(:ci_job_artifact, :archive) }
  let(:data) { [artifact] }

  describe '#execute' do
    before do
      Ci::DeletedObject.bulk_import(data)
      # We disable the check because the specs are wrapped in a transaction
      allow(service).to receive(:transaction_open?).and_return(false)
    end

    subject(:execute) { service.execute }

    it 'deletes records' do
      expect { execute }.to change { Ci::DeletedObject.count }.by(-1)
    end

    it 'deletes files' do
      expect { execute }.to change { artifact.file.exists? }
    end

    context 'when trying to execute without records' do
      let(:data) { [] }

      it 'does not change the number of objects' do
        expect { execute }.not_to change { Ci::DeletedObject.count }
      end
    end

    context 'when trying to remove the same file multiple times' do
      let(:objects) { Ci::DeletedObject.all.to_a }

      before do
        expect(service).to receive(:load_next_batch).twice.and_return(objects)
      end

      it 'executes successfully' do
        2.times { expect(service.execute).to be_truthy }
      end
    end

    context 'with artifacts both ready and not ready for deletion' do
      let(:data) { [] }

      let!(:past_ready) { create(:ci_deleted_object, pick_up_at: 2.days.ago) }
      let!(:ready) { create(:ci_deleted_object, pick_up_at: 1.day.ago) }

      it 'skips records with pick_up_at in the future' do
        not_ready = create(:ci_deleted_object, pick_up_at: 1.day.from_now)

        expect { execute }.to change { Ci::DeletedObject.count }.from(3).to(1)
        expect(not_ready.reload.present?).to be_truthy
      end

      it 'limits the number of records removed' do
        stub_const("#{described_class}::BATCH_SIZE", 1)

        expect { execute }.to change { Ci::DeletedObject.count }.by(-1)
      end

      it 'removes records in order' do
        stub_const("#{described_class}::BATCH_SIZE", 1)

        execute

        expect { past_ready.reload }.to raise_error(ActiveRecord::RecordNotFound)
        expect(ready.reload.present?).to be_truthy
      end

      it 'updates pick_up_at timestamp' do
        allow(service).to receive(:destroy_everything)

        execute

        expect(past_ready.reload.pick_up_at).to be_like_time(10.minutes.from_now)
      end

      it 'does not delete objects for which file deletion has failed' do
        expect(past_ready)
          .to receive(:delete_file_from_storage)
          .and_return(false)

        expect(service)
          .to receive(:load_next_batch)
          .and_return([past_ready, ready])

        expect { execute }.to change { Ci::DeletedObject.count }.from(2).to(1)
        expect(past_ready.reload.present?).to be_truthy
      end
    end

    context 'with an open database transaction' do
      it 'raises an exception and does not remove records' do
        expect(service).to receive(:transaction_open?).and_return(true)

        expect { execute }
          .to raise_error(Ci::DeleteObjectsService::TransactionInProgressError)
          .and change { Ci::DeletedObject.count }.by(0)
      end
    end
  end

  describe '#remaining_batches_count' do
    subject { service.remaining_batches_count(max_batch_count: 3) }

    context 'when there is less than one batch size' do
      before do
        Ci::DeletedObject.bulk_import(data)
      end

      it { is_expected.to eq(1) }
    end

    context 'when there is more than one batch size' do
      before do
        objects_scope = double

        expect(Ci::DeletedObject)
          .to receive(:ready_for_destruction)
          .and_return(objects_scope)

        expect(objects_scope).to receive(:size).and_return(110)
      end

      it { is_expected.to eq(2) }
    end
  end
end
