# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::ProjectRepositoryStorageMoves do
  it_behaves_like 'repository_storage_moves API', 'projects' do
    let_it_be(:container) { create(:project, :repository) }
    let_it_be(:storage_move) { create(:project_repository_storage_move, :scheduled, container: container) }
    let(:repository_storage_move_factory) { :project_repository_storage_move }
    let(:bulk_worker_klass) { Projects::ScheduleBulkRepositoryShardMovesWorker }
  end
end
