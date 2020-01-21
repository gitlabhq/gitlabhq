# frozen_string_literal: true

require 'spec_helper'

describe SelfMonitoringProjectCreateWorker do
  describe '#perform' do
    let(:service_class) { Gitlab::DatabaseImporters::SelfMonitoring::Project::CreateService }
    let(:service) { instance_double(service_class) }

    it_behaves_like 'executes service'
  end

  describe '.in_progress?', :clean_gitlab_redis_shared_state do
    it_behaves_like 'returns in_progress based on Sidekiq::Status'
  end
end
