# frozen_string_literal: true

require 'spec_helper'

describe API::ProjectRepositoryStorageMoves do
  include AccessMatchersForRequest

  let_it_be(:user) { create(:admin) }
  let_it_be(:project) { create(:project) }
  let_it_be(:storage_move) { create(:project_repository_storage_move, :scheduled, project: project) }

  shared_examples 'get single project repository storage move' do
    let(:project_repository_storage_move_id) { storage_move.id }

    def get_project_repository_storage_move
      get api(url, user)
    end

    it 'returns a project repository storage move' do
      get_project_repository_storage_move

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to match_response_schema('public_api/v4/project_repository_storage_move')
      expect(json_response['id']).to eq(storage_move.id)
      expect(json_response['state']).to eq(storage_move.human_state_name)
    end

    context 'non-existent project repository storage move' do
      let(:project_repository_storage_move_id) { non_existing_record_id }

      it 'returns not found' do
        get_project_repository_storage_move

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    describe 'permissions' do
      it { expect { get_project_repository_storage_move }.to be_allowed_for(:admin) }
      it { expect { get_project_repository_storage_move }.to be_denied_for(:user) }
    end
  end

  shared_examples 'get project repository storage move list' do
    def get_project_repository_storage_moves
      get api(url, user)
    end

    it 'returns project repository storage moves' do
      get_project_repository_storage_moves

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to include_pagination_headers
      expect(response).to match_response_schema('public_api/v4/project_repository_storage_moves')
      expect(json_response.size).to eq(1)
      expect(json_response.first['id']).to eq(storage_move.id)
      expect(json_response.first['state']).to eq(storage_move.human_state_name)
    end

    it 'avoids N+1 queries', :request_store do
      # prevent `let` from polluting the control
      get_project_repository_storage_moves

      control = ActiveRecord::QueryRecorder.new { get_project_repository_storage_moves }

      create(:project_repository_storage_move, :scheduled, project: project)

      expect { get_project_repository_storage_moves }.not_to exceed_query_limit(control)
    end

    it 'returns the most recently created first' do
      storage_move_oldest = create(:project_repository_storage_move, :scheduled, project: project, created_at: 2.days.ago)
      storage_move_middle = create(:project_repository_storage_move, :scheduled, project: project, created_at: 1.day.ago)

      get_project_repository_storage_moves

      json_ids = json_response.map {|storage_move| storage_move['id'] }
      expect(json_ids).to eq([
        storage_move.id,
        storage_move_middle.id,
        storage_move_oldest.id
      ])
    end

    describe 'permissions' do
      it { expect { get_project_repository_storage_moves }.to be_allowed_for(:admin) }
      it { expect { get_project_repository_storage_moves }.to be_denied_for(:user) }
    end
  end

  describe 'GET /project_repository_storage_moves' do
    it_behaves_like 'get project repository storage move list' do
      let(:url) { '/project_repository_storage_moves' }
    end
  end

  describe 'GET /project_repository_storage_moves/:repository_storage_move_id' do
    it_behaves_like 'get single project repository storage move' do
      let(:url) { "/project_repository_storage_moves/#{project_repository_storage_move_id}" }
    end
  end

  describe 'GET /projects/:id/repository_storage_moves' do
    it_behaves_like 'get project repository storage move list' do
      let(:url) { "/projects/#{project.id}/repository_storage_moves" }
    end
  end

  describe 'GET /projects/:id/repository_storage_moves/:repository_storage_move_id' do
    it_behaves_like 'get single project repository storage move' do
      let(:url) { "/projects/#{project.id}/repository_storage_moves/#{project_repository_storage_move_id}" }
    end
  end

  describe 'POST /projects/:id/repository_storage_moves' do
    let(:url) { "/projects/#{project.id}/repository_storage_moves" }
    let(:destination_storage_name) { 'test_second_storage' }

    def create_project_repository_storage_move
      post api(url, user), params: { destination_storage_name: destination_storage_name }
    end

    before do
      stub_storage_settings('test_second_storage' => { 'path' => 'tmp/tests/extra_storage' })
    end

    it 'schedules a project repository storage move' do
      create_project_repository_storage_move

      storage_move = project.repository_storage_moves.last

      expect(response).to have_gitlab_http_status(:created)
      expect(response).to match_response_schema('public_api/v4/project_repository_storage_move')
      expect(json_response['id']).to eq(storage_move.id)
      expect(json_response['state']).to eq('scheduled')
      expect(json_response['source_storage_name']).to eq('default')
      expect(json_response['destination_storage_name']).to eq(destination_storage_name)
    end

    describe 'permissions' do
      it { expect { create_project_repository_storage_move }.to be_allowed_for(:admin) }
      it { expect { create_project_repository_storage_move }.to be_denied_for(:user) }
    end

    context 'destination_storage_name is missing' do
      let(:destination_storage_name) { nil }

      it 'returns a validation error' do
        create_project_repository_storage_move

        expect(response).to have_gitlab_http_status(:bad_request)
      end
    end
  end
end
