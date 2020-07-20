# frozen_string_literal: true
require 'spec_helper'

RSpec.describe ProjectServiceWorker, '#perform' do
  let(:worker) { described_class.new }
  let(:service) { JiraService.new }

  before do
    allow(Service).to receive(:find).and_return(service)
  end

  it 'executes service with given data' do
    data = { test: 'test' }
    expect(service).to receive(:execute).with(data)

    worker.perform(1, data)
  end

  it 'logs error messages' do
    allow(service).to receive(:execute).and_raise(StandardError, 'invalid URL')
    expect(Sidekiq.logger).to receive(:error).with({ class: described_class.name, service_class: service.class.name, message: "invalid URL" })

    worker.perform(1, {})
  end
end
