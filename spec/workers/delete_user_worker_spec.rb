require 'spec_helper'

describe DeleteUserWorker do
  describe "Deletes a user and all their personal projects" do
    let!(:user)         { create(:user) }
    let!(:current_user) { create(:user) }
    let!(:namespace)    { create(:namespace, owner: user) }
    let!(:project)      { create(:project, namespace: namespace) }

    context 'no force flag given' do
      before do
        DeleteUserWorker.new.perform(current_user.id, user.id)
      end

      it 'deletes all personal projects' do
        expect { Project.find(project.id) }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it 'deletes the user' do
        expect { User.find(user.id) }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "solo owned groups present" do
      let(:solo_owned)  { create(:group) }
      let(:member)      { create(:group_member) }
      let(:user)        { member.user }

      before do
        solo_owned.group_members = [member]
        DeleteUserWorker.new.perform(current_user.id, user.id)
      end

      it 'does not delete the user' do
        expect(User.find(user.id)).to eq user
      end
    end

    context "deletions with force" do
      let(:solo_owned)      { create(:group) }
      let(:member)          { create(:group_member) }
      let(:user)            { member.user }

      before do
        solo_owned.group_members = [member]
        DeleteUserWorker.new.perform(current_user.id, user.id, "delete_solo_owned_groups" => true)
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
