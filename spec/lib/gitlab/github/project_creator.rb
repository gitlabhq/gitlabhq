require 'spec_helper'

describe Gitlab::Github::ProjectCreator do
  let(:user) { create(:user, github_access_token: "asdffg") }
  let(:repo) { OpenStruct.new(
    login: 'vim',
    name: 'vim',
    private: true,
    full_name: 'asd/vim',
    clone_url: "https://gitlab.com/asd/vim.git",
    owner: OpenStruct.new(login: "john"))
  }
  let(:namespace){ create(:namespace) }

  it 'creates project' do
    Project.any_instance.stub(:add_import_job)
    
    project_creator = Gitlab::Github::ProjectCreator.new(repo, namespace, user)
    project_creator.execute
    project = Project.last
    
    project.import_url.should ==  "https://asdffg@gitlab.com/asd/vim.git"
    project.visibility_level.should == Gitlab::VisibilityLevel::PRIVATE
  end
end
