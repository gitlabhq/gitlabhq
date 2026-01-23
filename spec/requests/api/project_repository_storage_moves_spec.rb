# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::ProjectRepositoryStorageMoves, feature_category: :gitaly do
  let_it_be(:user) { create(:admin) }
  let_it_be(:container) { create(:project, :repository) }
  let_it_be(:storage_move) { create(:project_repository_storage_move, :scheduled, container: container) }

  it_behaves_like 'repository_storage_moves API', 'projects' do
    let(:repository_storage_move_factory) { :project_repository_storage_move }
    let(:bulk_worker_klass) { Projects::ScheduleBulkRepositoryShardMovesWorker }

    context 'when project is hidden' do
      let_it_be(:container) { create(:project, :hidden) }
      let_it_be(:storage_move) { create(:project_repository_storage_move, :scheduled, container: container) }

      it_behaves_like 'get single container repository storage move' do
        let(:container_id) { container.id }
        let(:url) { "/projects/#{container_id}/repository_storage_moves/#{repository_storage_move_id}" }
      end

      it_behaves_like 'post single container repository storage move'
    end

    context 'when project is pending delete' do
      let_it_be(:container) { create(:project, pending_delete: true) }
      let_it_be(:storage_move) { create(:project_repository_storage_move, :scheduled, container: container) }

      it_behaves_like 'get single container repository storage move' do
        let(:container_id) { container.id }
        let(:url) { "/projects/#{container_id}/repository_storage_moves/#{repository_storage_move_id}" }
      end

      it_behaves_like 'post single container repository storage move'
    end
  end

  describe "GET /projects/:id/repository_storage_moves" do
    it_behaves_like 'authorizing granular token permissions', :read_repository_storage_move do
      let(:boundary_object) { container }
      let(:request) do
        get api("/projects/#{container.id}/repository_storage_moves",
          personal_access_token: pat)
      end
    end
  end

  describe "GET /projects/:id/repository_storage_moves/:repository_storage_move_id" do
    it_behaves_like 'authorizing granular token permissions', :read_repository_storage_move do
      let(:boundary_object) { container }
      let(:request) do
        get api("/projects/#{container.id}/repository_storage_moves/#{storage_move.id}",
          personal_access_token: pat)
      end
    end
  end

  describe "POST /projects/:id/repository_storage_moves" do
    before do
      stub_storage_settings('test_second_storage' => {})
    end

    it_behaves_like 'authorizing granular token permissions', :create_repository_storage_move do
      let(:boundary_object) { container }
      let(:request) do
        post api("/projects/#{container.id}/repository_storage_moves", personal_access_token: pat),
          params: { destination_storage_name: 'test_second_storage' }
      end
    end
  end
end
