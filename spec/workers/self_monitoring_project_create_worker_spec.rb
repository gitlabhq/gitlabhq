# frozen_string_literal: true

require 'spec_helper'

describe SelfMonitoringProjectCreateWorker do
  describe '#perform' do
    let(:service_class) { Gitlab::DatabaseImporters::SelfMonitoring::Project::CreateService }
    let(:service) { instance_double(service_class) }

    before do
      allow(service_class).to receive(:new) { service }
    end

    it 'runs the SelfMonitoring::Project::CreateService' do
      expect(service).to receive(:execute)

      subject.perform
    end
  end

  describe '.in_progress?', :clean_gitlab_redis_shared_state do
    it 'returns in_progress when job is enqueued' do
      jid = described_class.perform_async

      expect(described_class.in_progress?(jid)).to eq(true)
    end
  end
end
