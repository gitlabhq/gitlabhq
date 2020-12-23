# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProjectScheduleBulkRepositoryShardMovesWorker do
  it_behaves_like 'schedules bulk repository shard moves' do
    let_it_be_with_reload(:container) { create(:project, :repository).tap { |project| project.track_project_repository } }

    let(:move_service_klass) { ProjectRepositoryStorageMove }
    let(:worker_klass) { ProjectUpdateRepositoryStorageWorker }
  end
end
