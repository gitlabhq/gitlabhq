require 'spec_helper'

describe Gitlab::GoogleCodeImport::ProjectCreator do
  let(:user) { create(:user) }
  let(:repo) do
    Gitlab::GoogleCodeImport::Repository.new(
      "name" => 'vim',
      "summary" => 'VI Improved',
      "repositoryUrls" => ["https://vim.googlecode.com/git/"]
    )
  end
  let(:namespace) { create(:group, owner: user) }

  before do
    namespace.add_owner(user)
  end

  it 'creates project' do
    allow_any_instance_of(Project).to receive(:add_import_job)

    project_creator = described_class.new(repo, namespace, user)
    project = project_creator.execute

    expect(project.import_url).to eq("https://vim.googlecode.com/git/")
    expect(project.visibility_level).to eq(Gitlab::VisibilityLevel::PUBLIC)
  end
end
