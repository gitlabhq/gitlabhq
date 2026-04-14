# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Cells::ScheduleClaimsVerificationWorker, feature_category: :cell do
  let(:worker) { described_class.new }

  before do
    stub_config_cell(enabled: true)
  end

  it { is_expected.to be_a(CronjobQueue) }

  it_behaves_like 'an idempotent worker'

  describe '#perform' do
    context 'when cell is not enabled' do
      before do
        stub_config_cell(enabled: false)
      end

      it 'does not enqueue any workers' do
        expect(Cells::ClaimsVerificationWorker).not_to receive(:perform_in)

        worker.perform
      end
    end

    context 'when there are models with claims' do
      before do
        allow(Cells::Claimable).to receive(:models_with_claims).and_return([User, Namespace])
      end

      it 'enqueues a ClaimsVerificationWorker for each model with staggered delays' do
        expect(Cells::ClaimsVerificationWorker).to receive(:perform_in).with(0.minutes, 'User')
        expect(Cells::ClaimsVerificationWorker).to receive(:perform_in).with(10.minutes, 'Namespace')

        worker.perform
      end

      it 'logs the scheduled models' do
        allow(Cells::ClaimsVerificationWorker).to receive(:perform_in)

        expect(worker).to receive(:log_hash_metadata_on_done).with(
          message: "Scheduled [\"User\", \"Namespace\"] for claims verification"
        )

        worker.perform
      end
    end

    context 'when there are no models with claims' do
      before do
        allow(Cells::Claimable).to receive(:models_with_claims).and_return([])
      end

      it 'does not enqueue any workers' do
        expect(Cells::ClaimsVerificationWorker).not_to receive(:perform_in)

        worker.perform
      end
    end
  end
end
