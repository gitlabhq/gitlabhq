# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Nuget::CleanupStaleSymbolsWorker, type: :worker, feature_category: :package_registry do
  let(:worker) { described_class.new }

  it_behaves_like 'an idempotent worker'
  it_behaves_like 'worker with data consistency', described_class, data_consistency: :sticky

  it 'has a none deduplicate strategy' do
    expect(described_class.get_deduplicate_strategy).to eq(:none)
  end

  describe '#perform_work' do
    subject(:perform_work) { worker.perform_work }

    context 'with no work to do' do
      it { is_expected.to be_nil }
    end

    context 'with work to do' do
      let_it_be(:symbol_1) { create(:nuget_symbol) }
      let_it_be(:symbol_2) { create(:nuget_symbol, :orphan) }

      it 'deletes the orphan symbol', :aggregate_failures do
        expect(worker).to receive(:log_extra_metadata_on_done).with(:nuget_symbol_id, symbol_2.id)
        expect(Packages::Nuget::Symbol).to receive(:next_pending_destruction).with(order_by: nil).and_call_original
        expect { perform_work }.to change { Packages::Nuget::Symbol.count }.by(-1)
        expect { symbol_2.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'with an orphan symbol' do
      let_it_be(:symbol) { create(:nuget_symbol, :orphan) }

      context 'with an error during deletion' do
        before do
          allow_next_found_instance_of(Packages::Nuget::Symbol) do |instance|
            allow(instance).to receive(:destroy!).and_raise(StandardError)
          end
        end

        it 'handles the error' do
          expect(Gitlab::ErrorTracking).to receive(:log_exception).with(
            instance_of(StandardError), class: described_class.name
          )

          expect { perform_work }.to change { Packages::Nuget::Symbol.error.count }.by(1)
          expect(symbol.reload).to be_error
        end
      end

      context 'when trying to destroy a destroyed record' do
        before do
          allow_next_found_instance_of(Packages::Nuget::Symbol) do |instance|
            destroy_method = instance.method(:destroy!)

            allow(instance).to receive(:destroy!) do
              destroy_method.call

              raise StandardError
            end
          end
        end

        it 'handles the error' do
          expect(Gitlab::ErrorTracking).to receive(:log_exception)
            .with(instance_of(StandardError), class: described_class.name)
          expect { perform_work }.not_to change { Packages::Nuget::Symbol.count }
          expect(symbol.reload).to be_error
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
