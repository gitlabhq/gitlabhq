require 'spec_helper'

describe Gitlab::GitlabImport::ProjectCreator do
  let(:user) { create(:user, gitlab_access_token: "asdffg") }
  let(:repo) {{
    name: 'vim',
    path: 'vim',
    visibility_level: Gitlab::VisibilityLevel::PRIVATE,
    path_with_namespace: 'asd/vim',
    http_url_to_repo: "https://gitlab.com/asd/vim.git",
    owner: {name: "john"}}.with_indifferent_access
  }
  let(:namespace){ create(:namespace) }

  it 'creates project' do
    Project.any_instance.stub(:add_import_job)
    
    project_creator = Gitlab::GitlabImport::ProjectCreator.new(repo, namespace, user)
    project_creator.execute
    project = Project.last
    
    project.import_url.should ==  "https://oauth2:asdffg@gitlab.com/asd/vim.git"
    project.visibility_level.should == Gitlab::VisibilityLevel::PRIVATE
  end
end
