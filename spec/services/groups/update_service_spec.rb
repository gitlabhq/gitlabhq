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
          create(:empty_project, :public, group: public_group)
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
          create(:empty_project, :internal, group: internal_group)
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

  context 'repository_size_limit assignment as Bytes' do
    let(:group) { create(:group, :public, repository_size_limit: 0) }
    let(:service) { described_class.new(group, user, opts) }

    context 'when param present' do
      let(:opts) { { repository_size_limit: '100' } }

      it 'converts from MB to Bytes' do
        service.execute

        expect(group.reload.repository_size_limit).to eql(100 * 1024 * 1024)
      end
    end

    context 'when param not present' do
      let(:opts) { { repository_size_limit: '' } }

      it 'assign nil value' do
        service.execute

        expect(group.reload.repository_size_limit).to be_nil
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
      create(:empty_project, :internal, group: internal_group)
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
end
