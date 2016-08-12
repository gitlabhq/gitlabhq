require 'spec_helper'

describe DeleteUserService, services: true do
  describe "Deletes a user and all their personal projects" do
    let!(:user)         { create(:user) }
    let!(:current_user) { create(:user) }
    let!(:namespace)    { create(:namespace, owner: user) }
    let!(:project)      { create(:project, namespace: namespace) }

    context 'no options are given' do
      it 'deletes the user' do
        DeleteUserService.new(current_user).execute(user)

        expect { User.find(user.id)       }.to  raise_error(ActiveRecord::RecordNotFound)
      end

      it 'will delete the project in the near future' do
        expect_any_instance_of(Projects::DestroyService).to receive(:async_execute).once

        DeleteUserService.new(current_user).execute(user)
      end
    end

    context "solo owned groups present" do
      let(:solo_owned)  { create(:group) }
      let(:member)      { create(:group_member) }
      let(:user)        { member.user }

      before do
        solo_owned.group_members = [member]
        DeleteUserService.new(current_user).execute(user)
      end

      it 'does not delete the user' do
        expect(User.find(user.id)).to eq user
      end
    end

    context "deletions with solo owned groups" do
      let(:solo_owned)      { create(:group) }
      let(:member)          { create(:group_member) }
      let(:user)            { member.user }

      before do
        solo_owned.group_members = [member]
        DeleteUserService.new(current_user).execute(user, delete_solo_owned_groups: true)
      end

      it 'deletes solo owned groups' do
        expect { Project.find(solo_owned.id) }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it 'deletes the user' do
        expect { User.find(user.id) }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
