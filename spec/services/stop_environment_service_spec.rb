require 'spec_helper'

describe StopEnvironmentService do
  let(:service) { described_class.new(deployment) }

  describe '#execute' do
    subject { service.execute }

    context 'when environment is available' do
      let(:environment) { create(:environment, state: :available) }

      context 'when deployment was successful' do
        let(:deployment) { create(:deployment, :success, :stop, environment: environment) }

        it 'stops the environment' do
          subject

          expect(environment.reload).to be_stopped
        end
      end

      context 'when deployment failed' do
        let(:deployment) { create(:deployment, :failed, :stop, environment: environment) }

        it 'does not stop the environment' do
          subject

          expect(environment.reload).to be_available
        end
      end
    end

    context 'when environment is stopped' do
      let(:deployment) { create(:deployment, :success, :stop, environment: environment) }
      let(:environment) { create(:environment, state: :stopped) }

      it 'does not raise an error' do
        expect { subject }.not_to raise_error
        expect(environment.reload).to be_stopped
      end
    end
  end
end
