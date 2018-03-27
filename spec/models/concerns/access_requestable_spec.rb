require 'spec_helper'

describe AccessRequestable do
  describe 'Group' do
    describe '#request_access' do
      let(:group) { create(:group, :public, :access_requestable) }
      let(:user) { create(:user) }

      it { expect(group.request_access(user)).to be_a(GroupMember) }
      it { expect(group.request_access(user).user).to eq(user) }
    end

    describe '#access_requested?' do
      let(:group) { create(:group, :public, :access_requestable) }
      let(:user) { create(:user) }

      before do
        group.request_access(user)
      end

      it { expect(group.requesters.exists?(user_id: user)).to be_truthy }
    end
  end

  describe 'Project' do
    describe '#request_access' do
      let(:project) { create(:project, :public, :access_requestable) }
      let(:user) { create(:user) }

      it { expect(project.request_access(user)).to be_a(ProjectMember) }
    end

    describe '#access_requested?' do
      let(:project) { create(:project, :public, :access_requestable) }
      let(:user) { create(:user) }

      before do
        project.request_access(user)
      end

      it { expect(project.requesters.exists?(user_id: user)).to be_truthy }
    end
  end
end
