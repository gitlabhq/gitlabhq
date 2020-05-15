# frozen_string_literal: true

require 'spec_helper'

describe API::ProjectRepositoryStorageMoves do
  include AccessMatchersForRequest

  let(:user) { create(:admin) }
  let!(:storage_move) { create(:project_repository_storage_move, :scheduled) }

  describe 'GET /project_repository_storage_moves' do
    def get_project_repository_storage_moves
      get api('/project_repository_storage_moves', user)
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

      create(:project_repository_storage_move, :scheduled)

      expect { get_project_repository_storage_moves }.not_to exceed_query_limit(control)
    end

    it 'returns the most recently created first' do
      storage_move_oldest = create(:project_repository_storage_move, :scheduled, created_at: 2.days.ago)
      storage_move_middle = create(:project_repository_storage_move, :scheduled, created_at: 1.day.ago)

      get api('/project_repository_storage_moves', user)

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

  describe 'GET /project_repository_storage_moves/:id' do
    let(:project_repository_storage_move_id) { storage_move.id }

    def get_project_repository_storage_move
      get api("/project_repository_storage_moves/#{project_repository_storage_move_id}", user)
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
end
