# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::CommitsController, feature_category: :source_code_management do
  context 'token authentication' do
    context 'when public project' do
      let_it_be(:public_project) { create(:project, :small_repo, :public) }

      it_behaves_like 'authenticates sessionless user for the request spec', 'show atom', public_resource: true do
        let(:url) { project_commits_url(public_project, public_project.default_branch, format: :atom) }
      end
    end

    context 'when private project' do
      let_it_be(:private_project) { create(:project, :small_repo, :private) }

      it_behaves_like 'authenticates sessionless user for the request spec', 'show atom', public_resource: false, ignore_metrics: true do
        let(:url) { project_commits_url(private_project, private_project.default_branch, format: :atom) }

        before do
          private_project.add_maintainer(user)
        end
      end
    end
  end

  describe 'GET #show, on an atom request, when gitaly fails' do
    let_it_be_with_reload(:project) { create(:project, :repository) }
    let_it_be(:user) { create(:user, maintainer_of: project) }

    before do
      sign_in(user)
    end

    context 'when gitaly fails before the ref is resolved' do
      before do
        # Gitlab::Git::Commit.find only rescues Gitlab::Git::CommandError (and CommandTimedOut,
        # a subclass of it) internally, returning nil. ResourceExhaustedError is not a
        # CommandError subclass, so it genuinely propagates out of ref extraction unswallowed,
        # before assign_ref_vars ever assigns @ref.
        allow(Gitlab::Git::Commit).to receive(:find)
          .and_raise(Gitlab::Git::ResourceExhaustedError, 'Gitaly resource exhausted')
      end

      it 'returns 503 instead of a 500 caused by building a URL with a nil ref' do
        get project_commits_url(project, 'master', format: :atom)

        expect(response).to have_gitlab_http_status(:service_unavailable)
        expect(response.body).to include(project_url(project))
        expect(response.body).not_to include(project_commits_url(project, 'master'))
      end
    end

    context 'when gitaly fails after the ref is resolved' do
      before do
        allow_next_instance_of(Repository) do |repository|
          allow(repository).to receive(:commits)
            .and_raise(Gitlab::Git::CommandError, 'Gitaly unavailable')
        end
      end

      it 'returns 503 and links to the ref-scoped commits URL' do
        get project_commits_url(project, 'master', format: :atom)

        expect(response).to have_gitlab_http_status(:service_unavailable)
        expect(response.body).to include(project_commits_url(project, 'master'))
      end
    end
  end

  describe 'GET show' do
    let_it_be_with_reload(:project) { create(:project, :repository) }
    let_it_be(:user) { create(:user, maintainer_of: project) }

    let(:id) { 'master/README.md' }

    before do
      sign_in(user)
    end

    context 'with an invalid limit' do
      it 'uses the default limit' do
        expect_next_instance_of(Repository) do |instance|
          expect(instance).to receive(:commits).with(
            'master',
            path: 'README.md',
            limit: described_class::COMMITS_DEFAULT_LIMIT,
            offset: 0
          ).and_call_original
        end

        get project_commits_path(project, id, limit: 'foo')

        expect(response).to be_successful
      end

      context 'when limit is a hash' do
        it 'uses the default limit' do
          expect_next_instance_of(Repository) do |instance|
            expect(instance).to receive(:commits).with(
              'master',
              path: 'README.md',
              limit: described_class::COMMITS_DEFAULT_LIMIT,
              offset: 0
            ).and_call_original
          end

          get project_commits_path(project, id, limit: { 'broken' => 'value' })

          expect(response).to be_successful
        end
      end
    end

    context 'date range' do
      let(:base_repository_params) do
        {
          path: 'README.md',
          limit: described_class::COMMITS_DEFAULT_LIMIT,
          offset: 0
        }
      end

      # Dates must be parsed as UTC regardless of the ambient time zone.
      around do |example|
        Time.use_zone('America/Los_Angeles') { example.run }
      end

      shared_examples 'repository commits call' do
        it 'passes the correct params' do
          expect_next_instance_of(Repository) do |instance|
            expect(instance).to receive(:commits).with(
              'master',
              **repository_params
            ).and_call_original
          end

          get project_commits_path(project, id, **query_params)

          expect(response).to be_successful
        end
      end

      context 'when committed_before param' do
        context 'is valid' do
          let(:query_params) { { committed_before: '2020-01-01' } }
          let(:repository_params) { base_repository_params.merge(before: Time.utc(2020, 1, 1).to_i) }

          it_behaves_like 'repository commits call'
        end

        context 'is invalid' do
          let(:query_params) { { committed_before: 'xxx' } }
          let(:repository_params) { base_repository_params }

          it_behaves_like 'repository commits call'
        end

        context 'is not provided' do
          let(:query_params) { {} }
          let(:repository_params) { base_repository_params }

          it_behaves_like 'repository commits call'
        end
      end

      context 'with committed_after param' do
        context 'is valid' do
          let(:query_params) { { committed_after: '2020-01-01' } }
          let(:repository_params) { base_repository_params.merge(after: Time.utc(2020, 1, 1).to_i) }

          it_behaves_like 'repository commits call'
        end

        context 'is invalid' do
          let(:query_params) { { committed_after: 'xxx' } }
          let(:repository_params) { base_repository_params }

          it_behaves_like 'repository commits call'
        end
      end
    end
  end

  describe 'GET commits_root' do
    let_it_be_with_reload(:project) { create(:project, :repository) }
    let_it_be(:user) { create(:user, maintainer_of: project) }

    before do
      sign_in(user)
    end

    context 'no ref is provided' do
      it 'redirects to the default branch of the project' do
        get project_commits_root_path(project)

        expect(response).to redirect_to project_commits_path(project)
      end
    end
  end

  describe 'GET /commits/:id/signatures' do
    let_it_be_with_reload(:project) { create(:project, :repository) }
    let_it_be(:user) { create(:user, maintainer_of: project) }

    let(:repository) { project.repository }

    before do
      sign_in(user)
    end

    def send_request
      expect(::Gitlab::GitalyClient).to receive(:allow_ref_name_caching).and_call_original unless id.include?(' ')

      # Markdown-rendering commits on 'master' trips the Gitaly N+1 guard.
      # Remove once https://gitlab.com/gitlab-org/gitlab/-/work_items/631496 is fixed.
      stub_const('Gitlab::GitalyClient::MAXIMUM_GITALY_CALLS', 31)

      get project_signatures_path(project, id: id, format: :json)
    end

    context 'valid branch' do
      let(:id) { 'master' }

      it 'returns a successful response' do
        send_request

        expect(response).to be_successful
      end
    end

    context 'invalid branch format' do
      let(:id) { 'some branch' }

      it 'returns a not found response' do
        send_request

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'with signature message' do
      let(:id) { 'master' }
      let(:commit) { repository.commit('5937ac0a7beb003549fc5fd26fc247adbce4a52e') }
      let(:signature) { json_response['signatures'].find { |s| s['commit_sha'] == commit.id } }

      it 'returns a signature message' do
        send_request

        expect(signature).to be_present

        expect(signature['html']).to include('GPG Key ID')
        expect(signature['html']).to include('This commit was signed with an unverified signature')
      end

      context 'when commit has an unsupported signature type' do
        before do
          allow(Gitlab::Gpg::Commit).to receive(:new).and_call_original
        end

        it 'returns a unsupported signature message' do
          expect_next_instance_of(Gitlab::Gpg::Commit, commit) do |gpg_commit|
            expect(gpg_commit).to receive(:signature).and_return(nil)
          end

          send_request

          expect(signature).to be_present
          expect(signature['html']).to include('Unsupported signature')
        end
      end
    end
  end
end
