# frozen_string_literal: true
require 'spec_helper'

RSpec.describe ProjectServiceWorker, '#perform' do
  let(:worker) { described_class.new }
  let(:integration) { Integrations::Jira.new }

  before do
    allow(Integration).to receive(:find).and_return(integration)
  end

  it 'executes integration with given data' do
    data = { test: 'test' }
    expect(integration).to receive(:execute).with(data)

    worker.perform(1, data)
  end

  it 'logs error messages' do
    error = StandardError.new('invalid URL')
    allow(integration).to receive(:execute).and_raise(error)

    expect(Gitlab::ErrorTracking).to receive(:log_exception).with(error, integration_class: 'Integrations::Jira')

    worker.perform(1, {})
  end
end
