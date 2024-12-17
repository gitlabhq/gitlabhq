# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BitbucketServerImport::ProjectCreator, feature_category: :importers do
  let(:project_key) { 'TEST' }
  let(:repo_slug) { 'my-repo' }
  let(:name) { 'Test Project' }
  let(:namespace) { create(:group) }
  let(:current_user) { create(:user) }
  let(:session_data) { { 'token' => 'abc123' } }
  let(:timeout_strategy) { 'default' }

  let(:repo_data) do
    {
      'description' => 'Test repo',
      'project' => {
        'public' => true
      },
      'links' => {
        'self' => [
          {
            'href' => 'http://localhost/brows',
            'name' => 'http'
          }
        ],
        'clone' => [
          {
            'href' => 'http://localhost/clone',
            'name' => 'http'
          }
        ]
      }
    }
  end

  let(:repo) do
    BitbucketServer::Representation::Repo.new(repo_data)
  end

  subject(:creator) do
    described_class.new(
      project_key,
      repo_slug,
      repo,
      name,
      namespace,
      current_user,
      session_data,
      timeout_strategy
    )
  end

  describe '#execute' do
    let_it_be(:project) { create(:project) }
    let(:service) { instance_double(Projects::CreateService) }

    before do
      allow(Projects::CreateService).to receive(:new).and_return(service)
      allow(service).to receive(:execute).and_return(project)
    end

    it 'passes the arguments to Project::CreateService' do
      expected_params = {
        name: name,
        path: name,
        description: repo.description,
        namespace_id: namespace.id,
        organization_id: namespace.organization_id,
        visibility_level: repo.visibility_level,
        import_type: 'bitbucket_server',
        import_source: repo.browse_url,
        import_url: repo.clone_url,
        import_data: {
          credentials: session_data,
          data: {
            project_key: project_key,
            repo_slug: repo_slug,
            timeout_strategy: timeout_strategy,
            bitbucket_server_notes_separate_worker: true,
            user_contribution_mapping_enabled: true
          }
        },
        skip_wiki: true
      }

      expect(Projects::CreateService).to receive(:new)
        .with(current_user, expected_params)

      creator.execute
    end

    context 'when feature flags are disabled' do
      before do
        stub_feature_flags(bitbucket_server_notes_separate_worker: false)
        stub_feature_flags(importer_user_mapping: false)
        stub_feature_flags(bitbucket_server_user_mapping: false)
      end

      it 'disables these options in the import_data' do
        expected_params = {
          import_data: {
            credentials: session_data,
            data: {
              project_key: project_key,
              repo_slug: repo_slug,
              timeout_strategy: timeout_strategy,
              bitbucket_server_notes_separate_worker: false,
              user_contribution_mapping_enabled: false
            }
          }
        }

        expect(Projects::CreateService).to receive(:new)
          .with(current_user, a_hash_including(expected_params))

        creator.execute
      end
    end
  end
end
