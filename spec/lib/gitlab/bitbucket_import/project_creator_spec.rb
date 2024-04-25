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

    expect(project.import_url).to eq("https://x-token-auth:asdasd12345@bitbucket.org/repo/repo.git")
    expect(project.visibility_level).to eq(Gitlab::VisibilityLevel::PRIVATE)
  end

  context 'when basic auth is used' do
    let(:access_params) { { username: 'foo', app_password: 'bar' } }

    it 'sets basic auth in import_url' do
      project = creator.execute

      expect(project.import_url).to eq("https://foo:bar@bitbucket.org/repo/repo.git")
    end
  end
end
