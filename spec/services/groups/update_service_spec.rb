require 'spec_helper'

describe Groups::UpdateService do
  let!(:user) { create(:user) }
  let!(:private_group) { create(:group, :private) }
  let!(:internal_group) { create(:group, :internal) }
  let!(:public_group) { create(:group, :public) }

  describe "#execute" do
    context "project visibility_level validation" do
      context "public group with public projects" do
        let!(:service) { described_class.new(public_group, user, visibility_level: Gitlab::VisibilityLevel::INTERNAL) }

        before do
          public_group.add_user(user, Gitlab::Access::MASTER)
          create(:project, :public, group: public_group)
        end

        it "does not change permission level" do
          service.execute
          expect(public_group.errors.count).to eq(1)
        end
      end

      context "internal group with internal project" do
        let!(:service) { described_class.new(internal_group, user, visibility_level: Gitlab::VisibilityLevel::PRIVATE) }

        before do
          internal_group.add_user(user, Gitlab::Access::MASTER)
          create(:project, :internal, group: internal_group)
        end

        it "does not change permission level" do
          service.execute
          expect(internal_group.errors.count).to eq(1)
        end
      end
    end

    context "with parent_id user doesn't have permissions for" do
      let(:service) { described_class.new(public_group, user, parent_id: private_group.id) }

      before do
        service.execute
      end

      it 'does not update parent_id' do
        updated_group = public_group.reload

        expect(updated_group.parent_id).to be_nil
      end
    end
  end

  context "unauthorized visibility_level validation" do
    let!(:service) { described_class.new(internal_group, user, visibility_level: 99) }
    before do
      internal_group.add_user(user, Gitlab::Access::MASTER)
    end

    it "does not change permission level" do
      service.execute
      expect(internal_group.errors.count).to eq(1)
    end
  end

  context 'rename group' do
    let!(:service) { described_class.new(internal_group, user, path: SecureRandom.hex) }

    before do
      internal_group.add_user(user, Gitlab::Access::MASTER)
      create(:project, :internal, group: internal_group)
    end

    it 'returns true' do
      expect(service.execute).to eq(true)
    end

    context 'error moving group' do
      before do
        allow(internal_group).to receive(:move_dir).and_raise(Gitlab::UpdatePathError)
      end

      it 'does not raise an error' do
        expect { service.execute }.not_to raise_error
      end

      it 'returns false' do
        expect(service.execute).to eq(false)
      end

      it 'has the right error' do
        service.execute

        expect(internal_group.errors.full_messages.first).to eq('Gitlab::UpdatePathError')
      end

      it "hasn't changed the path" do
        expect { service.execute}.not_to change { internal_group.reload.path}
      end
    end
  end

  context 'for a subgroup', :nested_groups do
    let(:subgroup) { create(:group, :private, parent: private_group) }

    context 'when the parent group share_with_group_lock is enabled' do
      before do
        private_group.update_column(:share_with_group_lock, true)
      end

      context 'for the parent group owner' do
        it 'allows disabling share_with_group_lock' do
          private_group.add_owner(user)

          result = described_class.new(subgroup, user, share_with_group_lock: false).execute

          expect(result).to be_truthy
          expect(subgroup.reload.share_with_group_lock).to be_falsey
        end
      end

      context 'for a subgroup owner (who does not own the parent)' do
        it 'does not allow disabling share_with_group_lock' do
          subgroup_owner = create(:user)
          subgroup.add_owner(subgroup_owner)

          result = described_class.new(subgroup, subgroup_owner, share_with_group_lock: false).execute

          expect(result).to be_falsey
          expect(subgroup.errors.full_messages.first).to match(/cannot be disabled when the parent group "Share with group lock" is enabled, except by the owner of the parent group/)
          expect(subgroup.reload.share_with_group_lock).to be_truthy
        end
      end
    end
  end
end
