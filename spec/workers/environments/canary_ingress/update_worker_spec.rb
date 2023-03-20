# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Environments::CanaryIngress::UpdateWorker, feature_category: :continuous_delivery do
  let_it_be(:environment) { create(:environment) }

  let(:worker) { described_class.new }

  describe '#perform' do
    subject { worker.perform(environment_id, params) }

    let(:environment_id) { environment.id }
    let(:params) { { 'weight' => 50 } }

    it 'executes the update service' do
      expect_next_instance_of(Environments::CanaryIngress::UpdateService, environment.project, nil, params) do |service|
        expect(service).to receive(:execute).with(environment)
      end

      subject
    end

    context 'when an environment does not exist' do
      let(:environment_id) { non_existing_record_id }

      it 'does not execute the update service' do
        expect(Environments::CanaryIngress::UpdateService).not_to receive(:new)

        subject
      end
    end
  end
end
