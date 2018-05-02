require 'spec_helper'

describe Gitlab::BitbucketImport::ProjectCreator do
  let(:user) { create(:user) }

  let(:repo) do
    double(name: 'Vim',
           slug: 'vim',
           description: 'Test repo',
           is_private: true,
           owner: "asd",
           full_name: 'Vim repo',
           visibility_level: Gitlab::VisibilityLevel::PRIVATE,
           clone_url: 'ssh://git@bitbucket.org/asd/vim.git',
           has_wiki?: false)
  end

  let(:namespace) { create(:group) }
  let(:token) { "asdasd12345" }
  let(:secret) { "sekrettt" }
  let(:access_params) { { bitbucket_access_token: token, bitbucket_access_token_secret: secret } }

  before do
    namespace.add_owner(user)
  end

  it 'creates project' do
    allow_any_instance_of(EE::Project).to receive(:add_import_job)

    project_creator = described_class.new(repo, 'vim', namespace, user, access_params)
    project = project_creator.execute

    expect(project.import_url).to eq("ssh://git@bitbucket.org/asd/vim.git")
    expect(project.visibility_level).to eq(Gitlab::VisibilityLevel::PRIVATE)
  end
end
