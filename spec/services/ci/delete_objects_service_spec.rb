# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::DeleteObjectsService, :aggregate_failures, feature_category: :continuous_integration do
  let(:service) { described_class.new }
  let(:data) { [artifact] }

  describe '#execute' do
    shared_examples_for 'deleting objects' do |store_type|
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
        if store_type == :object_storage
          expect { execute }
            .to change { fog_connection.directories.get(bucket).files.any? }
        else
          expect { execute }.to change { artifact.file.exists? }
        end
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

        let_it_be(:past_ready) { create(:ci_deleted_object, pick_up_at: 2.days.ago) }
        let_it_be(:ready) { create(:ci_deleted_object, pick_up_at: 1.day.ago) }

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

    context 'when local storage is used' do
      let(:artifact) { create(:ci_job_artifact, :archive) }

      it_behaves_like 'deleting objects', :local_storage
    end

    context 'when object storage is used' do
      shared_examples_for 'deleting objects from object storage' do
        let!(:fog_file) do
          fog_connection.directories.new(key: bucket).files.create( # rubocop:disable Rails/SaveBang
            key: fog_file_path,
            body: 'content'
          )
        end

        let(:artifact) do
          create(
            :ci_job_artifact,
            :remote_store
          ).tap do |a|
            a.update_column(:file, 'artifacts.zip')
            a.reload
          end
        end

        context 'and object was direct uploaded to its final location' do
          let(:upload_path) { 'some/path/to/randomfile' }

          before do
            artifact.update_column(:file_final_path, upload_path)
            artifact.reload
          end

          it_behaves_like 'deleting objects', :object_storage
        end

        context 'and object was not direct uploaded to its final location' do
          let(:upload_path) do
            File.join(
              artifact.file.store_dir.to_s,
              artifact.file_identifier
            )
          end

          it_behaves_like 'deleting objects', :object_storage
        end
      end

      context 'and bucket prefix is not configured' do
        let(:fog_connection) do
          stub_artifacts_object_storage
        end

        let(:bucket) { 'artifacts' }
        let(:fog_file_path) { upload_path }

        it_behaves_like 'deleting objects from object storage'
      end

      context 'and bucket prefix is configured' do
        let(:fog_config) do
          Gitlab.config.artifacts.object_store.tap do |config|
            config[:remote_directory] = bucket
            config[:bucket_prefix] = bucket_prefix
          end
        end

        let(:fog_connection) do
          stub_object_storage_uploader(
            config: fog_config,
            uploader: JobArtifactUploader
          )
        end

        let(:bucket_prefix) { 'my/artifacts' }
        let(:bucket) { 'main-bucket' }
        let(:fog_file_path) { File.join(bucket_prefix, upload_path) }

        it_behaves_like 'deleting objects from object storage'
      end
    end
  end

  describe '#remaining_batches_count' do
    let(:artifact) do
      create(
        :ci_job_artifact,
        :archive
      )
    end

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
