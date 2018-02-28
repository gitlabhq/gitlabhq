require 'spec_helper'

describe Members::UpdateService do
  let(:project) { create(:project, :public) }
  let(:group) { create(:group, :public) }
  let(:current_user) { create(:user) }
  let(:member_user) { create(:user) }
  let(:permission) { :update }
  let(:member) { source.members_and_requesters.find_by!(user_id: member_user.id) }
  let(:params) do
    { access_level: Gitlab::Access::MASTER }
  end

  shared_examples 'a service raising Gitlab::Access::AccessDeniedError' do
    it 'raises Gitlab::Access::AccessDeniedError' do
      expect { described_class.new(current_user, params).execute(member, permission: permission) }
        .to raise_error(Gitlab::Access::AccessDeniedError)
    end
  end

  shared_examples 'a service updating a member' do
    it 'updates the member' do
      updated_member = described_class.new(current_user, params).execute(member, permission: permission)

      expect(updated_member).to be_valid
      expect(updated_member.access_level).to eq(Gitlab::Access::MASTER)
    end
  end

  before do
    project.add_developer(member_user)
    group.add_developer(member_user)
  end

  context 'when current user cannot update the given member' do
    it_behaves_like 'a service raising Gitlab::Access::AccessDeniedError' do
      let(:source) { project }
    end

    it_behaves_like 'a service raising Gitlab::Access::AccessDeniedError' do
      let(:source) { group }
    end
  end

  context 'when current user can update the given member' do
    before do
      project.add_master(current_user)
      group.add_owner(current_user)
    end

    it_behaves_like 'a service updating a member' do
      let(:source) { project }
    end

    it_behaves_like 'a service updating a member' do
      let(:source) { group }
    end
  end
end
