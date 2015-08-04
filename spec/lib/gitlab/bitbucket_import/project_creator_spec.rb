require 'spec_helper'

describe Gitlab::BitbucketImport::ProjectCreator do
  let(:user) { create(:user, bitbucket_access_token: "asdffg", bitbucket_access_token_secret: "sekret") }
  let(:repo) do
    {
      name: 'Vim',
      slug: 'vim',
      is_private: true,
      owner: "asd"
    }.with_indifferent_access
  end
  let(:namespace){ create(:group, owner: user) }

  before do
    namespace.add_owner(user)
  end

  it 'creates project' do
    allow_any_instance_of(Project).to receive(:add_import_job)

    project_creator = Gitlab::BitbucketImport::ProjectCreator.new(repo, namespace, user)
    project = project_creator.execute

    expect(project.import_url).to eq("ssh://git@bitbucket.org/asd/vim.git")
    expect(project.visibility_level).to eq(Gitlab::VisibilityLevel::PRIVATE)
  end
end
