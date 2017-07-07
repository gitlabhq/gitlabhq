require 'spec_helper'

describe ForkedProjectLink, "add link on fork" do
  let(:project_from) { create(:project, :repository) }
  let(:project_to) { fork_project(project_from, user) }
  let(:user) { create(:user) }
  let(:namespace) { user.namespace }

  def fork_project(from_project, user)
    shell = double('gitlab_shell', fork_repository: true)

    service = Projects::ForkService.new(from_project, user)
    allow(service).to receive(:gitlab_shell).and_return(shell)

    service.execute
  end

  before do
    project_from.add_reporter(user)
  end

  it 'project_from knows its forks' do
    _ = project_to

    expect(project_from.forks.count).to eq(1)
  end

  it "project_to knows it is forked" do
    expect(project_to.forked?).to be_truthy
  end

  it "project knows who it is forked from" do
    expect(project_to.forked_from_project).to eq(project_from)
  end

  context 'project_to is pending_delete' do
    before do
      project_to.update!(pending_delete: true)
    end

    it { expect(project_from.forks.count).to eq(0) }
  end

  context 'project_from is pending_delete' do
    before do
      project_from.update!(pending_delete: true)
    end

    it { expect(project_to.forked_from_project).to be_nil }
  end

  describe '#forked?' do
    let(:project_to) { create(:project, forked_project_link: forked_project_link) }
    let(:forked_project_link) { create(:forked_project_link) }

    before do
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

    it "project_to.destroy destroys fork_link" do
      project_to.destroy

      expect(ForkedProjectLink.exists?(id: forked_project_link.id)).to eq(false)
    end
  end

  def fork_project(from_project, user)
    service = Projects::ForkService.new(from_project, user)
    shell = double('gitlab_shell', fork_repository: true)

    allow(service).to receive(:gitlab_shell).and_return(shell)

    service.execute
  end
end
