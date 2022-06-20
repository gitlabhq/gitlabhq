# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Integrations::ExecuteWorker, '#perform' do
  let_it_be(:integration) { create(:jira_integration) }

  let(:worker) { described_class.new }

  it 'executes integration with given data' do
    data = { test: 'test' }

    expect_next_found_instance_of(integration.class) do |integration|
      expect(integration).to receive(:execute).with(data)
    end

    worker.perform(integration.id, data)
  end

  it 'logs error messages' do
    error = StandardError.new('invalid URL')

    expect_next_found_instance_of(integration.class) do |integration|
      expect(integration).to receive(:execute).and_raise(error)
      expect(integration).to receive(:log_exception).with(error)
    end

    worker.perform(integration.id, {})
  end

  context 'when integration cannot be found' do
    it 'completes silently and does not log an error' do
      expect(Gitlab::IntegrationsLogger).not_to receive(:error)

      expect do
        worker.perform(non_existing_record_id, {})
      end.not_to raise_error
    end
  end

  context 'when using the old worker class' do
    let(:described_class) { ProjectServiceWorker }

    it 'uses the correct worker attributes', :aggregate_failures do
      expect(described_class.sidekiq_options).to include('retry' => 3, 'dead' => false)
      expect(described_class.get_data_consistency).to eq(:always)
      expect(described_class.get_feature_category).to eq(:integrations)
      expect(described_class.get_urgency).to eq(:low)
      expect(described_class.worker_has_external_dependencies?).to be(true)
    end

    it 'executes integration with given data' do
      data = { test: 'test' }

      expect_next_found_instance_of(integration.class) do |integration|
        expect(integration).to receive(:execute).with(data)
      end

      worker.perform(integration.id, data)
    end
  end
end
