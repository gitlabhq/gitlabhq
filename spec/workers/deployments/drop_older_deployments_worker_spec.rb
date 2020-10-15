# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Deployments::DropOlderDeploymentsWorker do
  subject { described_class.new.perform(deployment&.id) }

  describe '#perform' do
    let(:deployment) { create(:deployment, :success) }

    it 'executes Deployments::OlderDeploymentsDropService' do
      expect(Deployments::OlderDeploymentsDropService)
          .to receive(:new).with(deployment.id).and_call_original

      subject
    end
  end
end
