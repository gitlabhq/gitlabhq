require 'spec_helper'

describe Gitlab::Shell do
  let(:project) { double('Project', id: 7, path: 'diaspora') }
  let(:gitlab_shell) { Gitlab::Shell.new }

  before do
    Project.stub(find: project)
  end

  it { should respond_to :add_key }
  it { should respond_to :remove_key }
  it { should respond_to :add_repository }
  it { should respond_to :remove_repository }
  it { should respond_to :fork_repository }

  it { gitlab_shell.url_to_repo('diaspora').should == Gitlab.config.gitlab_shell.ssh_path_prefix + "diaspora.git" }
end
