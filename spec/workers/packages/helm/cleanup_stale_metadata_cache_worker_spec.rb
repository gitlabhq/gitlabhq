# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Helm::CleanupStaleMetadataCacheWorker, feature_category: :package_registry do
  let(:worker) { described_class.new }

  it_behaves_like 'an idempotent worker'
  it_behaves_like 'worker with data consistency', described_class, data_consistency: :sticky

  it 'has a none deduplicate strategy' do
    expect(described_class.get_deduplicate_strategy).to eq(:none)
  end

  describe '#perform_work' do
    subject(:perform) { worker.perform_work }

    context 'with no work to do' do
      it { is_expected.to be_nil }
    end

    context 'with work to do' do
      let_it_be(:helm_metadata_cache1) { create(:helm_metadata_cache) }
      let_it_be(:helm_metadata_cache2) { create(:helm_metadata_cache, :pending_destruction) }

      let_it_be(:helm_metadata_cache3) do
        create(:helm_metadata_cache, :pending_destruction, updated_at: 1.year.ago, created_at: 1.year.ago)
      end

      it 'deletes the oldest pending destruction metadata cache based on updated_at', :aggregate_failures do
        expect(worker).to receive(:log_extra_metadata_on_done).with(:helm_metadata_cache_id, helm_metadata_cache3.id)

        expect { perform }.to change { Packages::Helm::MetadataCache.count }.by(-1)
        expect { helm_metadata_cache3.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'with a pending destruction metadata cache' do
      let_it_be(:helm_metadata_cache) { create(:helm_metadata_cache, :pending_destruction) }

      context 'with an error during the destroy' do
        before do
          allow_next_found_instance_of(Packages::Helm::MetadataCache) do |metadata_cache|
            allow(metadata_cache).to receive(:destroy!).and_raise('Error!')
          end
        end

        it 'handles the error', :aggregate_failures do
          expect(Gitlab::ErrorTracking).to receive(:log_exception)
            .with(instance_of(RuntimeError), class: described_class.name)
          expect { perform }.to change { Packages::Helm::MetadataCache.error.count }.from(0).to(1)
          expect(helm_metadata_cache.reload).to be_error
        end
      end

      context 'when trying to destroy a destroyed record' do
        before do
          allow_next_found_instance_of(Packages::Helm::MetadataCache) do |metadata_cache|
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
          expect { perform }.not_to change { Packages::Helm::MetadataCache.count }
          expect(helm_metadata_cache.reload).to be_error
        end
      end
    end
  end

  describe '#max_running_jobs' do
    let(:capacity) { described_class::MAX_CAPACITY }

    subject(:max_running_jobs) { worker.max_running_jobs }

    it { is_expected.to eq(capacity) }
  end
end
