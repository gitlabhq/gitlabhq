require 'spec_helper'

describe Gitlab::Gitolite do
  let(:project) { double('Project', id: 7, path: 'diaspora') }
  let(:gitolite_config) { double('Gitlab::GitoliteConfig') }
  let(:gitolite) { Gitlab::Gitolite.new }

  before do
    gitolite.stub(config: gitolite_config)
    Project.stub(find: project)
  end

  it { should respond_to :set_key }
  it { should respond_to :remove_key }

  it { should respond_to :update_repository }
  it { should respond_to :create_repository }
  it { should respond_to :remove_repository }

  it { gitolite.url_to_repo('diaspora').should == Gitlab.config.gitolite.ssh_path_prefix + "diaspora.git" }

  it "should call config update" do
    gitolite_config.should_receive(:update_project!)
    gitolite.update_repository(project.id)
  end
end
