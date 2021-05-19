# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Prometheus::CreateDefaultAlertsWorker do
  let_it_be(:project) { create(:project) }

  let(:worker) { described_class.new }
  let(:logger) { worker.send(:logger) }
  let(:service) { instance_double(Prometheus::CreateDefaultAlertsService) }
  let(:service_result) { ServiceResponse.success }

  subject { described_class.new.perform(project.id) }

  before do
    allow(Prometheus::CreateDefaultAlertsService)
      .to receive(:new).with(project: project)
      .and_return(service)
    allow(service).to receive(:execute)
      .and_return(service_result)
  end

  it_behaves_like 'an idempotent worker' do
    let(:job_args) { [project.id] }

    it 'calls the service' do
      expect(service).to receive(:execute)

      subject
    end

    context 'project is nil' do
      let(:job_args) { [nil] }

      it 'does not call the service' do
        expect(service).not_to receive(:execute)

        subject
      end
    end

    context 'when service returns an error' do
      let(:error_message) { 'some message' }
      let(:service_result) { ServiceResponse.error(message: error_message) }

      it 'succeeds and logs the error' do
        expect(logger)
          .to receive(:info)
          .with(a_hash_including('message' => error_message))
          .exactly(worker_exec_times).times

        subject
      end
    end
  end

  context 'when service raises an exception' do
    let(:error_message) { 'some exception' }
    let(:exception) { StandardError.new(error_message) }

    it 're-raises exception' do
      allow(service).to receive(:execute).and_raise(exception)

      expect { subject }.to raise_error(exception)
    end
  end
end
