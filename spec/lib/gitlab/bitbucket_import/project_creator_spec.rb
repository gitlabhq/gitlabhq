# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BitbucketImport::ProjectCreator, feature_category: :importers do
  let(:user) { create(:user) }

  let(:repo) do
    Bitbucket::Representation::Repo.new(
      'id' => 1,
      'name' => 'foo',
      'description' => 'bar',
      'is_private' => true,
      'links' => {
        'clone' => [
          { 'name' => 'https', 'href' => 'https://bitbucket.org/repo/repo.git' }
        ]
      }
    )
  end

  let(:namespace) { create(:group) }
  let(:token) { "asdasd12345" }
  let(:secret) { "sekrettt" }
  let(:access_params) { { token: token } }

  before do
    namespace.add_owner(user)

    allow_next_instance_of(Project) do |project|
      allow(project).to receive(:add_import_job)
    end
  end

  subject(:creator) { described_class.new(repo, 'vim', namespace, user, access_params) }

  it 'creates project' do
    project = creator.execute

    expect(project.unsafe_import_url).to eq("https://x-token-auth:asdasd12345@bitbucket.org/repo/repo.git")
    expect(project.visibility_level).to eq(Gitlab::VisibilityLevel::PRIVATE)
  end

  context 'when basic auth is used' do
    let(:access_params) { { username: 'foo', app_password: 'bar' } }

    it 'sets basic auth in unsafe_import_url' do
      project = creator.execute

      expect(project.unsafe_import_url).to eq("https://foo:bar@bitbucket.org/repo/repo.git")
    end
  end

  context 'when API token is used' do
    let(:access_params) { { email: 'user@example.com', api_token: 'token123' } }

    before do
      stub_application_setting(import_sources: %w[bitbucket])
    end

    it 'sets API token auth in unsafe_import_url with static username' do
      project = creator.execute

      expect(project.unsafe_import_url)
        .to eq("https://x-bitbucket-api-token-auth:token123@bitbucket.org/repo/repo.git")
    end

    it 'stores API token credentials in import_data' do
      project = creator.execute

      expect(project).to be_persisted, "Project errors: #{project.errors.full_messages.join(', ')}"
      expect(project.import_data).to be_present
      expect(project.import_data.credentials).to include(
        email: 'user@example.com',
        api_token: 'token123'
      )
    end
  end

  context 'when repo does not have clone links' do
    let(:repo) do
      Bitbucket::Representation::Repo.new(
        'id' => 1,
        'name' => 'foo',
        'description' => 'bar',
        'is_private' => true
      )
    end

    it 'returns nil' do
      expect(creator.execute).to be_nil
    end
  end
end
