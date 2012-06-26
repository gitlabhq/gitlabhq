# == Schema Information
#
# Table name: protected_branches
#
#  id         :integer(4)      not null, primary key
#  project_id :integer(4)      not null
#  name       :string(255)     not null
#  created_at :datetime        not null
#  updated_at :datetime        not null
#

require 'spec_helper'

describe ProtectedBranch do
  let(:project) { Factory(:project) }

  describe 'Associations' do
    it { should belong_to(:project) }
  end

  describe 'Validation' do
    it { should validate_presence_of(:project_id) }
    it { should validate_presence_of(:name) }
  end

  describe 'Callbacks' do
    subject { ProtectedBranch.new(:project => project, :name => 'branch_name') }

    it 'call update_repository after save' do
      subject.should_receive(:update_repository)
      subject.save
    end

    it 'call update_repository after destroy' do
      subject.should_receive(:update_repository)
      subject.destroy
    end
  end

  describe '#update_repository' do
    let(:gitolite) { mock }

    subject { ProtectedBranch.new(:project => project) }

    it "updates the branch's project repo permissions" do
      Gitlab::GitHost.should_receive(:system).and_return(gitolite)
      gitolite.should_receive(:update_project).with(project.path, project)

      subject.update_repository
    end
  end

  describe '#commit' do
    subject { ProtectedBranch.new(:project => project, :name => 'cant_touch_this') }

    it 'commits itself to its project' do
      project.should_receive(:commit).with('cant_touch_this')

      subject.commit
    end
  end
end
