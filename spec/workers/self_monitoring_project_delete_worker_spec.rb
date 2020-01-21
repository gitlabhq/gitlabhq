# frozen_string_literal: true

require 'spec_helper'

describe SelfMonitoringProjectDeleteWorker do
  let_it_be(:jid) { 'b5b28910d97563e58c2fe55f' }
  let_it_be(:data_key) { "self_monitoring_delete_result:#{jid}" }

  describe '#perform' do
    let(:service_class) { Gitlab::DatabaseImporters::SelfMonitoring::Project::DeleteService }
    let(:service) { instance_double(service_class) }

    it_behaves_like 'executes service'
  end

  describe '.status', :clean_gitlab_redis_shared_state do
    it_behaves_like 'returns in_progress based on Sidekiq::Status'
  end
end
