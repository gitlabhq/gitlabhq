# frozen_string_literal: true

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
          public_group.add_user(user, Gitlab::Access::OWNER)
          create(:project, :public, group: public_group)

          expect(TodosDestroyer::GroupPrivateWorker).not_to receive(:perform_in)
        end

        it "does not change permission level" do
          service.execute
          expect(public_group.errors.count).to eq(1)

          expect(TodosDestroyer::GroupPrivateWorker).not_to receive(:perform_in)
        end

        it "returns false if save failed" do
          allow(public_group).to receive(:save).and_return(false)

          expect(service.execute).to be_falsey
        end

        context 'when a project has container images' do
          let(:params) { { path: SecureRandom.hex } }
          let!(:container_repository) { create(:container_repository, project: project) }

          subject { described_class.new(public_group, user, params).execute }

          context 'within group' do
            let(:project) { create(:project, group: public_group) }

            context 'with path updates' do
              it 'does not allow the update' do
                expect(subject).to be false
                expect(public_group.errors[:base].first).to match(/Docker images in their Container Registry/)
              end
            end

            context 'with name updates' do
              let(:params) { { name: 'new-name' } }

              it 'allows the update' do
                expect(subject).to be true
                expect(public_group.reload.name).to eq('new-name')
              end
            end
          end

          context 'within subgroup' do
            let(:subgroup) { create(:group, parent: public_group) }
            let(:project) { create(:project, group: subgroup) }

            it 'does not allow path updates' do
              expect(subject).to be false
              expect(public_group.errors[:base].first).to match(/Docker images in their Container Registry/)
            end
          end
        end
      end

      context "internal group with internal project" do
        let!(:service) { described_class.new(internal_group, user, visibility_level: Gitlab::VisibilityLevel::PRIVATE) }

        before do
          internal_group.add_user(user, Gitlab::Access::OWNER)
          create(:project, :internal, group: internal_group)

          expect(TodosDestroyer::GroupPrivateWorker).not_to receive(:perform_in)
        end

        it "does not change permission level" do
          service.execute
          expect(internal_group.errors.count).to eq(1)
        end
      end

      context "internal group with private project" do
        let!(:service) { described_class.new(internal_group, user, visibility_level: Gitlab::VisibilityLevel::PRIVATE) }

        before do
          internal_group.add_user(user, Gitlab::Access::OWNER)
          create(:project, :private, group: internal_group)

          expect(TodosDestroyer::GroupPrivateWorker).to receive(:perform_in)
            .with(Todo::WAIT_FOR_DELETE, internal_group.id)
        end

        it "changes permission level to private" do
          service.execute
          expect(internal_group.visibility_level)
            .to eq(Gitlab::VisibilityLevel::PRIVATE)
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
      internal_group.add_user(user, Gitlab::Access::MAINTAINER)
    end

    it "does not change permission level" do
      service.execute
      expect(internal_group.errors.count).to eq(1)
    end
  end

  context 'when updating #emails_disabled' do
    let(:service) { described_class.new(internal_group, user, emails_disabled: true) }

    it 'updates the attribute' do
      internal_group.add_user(user, Gitlab::Access::OWNER)

      expect { service.execute }.to change { internal_group.emails_disabled }.to(true)
    end

    it 'does not update when not group owner' do
      expect { service.execute }.not_to change { internal_group.emails_disabled }
    end
  end

  context 'rename group' do
    let!(:service) { described_class.new(internal_group, user, path: SecureRandom.hex) }

    before do
      internal_group.add_user(user, Gitlab::Access::MAINTAINER)
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

  context 'for a subgroup' do
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
