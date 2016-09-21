require 'spec_helper'

describe ForkedProjectLink, "add link on fork" do
  let(:project_from) { create(:project) }
  let(:namespace) { create(:namespace) }
  let(:user) { create(:user, namespace: namespace) }

  before do
    @project_to = fork_project(project_from, user)
  end

  it "project_to knows it is forked" do
    expect(@project_to.forked?).to be_truthy
  end

  it "project knows who it is forked from" do
    expect(@project_to.forked_from_project).to eq(project_from)
  end
end

describe '#forked?' do
  let(:forked_project_link) { build(:forked_project_link) }
  let(:project_from) { create(:project) }
  let(:project_to) { create(:project, forked_project_link: forked_project_link) }

  before :each do
    forked_project_link.forked_from_project = project_from
    forked_project_link.forked_to_project = project_to
    forked_project_link.save!
  end

  it "project_to knows it is forked" do
    expect(project_to.forked?).to be_truthy
  end

  it "project_from is not forked" do
    expect(project_from.forked?).to be_falsey
  end
end

def fork_project(from_project, user)
  shell = double('gitlab_shell', fork_repository: true)

  service = Projects::ForkService.new(from_project, user)
  allow(service).to receive(:gitlab_shell).and_return(shell)

  service.execute
end
