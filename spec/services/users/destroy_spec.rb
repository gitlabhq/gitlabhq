require 'spec_helper'

describe Users::DestroyService, services: true do
  describe "Deletes a user and all their personal projects" do
    let!(:user)      { create(:user) }
    let!(:admin)     { create(:admin) }
    let!(:namespace) { create(:namespace, owner: user) }
    let!(:project)   { create(:project, namespace: namespace) }
    let(:service)    { described_class.new(admin) }

    context 'no options are given' do
      it 'deletes the user' do
        user_data = service.execute(user)

        expect { user_data['email'].to eq(user.email) }
        expect { User.find(user.id) }.to raise_error(ActiveRecord::RecordNotFound)
        expect { Namespace.with_deleted.find(user.namespace.id) }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it 'will delete the project in the near future' do
        expect_any_instance_of(Projects::DestroyService).to receive(:async_execute).once

        service.execute(user)
      end
    end

    context "solo owned groups present" do
      let(:solo_owned)  { create(:group) }
      let(:member)      { create(:group_member) }
      let(:user)        { member.user }

      before do
        solo_owned.group_members = [member]
        service.execute(user)
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
        service.execute(user, delete_solo_owned_groups: true)
      end

      it 'deletes solo owned groups' do
        expect { Project.find(solo_owned.id) }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it 'deletes the user' do
        expect { User.find(user.id) }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "deletion permission checks" do
      it 'does not delete the user when user is not an admin' do
        other_user = create(:user)

        expect { described_class.new(other_user).execute(user) }.to raise_error(Gitlab::Access::AccessDeniedError)
        expect(User.exists?(user.id)).to be(true)
      end

      it 'allows admins to delete anyone' do
        described_class.new(admin).execute(user)

        expect(User.exists?(user.id)).to be(false)
      end

      it 'allows users to delete their own account' do
        described_class.new(user).execute(user)

        expect(User.exists?(user.id)).to be(false)
      end
    end
  end
end
