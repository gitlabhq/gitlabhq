require 'spec_helper'

describe Gitlab::BitbucketImport::ProjectCreator, lib: true do
  let(:user) { create(:user) }
  let(:repo) do
    {
      name: 'Vim',
      slug: 'vim',
      is_private: true,
      owner: "asd"
    }.with_indifferent_access
  end
  let(:namespace){ create(:group, owner: user) }
  let(:token) { "asdasd12345" }
  let(:secret) { "sekrettt" }
  let(:access_params) { { bitbucket_access_token: token, bitbucket_access_token_secret: secret } }

  before do
    namespace.add_owner(user)
  end

  it 'creates project' do
    allow_any_instance_of(Project).to receive(:add_import_job)

    project_creator = Gitlab::BitbucketImport::ProjectCreator.new(repo, namespace, user, access_params)
    project = project_creator.execute

    expect(project.import_url).to eq("ssh://git@bitbucket.org/asd/vim.git")
    expect(project.visibility_level).to eq(Gitlab::VisibilityLevel::PRIVATE)
  end
end
