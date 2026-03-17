# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Internal::Gitaly, feature_category: :gitaly do
  include GitlabShellHelpers

  describe 'GET /internal/gitaly/object_pool_members' do
    let_it_be(:pool) { create(:pool_repository, :ready) }
    let_it_be(:source_project) { pool.source_project }

    subject(:request) do
      get api('/internal/gitaly/object_pool_members'),
        params: params,
        headers: gitlab_shell_internal_api_request_header
    end

    context 'when disk_path is missing' do
      let(:params) { { storage: pool.shard_name } }

      it 'returns 400 bad request' do
        request

        expect(response).to have_gitlab_http_status(:bad_request)
      end
    end

    context 'when storage is missing' do
      let(:params) { { disk_path: pool.disk_path } }

      it 'returns 400 bad request' do
        request

        expect(response).to have_gitlab_http_status(:bad_request)
      end
    end

    context 'when disk_path is not found' do
      let(:params) { { disk_path: 'nonexistent/path', storage: pool.shard_name } }

      it 'returns 404 not found' do
        request

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when storage is not found' do
      let(:params) { { disk_path: pool.disk_path, storage: 'nonexistent-storage' } }

      it 'returns 404 not found' do
        request

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when pool exists with only source project' do
      let(:params) { { disk_path: pool.disk_path, storage: pool.shard_name } }

      it 'returns the source project as a member' do
        request

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to be_an(Array)
        expect(json_response.size).to eq(1)
        expect(json_response.first).to include(
          'relative_path' => "#{source_project.disk_path}.git",
          'is_upstream' => true
        )
      end
    end

    context 'when pool has member projects' do
      let_it_be(:fork_project) do
        create(:project, forked_from_project: source_project, pool_repository: pool)
      end

      let(:params) { { disk_path: pool.disk_path, storage: pool.shard_name } }

      it 'returns all members including source and forks' do
        request

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response.size).to eq(2)

        upstream = json_response.find { |m| m['is_upstream'] }
        fork = json_response.find { |m| !m['is_upstream'] }

        expect(upstream['relative_path']).to eq("#{source_project.disk_path}.git")
        expect(fork['relative_path']).to eq("#{fork_project.disk_path}.git")
      end

      context 'when upstream_only is true' do
        let(:params) { { disk_path: pool.disk_path, storage: pool.shard_name, upstream_only: true } }

        it 'returns only the source project' do
          request

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response.size).to eq(1)
          expect(json_response.first['is_upstream']).to be true
          expect(json_response.first['relative_path']).to eq("#{source_project.disk_path}.git")
        end
      end
    end

    context 'when the authentication token is missing' do
      let(:params) { { disk_path: pool.disk_path, storage: pool.shard_name } }

      it 'returns 401 unauthorized' do
        get api('/internal/gitaly/object_pool_members'), params: params

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'when the source project of a pool does not exist' do
      let(:params) { { disk_path: pool.disk_path, storage: pool.shard_name } }

      before do
        pool.update_column(:source_project_id, nil)
      end

      it 'returns members without marking any as upstream' do
        request

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to be_an(Array)
        expect(json_response.none? { |m| m['is_upstream'] }).to be true
      end

      context 'when upstream_only is true' do
        let(:params) { { disk_path: pool.disk_path, storage: pool.shard_name, upstream_only: true } }

        it 'returns an empty members list' do
          request

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response).to be_an(Array)
          expect(json_response).to be_empty
        end
      end
    end

    context 'when projects have different visibility levels' do
      let_it_be(:public_fork) do
        create(:project, :public, forked_from_project: source_project, pool_repository: pool)
      end

      let_it_be(:private_fork) do
        create(:project, :private, forked_from_project: source_project, pool_repository: pool)
      end

      let(:params) { { disk_path: pool.disk_path, storage: pool.shard_name } }

      it 'returns correct public flag for each member' do
        request

        expect(response).to have_gitlab_http_status(:ok)

        public_member = json_response.find { |m| m['relative_path'] == "#{public_fork.disk_path}.git" }
        private_member = json_response.find { |m| m['relative_path'] == "#{private_fork.disk_path}.git" }

        expect(public_member['public']).to be true
        expect(private_member['public']).to be false
      end
    end
  end
end
