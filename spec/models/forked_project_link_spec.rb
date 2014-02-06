# == Schema Information
#
# Table name: forked_project_links
#
#  id                     :integer          not null, primary key
#  forked_to_project_id   :integer          not null
#  forked_from_project_id :integer          not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#

require 'spec_helper'

describe ForkedProjectLink, "add link on fork" do
  let(:project_from) { create(:project) }
  let(:namespace) { create(:namespace) }
  let(:user) { create(:user, namespace: namespace) }

  before do
    @project_to = fork_project(project_from, user)
  end

  it "project_to should know it is forked" do
    @project_to.forked?.should be_true
  end

  it "project should know who it is forked from" do
    @project_to.forked_from_project.should == project_from
  end
end

describe :forked_from_project do
  let(:forked_project_link) { build(:forked_project_link) }
  let(:project_from) { create(:project) }
  let(:project_to) { create(:project, forked_project_link: forked_project_link) }


  before :each do
    forked_project_link.forked_from_project = project_from
    forked_project_link.forked_to_project = project_to
    forked_project_link.save!
  end


  it "project_to should know it is forked" do
    project_to.forked?.should be_true
  end

  it "project_from should not be forked" do
    project_from.forked?.should be_false
  end

  it "project_to.destroy should destroy fork_link" do
    forked_project_link.should_receive(:destroy)
    project_to.destroy
  end

end

def fork_project(from_project, user)
  context = Projects::ForkService.new(from_project, user)
  shell = double("gitlab_shell")
  shell.stub(fork_repository: true)
  context.stub(gitlab_shell: shell)
  context.execute
end

