# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Npm::CleanupStaleMetadataCacheWorker, type: :worker, feature_category: :package_registry do
  let(:worker) { described_class.new }

  describe '#perform_work' do
    subject { worker.perform_work }

    context 'with no work to do' do
      it { is_expected.to be_nil }
    end

    context 'with work to do' do
      let_it_be(:npm_metadata_cache1) { create(:npm_metadata_cache) }
      let_it_be(:npm_metadata_cache2) { create(:npm_metadata_cache, :stale) }

      let_it_be(:npm_metadata_cache3) do
        create(:npm_metadata_cache, :stale, updated_at: 1.year.ago, created_at: 1.year.ago)
      end

      it 'deletes the oldest stale metadata cache based on id', :aggregate_failures do
        expect(worker).to receive(:log_extra_metadata_on_done).with(:npm_metadata_cache_id, npm_metadata_cache2.id)

        expect { subject }.to change { Packages::Npm::MetadataCache.count }.by(-1)
        expect { npm_metadata_cache2.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'with a stale metadata cache' do
      let_it_be(:npm_metadata_cache) { create(:npm_metadata_cache, :stale) }

      context 'with an error during the destroy' do
        before do
          allow_next_found_instance_of(Packages::Npm::MetadataCache) do |metadata_cache|
            allow(metadata_cache).to receive(:destroy!).and_raise('Error!')
          end
        end

        it 'handles the error' do
          expect(Gitlab::ErrorTracking).to receive(:log_exception)
            .with(instance_of(RuntimeError), class: described_class.name)
          expect { subject }.to change { Packages::Npm::MetadataCache.error.count }.from(0).to(1)
          expect(npm_metadata_cache.reload).to be_error
        end
      end

      context 'when trying to destroy a destroyed record' do
        before do
          allow_next_found_instance_of(Packages::Npm::MetadataCache) do |metadata_cache|
            destroy_method = metadata_cache.method(:destroy!)

            allow(metadata_cache).to receive(:destroy!) do
              destroy_method.call

              raise 'Error!'
            end
          end
        end

        it 'handles the error' do
          expect(Gitlab::ErrorTracking).to receive(:log_exception)
            .with(instance_of(RuntimeError), class: described_class.name)
          expect { subject }.not_to change { Packages::Npm::MetadataCache.count }
          expect(npm_metadata_cache.reload).to be_error
        end
      end
    end
  end

  describe '#max_running_jobs' do
    let(:capacity) { described_class::MAX_CAPACITY }

    subject { worker.max_running_jobs }

    it { is_expected.to eq(capacity) }
  end
end
