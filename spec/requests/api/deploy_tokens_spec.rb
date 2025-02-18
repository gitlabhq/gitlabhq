# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::DeployTokens, :aggregate_failures, feature_category: :continuous_delivery do
  let_it_be(:user)          { create(:user) }
  let_it_be(:creator)       { create(:user) }
  let_it_be(:project)       { create(:project, creator_id: creator.id) }
  let_it_be(:group)         { create(:group) }

  let!(:deploy_token) { create(:deploy_token, projects: [project]) }
  let!(:revoked_deploy_token) { create(:deploy_token, projects: [project], revoked: true) }
  let!(:expired_deploy_token) { create(:deploy_token, projects: [project], expires_at: '1988-01-11T04:33:04-0600') }
  let!(:group_deploy_token) { create(:deploy_token, :group, groups: [group]) }
  let!(:revoked_group_deploy_token) { create(:deploy_token, :group, groups: [group], revoked: true) }
  let!(:expired_group_deploy_token) { create(:deploy_token, :group, groups: [group], expires_at: '1988-01-11T04:33:04-0600') }

  describe 'GET /deploy_tokens' do
    subject do
      get api('/deploy_tokens', user, admin_mode: admin_mode)
      response
    end

    let_it_be(:admin_mode) { false }

    it_behaves_like 'GET request permissions for admin mode' do
      let(:path) { '/deploy_tokens' }
    end

    context 'when unauthenticated' do
      let(:user) { nil }

      it { is_expected.to have_gitlab_http_status(:unauthorized) }
    end

    context 'when authenticated as admin' do
      let(:user) { create(:admin) }
      let_it_be(:admin_mode) { true }

      it 'returns all deploy tokens' do
        subject

        token_ids = json_response.map { |token| token['id'] }
        expect(response).to include_pagination_headers
        expect(response).to match_response_schema('public_api/v4/deploy_tokens')
        expect(token_ids).to match_array(
          [
            deploy_token.id,
            revoked_deploy_token.id,
            expired_deploy_token.id,
            group_deploy_token.id,
            revoked_group_deploy_token.id,
            expired_group_deploy_token.id
          ])
      end

      context 'and active=true' do
        it 'only returns active deploy tokens' do
          get api('/deploy_tokens?active=true', user, admin_mode: true)

          token_ids = json_response.map { |token| token['id'] }
          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to include_pagination_headers
          expect(token_ids).to match_array(
            [
              deploy_token.id,
              group_deploy_token.id
            ])
        end
      end
    end
  end

  describe 'GET /projects/:id/deploy_tokens' do
    let(:path) { "/projects/#{project.id}/deploy_tokens" }

    subject do
      get api(path, user)
      response
    end

    context 'when unauthenticated' do
      let(:user) { nil }

      it { is_expected.to have_gitlab_http_status(:not_found) }
    end

    context 'when authenticated as non-admin user' do
      before do
        project.add_developer(user)
      end

      it { is_expected.to have_gitlab_http_status(:forbidden) }
    end

    context 'when authenticated as maintainer' do
      let!(:other_deploy_token) { create(:deploy_token) }

      before do
        project.add_maintainer(user)
      end

      it { is_expected.to have_gitlab_http_status(:ok) }

      it 'returns all deploy tokens for the project' do
        subject

        expect(response).to include_pagination_headers
        expect(response).to match_response_schema('public_api/v4/deploy_tokens')
      end

      it 'does not return deploy tokens for other projects' do
        subject

        token_ids = json_response.map { |token| token['id'] }
        expect(token_ids).to match_array(
          [
            deploy_token.id,
            expired_deploy_token.id,
            revoked_deploy_token.id
          ])
      end

      context 'and active=true' do
        it 'only returns active deploy tokens for the project' do
          get api("/projects/#{project.id}/deploy_tokens?active=true", user)

          token_ids = json_response.map { |token| token['id'] }
          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to include_pagination_headers
          expect(token_ids).to match_array([deploy_token.id])
        end
      end
    end
  end

  describe 'GET /projects/:id/deploy_tokens/:token_id' do
    let(:path) { "/projects/#{project.id}/deploy_tokens/#{deploy_token.id}" }

    subject do
      get api(path, user)
      response
    end

    context 'when unauthenticated' do
      let(:user) { nil }

      it { is_expected.to have_gitlab_http_status(:not_found) }
    end

    context 'when authenticated as non-admin user' do
      before do
        project.add_developer(user)
      end

      it { is_expected.to have_gitlab_http_status(:forbidden) }
    end

    context 'when authenticated as maintainer' do
      before do
        project.add_maintainer(user)
      end

      it { is_expected.to have_gitlab_http_status(:ok) }

      it 'returns specific deploy token for the project' do
        subject

        expect(response).to match_response_schema('public_api/v4/deploy_token')
      end

      context 'invalid request' do
        it 'returns not found with invalid project id' do
          get api("/projects/bad_id/deploy_tokens/#{deploy_token.id}", user)

          expect(response).to have_gitlab_http_status(:not_found)
        end

        it 'returns not found with invalid token id' do
          get api("/projects/#{project.id}/deploy_tokens/#{non_existing_record_id}", user)

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end
  end

  describe 'GET /groups/:id/deploy_tokens' do
    let(:path) { "/groups/#{group.id}/deploy_tokens" }

    subject do
      get api(path, user)
      response
    end

    context 'when unauthenticated' do
      let(:user) { nil }

      it { is_expected.to have_gitlab_http_status(:forbidden) }
    end

    context 'when authenticated as non-admin user' do
      before do
        group.add_developer(user)
      end

      it { is_expected.to have_gitlab_http_status(:forbidden) }
    end

    context 'when authenticated as maintainer' do
      let!(:other_deploy_token) { create(:deploy_token, :group) }

      before do
        group.add_maintainer(user)
      end

      it { is_expected.to have_gitlab_http_status(:ok) }

      it 'returns all deploy tokens for the group' do
        subject

        token_ids = json_response.map { |token| token['id'] }
        expect(response).to include_pagination_headers
        expect(response).to match_response_schema('public_api/v4/deploy_tokens')
        expect(token_ids.length).to be(3)
      end

      it 'does not return deploy tokens for other groups' do
        subject

        token_ids = json_response.map { |token| token['id'] }
        expect(token_ids).not_to include(other_deploy_token.id)
      end

      context 'and active=true' do
        it 'only returns active deploy tokens for the group' do
          get api("/groups/#{group.id}/deploy_tokens?active=true", user)

          token_ids = json_response.map { |token| token['id'] }
          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to include_pagination_headers
          expect(token_ids).to eql([group_deploy_token.id])
        end
      end
    end
  end

  describe 'GET /groups/:id/deploy_tokens/:token_id' do
    let(:path) { "/groups/#{group.id}/deploy_tokens/#{group_deploy_token.id}" }

    subject do
      get api(path, user)
      response
    end

    context 'when unauthenticated' do
      let(:user) { nil }

      it { is_expected.to have_gitlab_http_status(:forbidden) }
    end

    context 'when authenticated as non-admin user' do
      before do
        group.add_developer(user)
      end

      it { is_expected.to have_gitlab_http_status(:forbidden) }
    end

    context 'when authenticated as maintainer' do
      before do
        group.add_maintainer(user)
      end

      it { is_expected.to have_gitlab_http_status(:ok) }

      it 'returns specific deploy token for the group' do
        subject

        expect(response).to match_response_schema('public_api/v4/deploy_token')
      end

      context 'invalid request' do
        it 'returns not found with invalid group id' do
          get api("/groups/bad_id/deploy_tokens/#{group_deploy_token.id}", user)

          expect(response).to have_gitlab_http_status(:not_found)
        end

        it 'returns not found with invalid token id' do
          get api("/groups/#{group.id}/deploy_tokens/#{non_existing_record_id}", user)

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end
  end

  describe 'DELETE /projects/:id/deploy_tokens/:token_id' do
    let(:path) { "/projects/#{project.id}/deploy_tokens/#{deploy_token.id}" }

    subject do
      delete api(path, user)
      response
    end

    context 'when unauthenticated' do
      let(:user) { nil }

      it { is_expected.to have_gitlab_http_status(:not_found) }
    end

    context 'when authenticated as non-admin user' do
      before do
        project.add_developer(user)
      end

      it { is_expected.to have_gitlab_http_status(:forbidden) }
    end

    context 'when authenticated as maintainer' do
      before do
        project.add_maintainer(user)
      end

      it { is_expected.to have_gitlab_http_status(:no_content) }

      it 'calls the deploy token destroy service' do
        expect(::Projects::DeployTokens::DestroyService).to receive(:new)
          .with(project, user, token_id: deploy_token.id)
          .and_return(true)

        subject
      end

      context 'invalid request' do
        it 'returns not found with invalid group id' do
          delete api("/projects/bad_id/deploy_tokens/#{group_deploy_token.id}", user)

          expect(response).to have_gitlab_http_status(:not_found)
        end

        it 'returns bad_request with invalid token id' do
          expect(::Projects::DeployTokens::DestroyService).to receive(:new)
            .with(project, user, token_id: non_existing_record_id)
            .and_raise(ActiveRecord::RecordNotFound)

          delete api("/projects/#{project.id}/deploy_tokens/#{non_existing_record_id}", user)

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end
  end

  context 'deploy token creation' do
    shared_examples 'creating a deploy token' do |entity, unauthenticated_response, authorized_role|
      let(:expires_time) { 1.year.from_now.to_datetime }
      let(:params) do
        {
          name: 'Foo',
          expires_at: expires_time,
          scopes: [
            'read_repository'
          ],
          username: 'Bar'
        }
      end

      context 'when unauthenticated' do
        let(:user) { nil }

        it { is_expected.to have_gitlab_http_status(unauthenticated_response) }
      end

      context 'when authenticated as non-admin user' do
        before do
          send(entity).add_developer(user)
        end

        it { is_expected.to have_gitlab_http_status(:forbidden) }
      end

      context "when authenticated as #{authorized_role}" do
        before do
          send(entity).send("add_#{authorized_role}", user)
        end

        ::DeployToken::AVAILABLE_SCOPES.map(&:to_s).each do |scope|
          context "with valid scope #{scope}" do
            before do
              params[:scopes] = [scope.to_sym]
            end

            it 'creates the deploy token' do
              expect { subject }.to change { DeployToken.count }.by(1)

              expect(response).to have_gitlab_http_status(:created)
              expect(response).to match_response_schema('public_api/v4/deploy_token')
              expect(json_response['name']).to eq('Foo')
              expect(json_response['scopes']).to eq([scope])
              expect(json_response['username']).to eq('Bar')
              expect(json_response['expires_at'].to_time.to_i).to eq(expires_time.to_i)
              expect(json_response['token']).to match(/gldt-[A-Za-z0-9_-]{20}/)
            end
          end

          context 'with all scopes' do
            before do
              params[:scopes] = ::DeployToken::AVAILABLE_SCOPES
            end

            it 'creates the deploy token with all scopes' do
              expect { subject }.to change { DeployToken.count }.by(1)

              expect(response).to have_gitlab_http_status(:created)
              expect(response).to match_response_schema('public_api/v4/deploy_token')
              expect(json_response['scopes']).to eq(::DeployToken::AVAILABLE_SCOPES.map(&:to_s))
            end
          end
        end

        context 'with no optional params given' do
          let(:params) do
            {
              name: 'Foo',
              scopes: [
                'read_repository'
              ]
            }
          end

          it 'creates the deploy token with default values' do
            subject

            expect(response).to have_gitlab_http_status(:created)
            expect(json_response['username']).to match(/gitlab\+deploy-token-\d+/)
            expect(json_response['expires_at']).to eq(nil)
          end
        end

        context 'with an invalid scope' do
          before do
            params[:scopes] = %w[read_repository all_access]
          end

          it { is_expected.to have_gitlab_http_status(:bad_request) }
        end

        context 'with an invalid expires_at date' do
          before do
            params[:expires_at] = 'foo'
          end

          it { is_expected.to have_gitlab_http_status(:bad_request) }
        end
      end
    end

    describe 'POST /projects/:id/deploy_tokens' do
      subject do
        post api("/projects/#{project.id}/deploy_tokens", user), params: params
        response
      end

      it_behaves_like 'creating a deploy token', :project, :not_found, :maintainer
    end

    describe 'POST /groups/:id/deploy_tokens' do
      subject do
        post api("/groups/#{group.id}/deploy_tokens", user), params: params
        response
      end

      it_behaves_like 'creating a deploy token', :group, :forbidden, :owner

      context 'when authenticated as maintainer' do
        before do
          group.add_maintainer(user)
        end

        let(:params) { { name: 'test', scopes: ['read_repository'] } }

        it { is_expected.to have_gitlab_http_status(:forbidden) }
      end
    end
  end

  describe 'DELETE /groups/:id/deploy_tokens/:token_id' do
    let(:path) { "/groups/#{group.id}/deploy_tokens/#{group_deploy_token.id}" }

    subject do
      delete api(path, user)
      response
    end

    context 'when unauthenticated' do
      let(:user) { nil }

      it { is_expected.to have_gitlab_http_status(:forbidden) }
    end

    context 'when authenticated as non-admin user' do
      before do
        group.add_developer(user)
      end

      it { is_expected.to have_gitlab_http_status(:forbidden) }
    end

    context 'when authenticated as maintainer' do
      before do
        group.add_maintainer(user)
      end

      it { is_expected.to have_gitlab_http_status(:forbidden) }
    end

    context 'when authenticated as owner' do
      before do
        group.add_owner(user)
      end

      it 'calls the deploy token destroy service' do
        expect(::Groups::DeployTokens::DestroyService).to receive(:new)
          .with(group, user, token_id: group_deploy_token.id)
          .and_return(true)

        subject
      end

      context 'invalid request' do
        it 'returns bad request with invalid group id' do
          delete api("/groups/bad_id/deploy_tokens/#{group_deploy_token.id}", user)

          expect(response).to have_gitlab_http_status(:not_found)
        end

        it 'returns not found with invalid deploy token id' do
          expect(::Groups::DeployTokens::DestroyService).to receive(:new)
            .with(group, user, token_id: non_existing_record_id)
            .and_raise(ActiveRecord::RecordNotFound)

          delete api("/groups/#{group.id}/deploy_tokens/#{non_existing_record_id}", user)

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end
  end
end
