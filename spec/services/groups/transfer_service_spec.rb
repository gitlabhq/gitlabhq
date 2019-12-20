# frozen_string_literal: true

require 'spec_helper'

describe Groups::TransferService do
  let(:user) { create(:user) }
  let(:new_parent_group) { create(:group, :public) }
  let!(:group_member) { create(:group_member, :owner, group: group, user: user) }
  let(:transfer_service) { described_class.new(group, user) }

  shared_examples 'ensuring allowed transfer for a group' do
    context "when there's an exception on GitLab shell directories" do
      let(:new_parent_group) { create(:group, :public) }

      before do
        allow_next_instance_of(described_class) do |instance|
          allow(instance).to receive(:update_group_attributes).and_raise(Gitlab::UpdatePathError, 'namespace directory cannot be moved')
        end
        create(:group_member, :owner, group: new_parent_group, user: user)
      end

      it 'returns false' do
        expect(transfer_service.execute(new_parent_group)).to be_falsy
      end

      it 'adds an error on group' do
        transfer_service.execute(new_parent_group)
        expect(transfer_service.error).to eq('Transfer failed: namespace directory cannot be moved')
      end
    end
  end

  describe '#execute' do
    context 'when transforming a group into a root group' do
      let!(:group) { create(:group, :public, :nested) }

      it_behaves_like 'ensuring allowed transfer for a group'

      context 'when the group is already a root group' do
        let(:group) { create(:group, :public) }

        it 'adds an error on group' do
          transfer_service.execute(nil)
          expect(transfer_service.error).to eq('Transfer failed: Group is already a root group.')
        end
      end

      context 'when the user does not have the right policies' do
        let!(:group_member) { create(:group_member, :guest, group: group, user: user) }

        it "returns false" do
          expect(transfer_service.execute(nil)).to be_falsy
        end

        it "adds an error on group" do
          transfer_service.execute(new_parent_group)
          expect(transfer_service.error).to eq("Transfer failed: You don't have enough permissions.")
        end
      end

      context 'when there is a group with the same path' do
        let!(:group) { create(:group, :public, :nested, path: 'not-unique') }

        before do
          create(:group, path: 'not-unique')
        end

        it 'returns false' do
          expect(transfer_service.execute(nil)).to be_falsy
        end

        it 'adds an error on group' do
          transfer_service.execute(nil)
          expect(transfer_service.error).to eq('Transfer failed: The parent group already has a subgroup with the same path.')
        end
      end

      context 'when the group is a subgroup and the transfer is valid' do
        let!(:subgroup1) { create(:group, :private, parent: group) }
        let!(:subgroup2) { create(:group, :internal, parent: group) }
        let!(:project1) { create(:project, :repository, :private, namespace: group) }

        before do
          transfer_service.execute(nil)
          group.reload
        end

        it 'updates group attributes' do
          expect(group.parent).to be_nil
        end

        it 'updates group children path' do
          group.children.each do |subgroup|
            expect(subgroup.full_path).to eq("#{group.path}/#{subgroup.path}")
          end
        end

        it 'updates group projects path' do
          group.projects.each do |project|
            expect(project.full_path).to eq("#{group.path}/#{project.path}")
          end
        end
      end
    end

    context 'when transferring a subgroup into another group' do
      let(:group) { create(:group, :public, :nested) }

      it_behaves_like 'ensuring allowed transfer for a group'

      context 'when the new parent group is the same as the previous parent group' do
        let(:group) { create(:group, :public, :nested, parent: new_parent_group) }

        it 'returns false' do
          expect(transfer_service.execute(new_parent_group)).to be_falsy
        end

        it 'adds an error on group' do
          transfer_service.execute(new_parent_group)
          expect(transfer_service.error).to eq('Transfer failed: Group is already associated to the parent group.')
        end
      end

      context 'when the user does not have the right policies' do
        let!(:group_member) { create(:group_member, :guest, group: group, user: user) }

        it "returns false" do
          expect(transfer_service.execute(new_parent_group)).to be_falsy
        end

        it "adds an error on group" do
          transfer_service.execute(new_parent_group)
          expect(transfer_service.error).to eq("Transfer failed: You don't have enough permissions.")
        end
      end

      context 'when the parent has a group with the same path' do
        before do
          create(:group_member, :owner, group: new_parent_group, user: user)
          group.update_attribute(:path, "not-unique")
          create(:group, path: "not-unique", parent: new_parent_group)
        end

        it 'returns false' do
          expect(transfer_service.execute(new_parent_group)).to be_falsy
        end

        it 'adds an error on group' do
          transfer_service.execute(new_parent_group)
          expect(transfer_service.error).to eq('Transfer failed: The parent group already has a subgroup with the same path.')
        end
      end

      context 'when the parent group has a project with the same path' do
        let!(:group) { create(:group, :public, :nested, path: 'foo') }

        before do
          create(:group_member, :owner, group: new_parent_group, user: user)
          create(:project, path: 'foo', namespace: new_parent_group)
          group.update_attribute(:path, 'foo')
        end

        it 'returns false' do
          expect(transfer_service.execute(new_parent_group)).to be_falsy
        end

        it 'adds an error on group' do
          transfer_service.execute(new_parent_group)
          expect(transfer_service.error).to eq('Transfer failed: Validation failed: Group URL has already been taken')
        end
      end

      context 'when the group is allowed to be transferred' do
        before do
          create(:group_member, :owner, group: new_parent_group, user: user)
          transfer_service.execute(new_parent_group)
        end

        context 'when the group has a lower visibility than the parent group' do
          let(:new_parent_group) { create(:group, :public) }
          let(:group) { create(:group, :private, :nested) }

          it 'does not update the visibility for the group' do
            group.reload
            expect(group.private?).to be_truthy
            expect(group.visibility_level).not_to eq(new_parent_group.visibility_level)
          end
        end

        context 'when the group has a higher visibility than the parent group' do
          let(:new_parent_group) { create(:group, :private) }
          let(:group) { create(:group, :public, :nested) }

          it 'updates visibility level based on the parent group' do
            group.reload
            expect(group.private?).to be_truthy
            expect(group.visibility_level).to eq(new_parent_group.visibility_level)
          end
        end

        it 'updates visibility for the group based on the parent group' do
          expect(group.visibility_level).to eq(new_parent_group.visibility_level)
        end

        it 'updates parent group to the new parent' do
          expect(group.parent).to eq(new_parent_group)
        end

        it 'returns the group as children of the new parent' do
          expect(new_parent_group.children.count).to eq(1)
          expect(new_parent_group.children.first).to eq(group)
        end

        it 'creates a redirect for the group' do
          expect(group.redirect_routes.count).to eq(1)
        end
      end

      context 'when transferring a group with group descendants' do
        let!(:subgroup1) { create(:group, :private, parent: group) }
        let!(:subgroup2) { create(:group, :internal, parent: group) }

        before do
          create(:group_member, :owner, group: new_parent_group, user: user)
          transfer_service.execute(new_parent_group)
        end

        it 'updates subgroups path' do
          new_parent_path = new_parent_group.path
          group.children.each do |subgroup|
            expect(subgroup.full_path).to eq("#{new_parent_path}/#{group.path}/#{subgroup.path}")
          end
        end

        it 'creates redirects for the subgroups' do
          expect(group.redirect_routes.count).to eq(1)
          expect(subgroup1.redirect_routes.count).to eq(1)
          expect(subgroup2.redirect_routes.count).to eq(1)
        end

        context 'when the new parent has a higher visibility than the children' do
          it 'does not update the children visibility' do
            expect(subgroup1.private?).to be_truthy
            expect(subgroup2.internal?).to be_truthy
          end
        end

        context 'when the new parent has a lower visibility than the children' do
          let!(:subgroup1) { create(:group, :public, parent: group) }
          let!(:subgroup2) { create(:group, :public, parent: group) }
          let(:new_parent_group) { create(:group, :private) }

          it 'updates children visibility to match the new parent' do
            group.children.each do |subgroup|
              expect(subgroup.private?).to be_truthy
            end
          end
        end
      end

      context 'when transferring a group with project descendants' do
        let!(:project1) { create(:project, :repository, :private, namespace: group) }
        let!(:project2) { create(:project, :repository, :internal, namespace: group) }

        before do
          TestEnv.clean_test_path
          create(:group_member, :owner, group: new_parent_group, user: user)
          transfer_service.execute(new_parent_group)
        end

        it 'updates projects path' do
          new_parent_path = new_parent_group.path
          group.projects.each do |project|
            expect(project.full_path).to eq("#{new_parent_path}/#{group.path}/#{project.name}")
          end
        end

        it 'creates permanent redirects for the projects' do
          expect(group.redirect_routes.count).to eq(1)
          expect(project1.redirect_routes.count).to eq(1)
          expect(project2.redirect_routes.count).to eq(1)
        end

        context 'when the new parent has a higher visibility than the projects' do
          it 'does not update projects visibility' do
            expect(project1.private?).to be_truthy
            expect(project2.internal?).to be_truthy
          end
        end

        context 'when the new parent has a lower visibility than the projects' do
          let!(:project1) { create(:project, :repository, :public, namespace: group) }
          let!(:project2) { create(:project, :repository, :public, namespace: group) }
          let(:new_parent_group) { create(:group, :private) }

          it 'updates projects visibility to match the new parent' do
            group.projects.each do |project|
              expect(project.private?).to be_truthy
            end
          end
        end
      end

      context 'when transferring a group with subgroups & projects descendants' do
        let!(:project1) { create(:project, :repository, :private, namespace: group) }
        let!(:project2) { create(:project, :repository, :internal, namespace: group) }
        let!(:subgroup1) { create(:group, :private, parent: group) }
        let!(:subgroup2) { create(:group, :internal, parent: group) }

        before do
          TestEnv.clean_test_path
          create(:group_member, :owner, group: new_parent_group, user: user)
          transfer_service.execute(new_parent_group)
        end

        it 'updates subgroups path' do
          new_parent_path = new_parent_group.path
          group.children.each do |subgroup|
            expect(subgroup.full_path).to eq("#{new_parent_path}/#{group.path}/#{subgroup.path}")
          end
        end

        it 'updates projects path' do
          new_parent_path = new_parent_group.path
          group.projects.each do |project|
            expect(project.full_path).to eq("#{new_parent_path}/#{group.path}/#{project.name}")
          end
        end

        it 'creates redirect for the subgroups and projects' do
          expect(group.redirect_routes.count).to eq(1)
          expect(subgroup1.redirect_routes.count).to eq(1)
          expect(subgroup2.redirect_routes.count).to eq(1)
          expect(project1.redirect_routes.count).to eq(1)
          expect(project2.redirect_routes.count).to eq(1)
        end
      end

      context 'when transferring a group with nested groups and projects' do
        let!(:group) { create(:group, :public) }
        let!(:project1) { create(:project, :repository, :private, namespace: group) }
        let!(:subgroup1) { create(:group, :private, parent: group) }
        let!(:nested_subgroup) { create(:group, :private, parent: subgroup1) }
        let!(:nested_project) { create(:project, :repository, :private, namespace: subgroup1) }

        before do
          TestEnv.clean_test_path
          create(:group_member, :owner, group: new_parent_group, user: user)
          transfer_service.execute(new_parent_group)
        end

        it 'updates subgroups path' do
          new_base_path = "#{new_parent_group.path}/#{group.path}"
          group.children.each do |children|
            expect(children.full_path).to eq("#{new_base_path}/#{children.path}")
          end

          new_base_path = "#{new_parent_group.path}/#{group.path}/#{subgroup1.path}"
          subgroup1.children.each do |children|
            expect(children.full_path).to eq("#{new_base_path}/#{children.path}")
          end
        end

        it 'updates projects path' do
          new_parent_path = "#{new_parent_group.path}/#{group.path}"
          subgroup1.projects.each do |project|
            project_full_path = "#{new_parent_path}/#{project.namespace.path}/#{project.name}"
            expect(project.full_path).to eq(project_full_path)
          end
        end

        it 'creates redirect for the subgroups and projects' do
          expect(group.redirect_routes.count).to eq(1)
          expect(project1.redirect_routes.count).to eq(1)
          expect(subgroup1.redirect_routes.count).to eq(1)
          expect(nested_subgroup.redirect_routes.count).to eq(1)
          expect(nested_project.redirect_routes.count).to eq(1)
        end
      end

      context 'when updating the group goes wrong' do
        let!(:subgroup1) { create(:group, :public, parent: group) }
        let!(:subgroup2) { create(:group, :public, parent: group) }
        let(:new_parent_group) { create(:group, :private) }
        let!(:project1) { create(:project, :repository, :public, namespace: group) }

        before do
          allow(group).to receive(:save!).and_raise(ActiveRecord::RecordInvalid.new(group))
          TestEnv.clean_test_path
          create(:group_member, :owner, group: new_parent_group, user: user)
          transfer_service.execute(new_parent_group)
        end

        it 'restores group and projects visibility' do
          subgroup1.reload
          project1.reload
          expect(subgroup1.public?).to be_truthy
          expect(project1.public?).to be_truthy
        end
      end
    end

    context 'when transferring a subgroup into root group' do
      let(:group) { create(:group, :public, :nested) }
      let(:subgroup) { create(:group, :public, parent: group) }
      let(:transfer_service) { described_class.new(subgroup, user) }

      it 'ensures there is still an owner for the transferred group' do
        expect(subgroup.owners).to be_empty

        transfer_service.execute(nil)
        subgroup.reload

        expect(subgroup.owners).to match_array(user)
      end

      context 'when group has explicit owner' do
        let(:another_owner) { create(:user) }
        let!(:another_member) { create(:group_member, :owner, group: subgroup, user: another_owner) }

        it 'does not add additional owner' do
          expect(subgroup.owners).to match_array(another_owner)

          transfer_service.execute(nil)
          subgroup.reload

          expect(subgroup.owners).to match_array(another_owner)
        end
      end
    end

    context 'when a project has container images' do
      let(:group) { create(:group, :public, :nested) }
      let!(:container_repository) { create(:container_repository, project: project) }

      subject { transfer_service.execute(new_parent_group) }

      before do
        group.add_owner(user)
        new_parent_group.add_owner(user)
      end

      context 'within group' do
        let(:project) { create(:project, :repository, :public, namespace: group) }

        it 'does not transfer' do
          expect(subject).to be false
          expect(transfer_service.error).to match(/Docker images in their Container Registry/)
        end
      end

      context 'within subgroup' do
        let(:subgroup) { create(:group, parent: group) }
        let(:project) { create(:project, :repository, :public, namespace: subgroup) }

        it 'does not transfer' do
          expect(subject).to be false
          expect(transfer_service.error).to match(/Docker images in their Container Registry/)
        end
      end
    end
  end
end
