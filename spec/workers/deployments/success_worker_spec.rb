require 'spec_helper'

describe Deployments::SuccessWorker do
  subject { described_class.new.perform(deployment&.id) }

  context 'when deployment starts environment' do
    context 'when deployment was successful' do
      let(:deployment) { create(:deployment, :start, :success) }

      it 'executes StartEnvironmentService' do
        expect(StartEnvironmentService)
          .to receive(:new).with(deployment).and_call_original

        subject
      end
    end

    context 'when deployment failed' do
      let(:deployment) { create(:deployment, :start, :failed) }

      it 'does not execute StartEnvironmentService' do
        expect(StartEnvironmentService)
          .not_to receive(:new).with(deployment).and_call_original

        subject
      end
    end
  end

  context 'when deployment stops environment' do
    context 'when deployment was successful' do
      let(:deployment) { create(:deployment, :stop, :success) }

      it 'executes StopEnvironmentService' do
        expect(StopEnvironmentService)
          .to receive(:new).with(deployment).and_call_original

        subject
      end
    end

    context 'when deployment failed' do
      let(:deployment) { create(:deployment, :stop, :failed) }

      it 'does not execute StopEnvironmentService' do
        expect(StopEnvironmentService)
          .not_to receive(:new).with(deployment).and_call_original

        subject
      end
    end
  end
end
