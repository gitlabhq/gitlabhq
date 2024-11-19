# frozen_string_literal: true

require 'spec_helper'

RSpec.describe VirtualRegistries::Packages::DestroyOrphanCachedResponsesWorker, type: :worker, feature_category: :virtual_registry do
  let(:worker) { described_class.new }
  let(:model) { ::VirtualRegistries::Packages::Maven::CachedResponse }

  it_behaves_like 'an idempotent worker' do
    let(:job_args) { [model.name] }
  end

  it_behaves_like 'worker with data consistency', described_class, data_consistency: :sticky

  it 'has a none deduplicate strategy' do
    expect(described_class.get_deduplicate_strategy).to eq(:none)
  end

  describe '#perform_work' do
    subject(:perform_work) { worker.perform_work(model.name) }

    context 'with no work to do' do
      it { is_expected.to be_nil }
    end

    context 'with work to do' do
      let_it_be(:cached_response) { create(:virtual_registries_packages_maven_cached_response) }
      let_it_be(:orphan_cached_response) do
        create(:virtual_registries_packages_maven_cached_response, :pending_destruction)
      end

      it 'destroys orphan cached responses' do
        expect(worker).to receive(:log_extra_metadata_on_done).with(:cached_response_id, orphan_cached_response.id)
        expect(worker).to receive(:log_extra_metadata_on_done).with(:group_id, orphan_cached_response.group_id)
        expect(worker).to receive(:log_extra_metadata_on_done).with(:relative_path,
          orphan_cached_response.relative_path)
        expect(model).to receive(:next_pending_destruction).and_call_original
        expect { perform_work }.to change { model.count }.by(-1)
        expect { orphan_cached_response.reset }.to raise_error(ActiveRecord::RecordNotFound)
      end

      context 'with an error during deletion' do
        before do
          allow_next_found_instance_of(model) do |instance|
            allow(instance).to receive(:destroy).and_raise(StandardError)
          end
        end

        it 'tracks the error' do
          expect(Gitlab::ErrorTracking).to receive(:log_exception).with(
            instance_of(StandardError), class: described_class.name
          )

          expect { perform_work }.to change { model.error.count }.by(1)
        end
      end

      context 'when trying to update a destroyed record' do
        before do
          allow_next_found_instance_of(model) do |instance|
            destroy_method = instance.method(:destroy!)

            allow(instance).to receive(:destroy!) do
              destroy_method.call

              raise StandardError
            end
          end
        end

        it 'does not change the status to error' do
          expect(Gitlab::ErrorTracking).to receive(:log_exception)
            .with(instance_of(StandardError), class: described_class.name)
          expect { perform_work }.not_to change { model.error.count }
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
