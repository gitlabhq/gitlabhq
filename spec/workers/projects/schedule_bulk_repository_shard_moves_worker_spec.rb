# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::ScheduleBulkRepositoryShardMovesWorker do
  it_behaves_like 'schedules bulk repository shard moves' do
    let_it_be_with_reload(:container) { create(:project, :repository) }

    let(:move_service_klass) { Projects::RepositoryStorageMove }
    let(:worker_klass) { Projects::UpdateRepositoryStorageWorker }
  end
end
